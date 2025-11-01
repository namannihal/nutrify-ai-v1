from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List
from datetime import datetime, timedelta

from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.fitness import FitnessPlan, Workout, Exercise
from app.schemas.fitness import (
    WorkoutPlanResponse,
    WorkoutLogCreate,
)

router = APIRouter()


@router.get("/current-plan", response_model=WorkoutPlanResponse)
async def get_current_workout_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user's current workout plan"""
    # Get most recent plan
    result = await db.execute(
        select(FitnessPlan)
        .where(FitnessPlan.user_id == current_user.id)
        .order_by(desc(FitnessPlan.week_start))
        .limit(1)
    )
    plan = result.scalar_one_or_none()
    
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No workout plan found. Please generate one first."
        )
    
    # Get workouts for this plan
    workouts_result = await db.execute(
        select(Workout).where(Workout.fitness_plan_id == plan.id)
    )
    workouts = workouts_result.scalars().all()
    
    # Get exercises for these workouts
    workout_data = []
    for workout in workouts:
        exercises_result = await db.execute(
            select(Exercise).where(Exercise.workout_id == workout.id)
        )
        exercises = exercises_result.scalars().all()
        
        workout_data.append({
            "day": workout.day_of_week.lower(),
            "type": workout.workout_type,
            "duration": workout.duration_minutes,
            "exercises": [_exercise_to_dict(e) for e in exercises],
        })
    
    return {
        "id": str(plan.id),
        "user_id": str(plan.user_id),
        "week_start": plan.week_start.isoformat(),
        "workouts": workout_data,
        "difficulty_level": plan.difficulty_level,
        "created_by_ai": plan.created_by_ai,
        "adaptation_reason": plan.adaptation_reason,
    }


@router.post("/generate", response_model=WorkoutPlanResponse)
async def generate_workout_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate a new AI-powered workout plan"""
    # TODO: Integrate with LangChain agent for AI generation
    
    # Calculate week start (current Monday)
    today = datetime.now().date()
    week_start = today - timedelta(days=today.weekday())
    
    # Create fitness plan
    plan = FitnessPlan(
        user_id=current_user.id,
        week_start=week_start,
        week_end=week_start + timedelta(days=6),
        difficulty_level=7,
        created_by_ai=True,
        adaptation_reason="Initial plan based on your fitness level and goals"
    )
    
    db.add(plan)
    await db.commit()
    await db.refresh(plan)
    
    # Create sample workouts
    workouts = _create_sample_workouts(plan.id)
    for workout in workouts:
        db.add(workout)
    
    await db.commit()
    
    # Create exercises for workouts
    for workout in workouts:
        await db.refresh(workout)
        exercises = _create_sample_exercises(workout.id, workout.workout_type)
        for exercise in exercises:
            db.add(exercise)
    
    await db.commit()
    
    # Fetch created workouts with exercises
    workouts_result = await db.execute(
        select(Workout).where(Workout.fitness_plan_id == plan.id)
    )
    created_workouts = workouts_result.scalars().all()
    
    workout_data = []
    for workout in created_workouts:
        exercises_result = await db.execute(
            select(Exercise).where(Exercise.workout_id == workout.id)
        )
        exercises = exercises_result.scalars().all()
        
        workout_data.append({
            "day": workout.day_of_week.lower(),
            "type": workout.workout_type,
            "duration": workout.duration_minutes,
            "exercises": [_exercise_to_dict(e) for e in exercises],
        })
    
    return {
        "id": str(plan.id),
        "user_id": str(plan.user_id),
        "week_start": plan.week_start_date.isoformat(),
        "workouts": workout_data,
        "difficulty_level": plan.difficulty_level,
        "created_by_ai": plan.created_by_ai,
        "adaptation_reason": plan.adaptation_reason,
    }


@router.post("/log-workout")
async def log_workout(
    workout_data: WorkoutLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Log a completed workout"""
    # TODO: Implement workout logging
    return {"message": "Workout logged successfully"}


