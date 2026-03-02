import google.generativeai as genai
import json
import os
import uuid
from datetime import datetime
from typing import List, Dict, Any
from schemas import UserProfile, NutritionPlan, WorkoutPlan
from dotenv import load_dotenv

load_dotenv()

# Configure Gemini
api_key = os.getenv("GOOGLE_API_KEY")
if api_key:
    genai.configure(api_key=api_key)

EXERCISES_DB = []

def load_exercises():
    global EXERCISES_DB
    try:
        with open("data/exercises.json", "r") as f:
            EXERCISES_DB = json.load(f)
        print(f"Loaded {len(EXERCISES_DB)} exercises")
    except Exception as e:
        print(f"Error loading exercises: {e}")

# Load on import
load_exercises()

def get_valid_exercise_ids() -> List[str]:
    return [ex["id"] for ex in EXERCISES_DB]

def get_exercises_summary() -> str:
    """Returns a compact summary of available exercises for the prompt."""
    # To save tokens, we might just list IDs or (ID, name, equipment)
    # For 1000 exercises, we need to be careful. 
    # Gemini 2.0 Flash has 1M context, so passing the full JSON is actually fine!
    return json.dumps(EXERCISES_DB[:], indent=None) # Passing full DB is best for accuracy

class AIService:
    def __init__(self):
        self.model = genai.GenerativeModel('gemini-2.0-flash-exp') # Or gemini-1.5-flash

    async def generate_nutrition_plan(self, profile: UserProfile) -> Dict[str, Any]:
        prompt = f"""
        You are an expert nutritionist AI. Generate a 7-day meal plan for this user:
        
        Profile:
        - Age: {profile.age}, Gender: {profile.gender}, Weight: {profile.weight}kg, Height: {profile.height}cm
        - Goal: {profile.primary_goal}
        - Activity Level: {profile.activity_level}
        - Dietary Restrictions: {', '.join(profile.dietary_restrictions)}
        
        Requirements:
        1. Calculate appropriate daily calories and macros (Protein/Carbs/Fat) for their goal.
        2. Create a weekly plan (Monday-Sunday).
        3. Provide breakfast, lunch, dinner, and snacks for each day.
        4. Meals should be varied and nutritious.
        5. Return valid JSON matching the schema below.
        
        Output JSON Schema:
        {{
            "week_start": "YYYY-MM-DD",
            "daily_calories": 2000,
            "macros": {{"protein": 150, "carbs": 200, "fat": 60}},
            "meals": [
                {{
                    "day": "Monday",
                    "breakfast": [ {{ "id": "uuid", "name": "Oatmeal", "calories": 400, "protein_grams": 15, "carbs_grams": 60, "fat_grams": 10, "ingredients": {{"oats": "50g"}}, "instructions": "Boil water..." }} ],
                    "lunch": [...],
                    "dinner": [...],
                    "snacks": [...]
                }}
            ],
            "adaptation_reason": "Balanced for weight maintenance"
        }}
        """
        
        try:
            response = self.model.generate_content(
                prompt,
                generation_config={"response_mime_type": "application/json"}
            )
            data = json.loads(response.text)
            
            # Enrich with missing fields if needed (ids, etc)
            data["id"] = f"plan_{uuid.uuid4().hex[:8]}"
            data["user_id"] = "user_123" # In real app, get from request
            return data
        except Exception as e:
            print(f"Error generating nutrition plan: {e}")
            raise

    async def generate_workout_plan(self, profile: UserProfile) -> Dict[str, Any]:
        # Filter exercises based on equipment if needed, or pass full DB and let AI filter
        # Better to filter in code if possible, but letting AI do it with full context is powerful
        
        prompt = f"""
        You are an elite fitness coach. Create a weekly workout plan for this user:
        
        Profile:
        - Goal: {profile.primary_goal}
        - Experience: {profile.fitness_experience}
        - Equipment Available: {', '.join(profile.equipment)}
        - Days Per Week: {profile.days_per_week}
        - Time Per Workout: {profile.time_per_workout} mins
        
        CRITICAL: Use ONLY exercises from the provided Exercise Library. 
        Use the exact "id" from the library for "exercise_id".
        
        Requirements:
        1. Structure the plan for Monday-Sunday.
        2. Mark rest days appropriately based on their days_per_week preference.
        3. Ensure progressive overload principles.
        4. Return valid JSON matching the schema.
        
        Exercise Library (JSON):
        {get_exercises_summary()}
        
        Output JSON Schema:
        {{
            "week_start": "YYYY-MM-DD",
            "goal": "{profile.primary_goal}",
            "workouts": [
                {{
                    "day": "Monday",
                    "is_rest_day": false,
                    "workouts": [
                        {{
                            "id": "w_1",
                            "name": "Full Body A",
                            "exercises": [
                                {{
                                    "exercise_id": "3_4_Sit-Up", 
                                    "name": "3/4 Sit-Up",
                                    "sets": 3,
                                    "reps": "12-15",
                                    "rest_seconds": 60
                                }}
                            ],
                            "estimated_duration_minutes": 45,
                            "difficulty": "intermediate",
                            "target_muscle_groups": ["full body"]
                        }}
                    ]
                }}
            ]
        }}
        """
        
        try:
            response = self.model.generate_content(
                prompt,
                generation_config={"response_mime_type": "application/json"}
            )
            data = json.loads(response.text)
            
            # Validate exercise IDs exist in our DB
            valid_ids = set(get_valid_exercise_ids())
            for day in data.get("workouts", []):
                 for workout in day.get("workouts", []):
                     for exercise in workout.get("exercises", []):
                         eid = exercise.get("exercise_id")
                         if eid not in valid_ids:
                             print(f"Warning: AI generated invalid exercise ID: {eid}")
                             # Could implement fallback logic here
            
            data["id"] = f"wplan_{uuid.uuid4().hex[:8]}"
            data["user_id"] = "user_123"
            return data
        except Exception as e:
            print(f"Error generating workout plan: {e}")
            raise
