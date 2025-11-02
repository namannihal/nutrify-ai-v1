from datetime import datetime, timedelta
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user
from app.core.database import get_db
from app.models.fitness import Exercise, FitnessPlan, Workout
from app.models.user import User
from app.schemas.fitness import WorkoutLogCreate, WorkoutPlanResponse

router = APIRouter()

DAY_NAMES = [
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday",
]


def _exercise_to_dict(exercise: Exercise) -> dict:
    return {
        "id": str(exercise.id),
        "name": exercise.name,
        "sets": exercise.sets,
        "reps": exercise.reps,
        "duration": exercise.duration_seconds,
        "rest_time": exercise.rest_time_seconds,
        "instructions": exercise.instructions,
        "muscle_groups": exercise.muscle_groups or [],
        "equipment": exercise.equipment_required or [],
    }

def _workout_to_dict(workout: Workout, exercises: List[Exercise]) -> dict:
    day_index = workout.day_of_week
    day_name = DAY_NAMES[day_index] if 0 <= day_index < len(DAY_NAMES) else str(day_index)
    return {
        "day": day_name,
        "type": workout.workout_type,
        "duration": workout.duration_minutes,
        "exercises": [_exercise_to_dict(ex) for ex in exercises],
    }


@router.get("/current-plan", response_model=WorkoutPlanResponse)
async def get_current_workout_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
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
            detail="No workout plan found. Please generate one first.",
        )

    workouts_result = await db.execute(
        select(Workout)
        .where(Workout.plan_id == plan.id)
        .order_by(Workout.day_of_week, Workout.created_at)
    )
    workouts = workouts_result.scalars().all()

    workout_data: List[dict] = []
    for workout in workouts:
        exercises_result = await db.execute(
            select(Exercise)
            .where(Exercise.workout_id == workout.id)
            .order_by(Exercise.exercise_order)
        )
        exercises = exercises_result.scalars().all()
        workout_data.append(_workout_to_dict(workout, exercises))

    return {
        "id": str(plan.id),
        "user_id": str(plan.user_id),
        "week_start": plan.week_start.isoformat(),
        "workouts": workout_data,
        "difficulty_level": plan.difficulty_level or 0,
        "created_by_ai": plan.created_by_ai,
        "adaptation_reason": plan.adaptation_reason,
    }


@router.post("/generate", response_model=WorkoutPlanResponse)
async def generate_workout_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = datetime.now().date()
    week_start = today - timedelta(days=today.weekday())

    plan = FitnessPlan(
        user_id=current_user.id,
        week_start=week_start,
        week_end=week_start + timedelta(days=6),
        difficulty_level=7,
        created_by_ai=True,
        adaptation_reason="Initial plan based on your fitness profile",
    )
    db.add(plan)
    await db.flush()

    workouts = _create_sample_workouts(plan.id)
    db.add_all(workouts)
    await db.flush()

    for workout in workouts:
        exercises = _create_sample_exercises(workout.id, workout.workout_type)
        db.add_all(exercises)

    await db.commit()
    await db.refresh(plan)

    workouts_result = await db.execute(
        select(Workout)
        .where(Workout.plan_id == plan.id)
        .order_by(Workout.day_of_week, Workout.created_at)
    )
    created_workouts = workouts_result.scalars().all()

    workout_data: List[dict] = []
    for workout in created_workouts:
        exercises_result = await db.execute(
            select(Exercise)
            .where(Exercise.workout_id == workout.id)
            .order_by(Exercise.exercise_order)
        )
        exercises = exercises_result.scalars().all()
        workout_data.append(_workout_to_dict(workout, exercises))

    return {
        "id": str(plan.id),
        "user_id": str(plan.user_id),
        "week_start": plan.week_start.isoformat(),
        "workouts": workout_data,
        "difficulty_level": plan.difficulty_level or 0,
        "created_by_ai": plan.created_by_ai,
        "adaptation_reason": plan.adaptation_reason,
    }


@router.post("/log-workout")
async def log_workout(
    workout_data: WorkoutLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # TODO: Implement persistence once workout logging is supported
    return {"message": "Workout logged successfully"}


def _create_sample_workouts(plan_id) -> List[Workout]:
    presets = [
        {"type": "strength", "name": "Strength Training", "duration": 45},
        {"type": "cardio", "name": "Cardio Session", "duration": 30},
        {"type": "strength", "name": "Lower Body Strength", "duration": 45},
        {"type": "rest", "name": "Rest Day", "duration": 0},
        {"type": "strength", "name": "Upper Body Strength", "duration": 45},
        {"type": "cardio", "name": "Endurance Cardio", "duration": 30},
        {"type": "rest", "name": "Recovery", "duration": 0},
    ]

    workouts: List[Workout] = []
    for index, preset in enumerate(presets):
        workouts.append(
            Workout(
                plan_id=plan_id,
                day_of_week=index,
                workout_type=preset["type"],
                name=preset["name"],
                duration_minutes=preset["duration"],
            )
        )
    return workouts


def _create_sample_exercises(workout_id, workout_type: str) -> List[Exercise]:
    if workout_type == "strength":
        return [
            Exercise(
                workout_id=workout_id,
                exercise_order=1,
                name="Barbell Squats",
                sets=4,
                reps=8,
                rest_time_seconds=90,
                instructions="Keep core tight, descend until thighs are parallel to the floor",
                muscle_groups=["Quadriceps", "Glutes", "Core"],
                equipment_required=["Barbell", "Squat Rack"],
            ),
            Exercise(
                workout_id=workout_id,
                exercise_order=2,
                name="Bench Press",
                sets=4,
                reps=10,
                rest_time_seconds=90,
                instructions="Lower bar to chest, press up explosively",
                muscle_groups=["Chest", "Shoulders", "Triceps"],
                equipment_required=["Barbell", "Bench"],
            ),
            Exercise(
                workout_id=workout_id,
                exercise_order=3,
                name="Bent-Over Rows",
                sets=3,
                reps=12,
                rest_time_seconds=60,
                instructions="Hinge at hips, pull bar to lower chest",
                muscle_groups=["Back", "Biceps", "Core"],
                equipment_required=["Barbell"],
            ),
            Exercise(
                workout_id=workout_id,
                exercise_order=4,
                name="Overhead Press",
                sets=3,
                reps=10,
                rest_time_seconds=60,
                instructions="Press weight overhead, keep core engaged",
                muscle_groups=["Shoulders", "Triceps", "Core"],
                equipment_required=["Barbell"],
            ),
        ]
    if workout_type == "cardio":
        return [
            Exercise(
                workout_id=workout_id,
                exercise_order=1,
                name="Running",
                duration_seconds=1200,
                instructions="Maintain a steady pace and focus on breathing",
                muscle_groups=["Legs", "Cardiovascular"],
                equipment_required=["None"],
            ),
            Exercise(
                workout_id=workout_id,
                exercise_order=2,
                name="Jump Rope",
                sets=3,
                duration_seconds=180,
                rest_time_seconds=60,
                instructions="Keep elbows close to your body, use wrists to rotate the rope",
                muscle_groups=["Full Body"],
                equipment_required=["Jump Rope"],
            ),
        ]
    # Stretching / recovery by default
    return [
        Exercise(
            workout_id=workout_id,
            exercise_order=1,
            name="Active Stretching",
            duration_seconds=600,
            instructions="Focus on breathing and gentle movement",
            muscle_groups=["Full Body"],
            equipment_required=["None"],
        )
    ]
