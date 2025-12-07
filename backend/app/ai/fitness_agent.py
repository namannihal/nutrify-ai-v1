"""
Fitness Agent - Generates personalized workout plans
Implements context-aware AI workout planning with hierarchical memory
"""

from typing import Dict, List, Optional
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

from app.models.user import User
from app.models.fitness import FitnessPlan, Workout, Exercise
from app.memory.hierarchical_memory import HierarchicalMemory
from app.tools.fitness_tools import ExerciseDatabase
from app.core.config import settings


class FitnessAgent:
    """
    AI Agent for generating personalized fitness plans
    Uses hierarchical memory for context management
    """
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.llm = ChatOpenAI(
            model=settings.AI_MODEL,
            temperature=settings.AI_TEMPERATURE,
            api_key=settings.OPENAI_API_KEY
        )
        self.memory = HierarchicalMemory(db)
        self.exercise_db = ExerciseDatabase()
        
    async def generate_weekly_plan(
        self,
        user: User,
        start_date: Optional[datetime] = None
    ) -> FitnessPlan:
        """
        Generate a personalized weekly workout plan
        
        Args:
            user: User object with profile data
            start_date: Week start date (defaults to next Monday)
            
        Returns:
            FitnessPlan with 7 days of workouts
        """
        if start_date is None:
            start_date = self._get_next_monday()
            
        # Retrieve user context
        context = await self.memory.get_user_context(
            user_id=user.id,
            context_type="fitness_planning"
        )
        
        # Generate workouts using AI
        weekly_workouts = await self._generate_weekly_workouts(user, context)
        
        # Calculate end date
        end_date = start_date + timedelta(days=6)
        
        # Create FitnessPlan in database (without workouts first)
        workout_plan = FitnessPlan(
            user_id=user.id,
            week_start=start_date,
            week_end=end_date,
            created_by_ai=True,
            ai_model_version=settings.AI_MODEL
        )
        
        self.db.add(workout_plan)
        await self.db.flush()  # Get plan_id before adding workouts
        
        # Add workouts with plan_id
        for workout in weekly_workouts:
            workout.plan_id = workout_plan.id
            self.db.add(workout)
        
        await self.db.commit()
        await self.db.refresh(workout_plan)
        
        # Update episodic memory
        await self.memory.store_episode(
            user_id=user.id,
            episode_type="workout_plan_generated",
            content={
                "plan_id": str(workout_plan.id),
                "workout_count": len(weekly_workouts),
                "generated_at": datetime.utcnow().isoformat()
            }
        )
        
        return workout_plan
        
    async def _generate_weekly_workouts(
        self,
        user: User,
        context: Dict
    ) -> List[Workout]:
        """
        Generate 7 days of workout plans using AI
        """
        system_prompt = self._build_fitness_system_prompt()
        user_prompt = self._build_fitness_user_prompt(user, context)
        
        response = await self.llm.ainvoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ])
        
        workouts = await self._parse_workout_response(response.content)
        return workouts
        
    def _build_fitness_system_prompt(self) -> str:
        """System prompt for fitness agent"""
        return """You are an expert personal trainer and fitness coach AI.
Your role is to create personalized, safe, and effective weekly workout plans.

Key principles:
- Consider user's fitness level, goals, and available equipment
- Ensure progressive overload and proper recovery
- Include warm-up and cool-down exercises
- Vary workout types (strength, cardio, flexibility, rest)
- Provide clear exercise instructions with sets, reps, and rest periods
- Account for injuries or physical limitations

Response format: Return a JSON array with 7 workouts (one per day). Each workout must include:
- day_of_week: integer 0-6 (0=Monday, 1=Tuesday, 2=Wednesday, 3=Thursday, 4=Friday, 5=Saturday, 6=Sunday)
- name: string (e.g., "Upper Body Strength")
- workout_type: string (e.g., "strength", "cardio", "flexibility", "rest", "mixed")
- duration_minutes: integer
- description: string (brief overview)
- estimated_calories: integer (optional)
- intensity_level: integer 1-5 (optional)
- exercises: array of exercise objects

Each exercise object must include:
- name: string
- description: string
- sets: integer
- reps: string (e.g., "8-10" or "to failure")
- rest_seconds: integer
- muscle_groups: array of strings
- equipment_needed: string or null
- video_url: string (optional)

Example:
[
  {
    "day_of_week": 0,
    "name": "Upper Body Strength",
    "workout_type": "strength",
    "duration_minutes": 45,
    "description": "Focus on chest, back, and arms",
    "estimated_calories": 300,
    "intensity_level": 4,
    "exercises": [
      {
        "name": "Bench Press",
        "description": "Lie on bench, lower barbell to chest, press up",
        "sets": 3,
        "reps": "8-10",
        "rest_seconds": 90,
        "muscle_groups": ["chest", "triceps"],
        "equipment_needed": "barbell, bench"
      }
    ]
  }
]

Include rest days as needed based on intensity and user recovery ability."""
        
    def _build_fitness_user_prompt(
        self,
        user: User,
        context: Dict
    ) -> str:
        """Build user-specific fitness prompt"""
        profile = user.profile
        
        prompt = f"""Generate a 7-day workout plan for this user:

USER PROFILE:
- Age: {profile.age if profile else 'N/A'}
- Fitness Level: {profile.fitness_level if profile else 'beginner'}
- Primary Goal: {profile.primary_goal if profile else 'general fitness'}
- Activity Level: {profile.activity_level if profile else 'moderate'}

"""
        
        if profile and profile.fitness_preferences:
            prompt += f"FITNESS PREFERENCES: {', '.join(profile.fitness_preferences)}\n"
        if profile and profile.available_equipment:
            prompt += f"AVAILABLE EQUIPMENT: {', '.join(profile.available_equipment)}\n"
        if profile and profile.injuries_limitations:
            prompt += f"INJURIES/LIMITATIONS: {', '.join(profile.injuries_limitations)}\n"
            
        if context.get("past_workouts"):
            prompt += f"\nPAST WORKOUT PATTERNS: {context['past_workouts']}\n"
            
        prompt += "\nGenerate the 7-day workout plan as JSON:"
        return prompt
        
    async def _parse_workout_response(self, response: str) -> List[Workout]:
        """Parse AI response into Workout objects with nested Exercise objects"""
        import json
        
        # Extract JSON
        if "```json" in response:
            response = response.split("```json")[1].split("```")[0]
        elif "```" in response:
            response = response.split("```")[1].split("```")[0]
            
        try:
            workouts_data = json.loads(response.strip())
        except json.JSONDecodeError:
            return self._generate_fallback_workouts()
            
        workouts = []
        for workout_data in workouts_data:
            # Create workout without exercises first
            workout = Workout(
                day_of_week=workout_data.get("day_of_week", 0),
                name=workout_data.get("name", "Workout"),
                workout_type=workout_data.get("workout_type", "mixed"),
                duration_minutes=workout_data.get("duration_minutes", 30),
                description=workout_data.get("description"),
                estimated_calories=workout_data.get("estimated_calories"),
                intensity_level=workout_data.get("intensity_level")
            )
            
            # Create exercises (will be added to workout via relationship)
            for ex_data in workout_data.get("exercises", []):
                exercise = Exercise(
                    name=ex_data.get("name", "Exercise"),
                    description=ex_data.get("description"),
                    sets=ex_data.get("sets", 3),
                    reps=ex_data.get("reps", "10"),
                    rest_seconds=ex_data.get("rest_seconds", 60),
                    muscle_groups=ex_data.get("muscle_groups", []),
                    equipment_needed=ex_data.get("equipment_needed"),
                    video_url=ex_data.get("video_url")
                )
                workout.exercises.append(exercise)
            
            workouts.append(workout)
            
        return workouts
        
    def _generate_fallback_workouts(self) -> List[Workout]:
        """Generate simple fallback workout plan"""
        workout_templates = [
            {"day": 0, "name": "Upper Body Strength", "type": "strength"},
            {"day": 1, "name": "Cardio & Core", "type": "cardio"},
            {"day": 2, "name": "Lower Body Strength", "type": "strength"},
            {"day": 3, "name": "Active Recovery", "type": "flexibility"},
            {"day": 4, "name": "Full Body Workout", "type": "mixed"},
            {"day": 5, "name": "Cardio Intervals", "type": "cardio"},
            {"day": 6, "name": "Rest Day", "type": "rest"}
        ]
        
        workouts = []
        for template in workout_templates:
            workout = Workout(
                day_of_week=template["day"],
                name=template["name"],
                workout_type=template["type"],
                duration_minutes=30 if template["type"] != "rest" else 0,
                description=f"{template['name']} workout"
            )
            
            # Add basic exercise for non-rest days
            if template["type"] != "rest":
                exercise = Exercise(
                    name="Basic Exercise",
                    description="Perform as directed",
                    sets=3,
                    reps="10-12",
                    rest_seconds=60,
                    muscle_groups=["full_body"]
                )
                workout.exercises.append(exercise)
            
            workouts.append(workout)
            
        return workouts
        
    def _get_next_monday(self) -> datetime:
        """Get the next Monday's date"""
        today = datetime.now().date()
        days_ahead = 0 - today.weekday()
        if days_ahead <= 0:
            days_ahead += 7
        return datetime.combine(today + timedelta(days=days_ahead), datetime.min.time())