def _exercise_to_dict(exercise: Exercise) -> dict:
    """Convert exercise model to dict"""
    return {
        "id": str(exercise.id),
        "name": exercise.name,
        "sets": exercise.sets,
        "reps": exercise.reps,
        "duration": exercise.duration_seconds,
        "rest_time": exercise.rest_seconds,
        "instructions": exercise.instructions,
        "muscle_groups": exercise.target_muscles or [],
        "equipment": exercise.equipment_needed or [],
    }


def _create_sample_workouts(plan_id) -> List[Workout]:
    """Create sample workouts"""
    return [
        Workout(
            fitness_plan_id=plan_id,
            day_of_week="Monday",
            workout_type="strength",
            duration_minutes=45,
        ),
        Workout(
            fitness_plan_id=plan_id,
            day_of_week="Tuesday",
            workout_type="cardio",
            duration_minutes=30,
        ),
        Workout(
            fitness_plan_id=plan_id,
            day_of_week="Wednesday",
            workout_type="strength",
            duration_minutes=45,
        ),
        Workout(
            fitness_plan_id=plan_id,
            day_of_week="Thursday",
            workout_type="rest",
            duration_minutes=0,
        ),
        Workout(
            fitness_plan_id=plan_id,
            day_of_week="Friday",
            workout_type="strength",
            duration_minutes=45,
        ),
        Workout(
            fitness_plan_id=plan_id,
            day_of_week="Saturday",
            workout_type="cardio",
            duration_minutes=30,
        ),
        Workout(
            fitness_plan_id=plan_id,
            day_of_week="Sunday",
            workout_type="rest",
            duration_minutes=0,
        ),
    ]


def _create_sample_exercises(workout_id, workout_type: str) -> List[Exercise]:
    """Create sample exercises based on workout type"""
    if workout_type == "strength":
        return [
            Exercise(
                workout_id=workout_id,
                name="Barbell Squats",
                sets=4,
                reps=8,
                rest_seconds=90,
                instructions="Keep core tight, descend until thighs parallel to floor",
                target_muscles=["Quadriceps", "Glutes", "Core"],
                equipment_needed=["Barbell", "Squat Rack"],
            ),
            Exercise(
                workout_id=workout_id,
                name="Bench Press",
                sets=4,
                reps=10,
                rest_seconds=90,
                instructions="Lower bar to chest, press up explosively",
                target_muscles=["Chest", "Shoulders", "Triceps"],
                equipment_needed=["Barbell", "Bench"],
            ),
            Exercise(
                workout_id=workout_id,
                name="Bent-Over Rows",
                sets=3,
                reps=12,
                rest_seconds=60,
                instructions="Hinge at hips, pull bar to lower chest",
                target_muscles=["Back", "Biceps", "Core"],
                equipment_needed=["Barbell"],
            ),
            Exercise(
                workout_id=workout_id,
                name="Overhead Press",
                sets=3,
                reps=10,
                rest_seconds=60,
                instructions="Press weight overhead, keep core engaged",
                target_muscles=["Shoulders", "Triceps", "Core"],
                equipment_needed=["Barbell"],
            ),
        ]
    elif workout_type == "cardio":
        return [
            Exercise(
                workout_id=workout_id,
                name="Running",
                duration_seconds=1200,
                instructions="Maintain steady pace, focus on breathing",
                target_muscles=["Legs", "Cardiovascular"],
                equipment_needed=["None"],
            ),
            Exercise(
                workout_id=workout_id,
                name="Jump Rope",
                sets=3,
                duration_seconds=180,
                rest_seconds=60,
                instructions="Keep elbows close to body, use wrists to rotate rope",
                target_muscles=["Legs", "Shoulders", "Cardiovascular"],
                equipment_needed=["Jump Rope"],
            ),
        ]
    else:
        return []
