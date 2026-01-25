from datetime import datetime, timedelta
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from fastapi.responses import StreamingResponse
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user
from app.core.database import get_db
from app.models.fitness import Exercise, FitnessPlan, Workout, WorkoutLog
from app.models.user import User
from app.schemas.fitness import WorkoutLogCreate, WorkoutPlanResponse, WorkoutLogResponse
from app.ai.fitness_agent import FitnessAgent
from app.services.generation_service import GenerationService, GenerationType

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
        "duration_seconds": exercise.duration_seconds,
        "rest_time_seconds": exercise.rest_time_seconds,
        "instructions": exercise.instructions,
        "muscle_groups": exercise.muscle_groups or [],
        "equipment_required": exercise.equipment_required or [],
    }

def _workout_to_dict(workout: Workout, exercises: List[Exercise]) -> dict:
    day_index = workout.day_of_week
    day_name = DAY_NAMES[day_index] if 0 <= day_index < len(DAY_NAMES) else str(day_index)
    return {
        "day": day_name,
        "workouts": [
            {
                "id": str(workout.id),
                "name": workout.name,
                "description": workout.description,
                "duration_minutes": workout.duration_minutes,
                "estimated_calories": workout.estimated_calories,
                "intensity_level": workout.intensity_level,
                "exercises": [_exercise_to_dict(ex) for ex in exercises],
            }
        ],
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
    """Generate a new AI-powered workout plan"""
    # Initialize AI agent
    agent = FitnessAgent(db)
    
    # Generate plan using AI
    try:
        plan = await agent.generate_weekly_plan(current_user)
        # Note: Commit is handled by get_db() dependency
        await db.flush()  # Ensure all changes are flushed
    except Exception as e:
        import traceback
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Workout generation failed: {str(e)}")
        logger.error(traceback.format_exc())
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate workout plan: {str(e)}"
        )
    
    # Query workouts from the database (don't rely on relationships)
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


@router.post("/generate-async")
async def generate_workout_plan_async(
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Start async generation of a new AI-powered workout plan"""
    # Check if there's already an active generation for this user
    existing_task = GenerationService.get_user_task(
        str(current_user.id),
        GenerationType.FITNESS
    )
    if existing_task and existing_task.status in ("pending", "in_progress"):
        return {
            "task_id": existing_task.id,
            "status": existing_task.status,
            "message": "Generation already in progress"
        }

    # Create new task
    task = GenerationService.create_task(
        str(current_user.id),
        GenerationType.FITNESS
    )

    # Start generation in background
    background_tasks.add_task(
        GenerationService.run_fitness_generation,
        task.id,
        current_user,
        db
    )

    return {
        "task_id": task.id,
        "status": task.status.value,
        "message": "Generation started"
    }


@router.get("/generation-status/{task_id}")
async def get_generation_status(
    task_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get the status of a generation task"""
    task = GenerationService.get_task(task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )

    # Verify ownership
    if task.user_id != str(current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this task"
        )

    response = {
        "task_id": task.id,
        "status": task.status.value,
        "progress": task.progress,
        "message": task.message,
    }

    if task.result_id:
        response["result_id"] = task.result_id
    if task.error:
        response["error"] = task.error

    return response


@router.get("/generation-status/{task_id}/stream")
async def stream_generation_status(
    task_id: str,
    current_user: User = Depends(get_current_user)
):
    """Stream generation status updates via SSE"""
    task = GenerationService.get_task(task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )

    # Verify ownership
    if task.user_id != str(current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this task"
        )

    return StreamingResponse(
        GenerationService.stream_task_status(task_id),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        }
    )


@router.post("/log-workout", response_model=WorkoutLogResponse)
async def log_workout(
    workout_data: WorkoutLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Log a completed workout session"""
    # If workout_id is provided, fetch the planned workout for reference
    planned_workout = None
    if workout_data.workout_id:
        result = await db.execute(
            select(Workout).where(Workout.id == workout_data.workout_id)
        )
        planned_workout = result.scalar_one_or_none()

    # Create workout log entry
    workout_log = WorkoutLog(
        user_id=current_user.id,
        workout_id=workout_data.workout_id,
        workout_date=workout_data.workout_date,
        custom_workout_name=workout_data.workout_name or (planned_workout.name if planned_workout else None),
        duration_minutes=workout_data.duration_minutes,
        calories_burned=workout_data.calories_burned or (planned_workout.estimated_calories if planned_workout else None),
        difficulty_rating=workout_data.perceived_exertion,
        energy_level=workout_data.mood_after,
        notes=workout_data.notes,
        completed_fully=workout_data.completed,
    )

    db.add(workout_log)
    await db.commit()
    await db.refresh(workout_log)

    # Return in the expected response format
    return {
        "id": workout_log.id,
        "user_id": workout_log.user_id,
        "workout_id": workout_log.workout_id,
        "workout_date": workout_log.workout_date,
        "workout_name": workout_log.custom_workout_name,
        "duration_minutes": workout_log.duration_minutes,
        "calories_burned": workout_log.calories_burned,
        "perceived_exertion": workout_log.difficulty_rating,
        "mood_after": workout_log.energy_level,
        "completed": workout_log.completed_fully,
        "completion_percentage": 100 if workout_log.completed_fully else 0,
        "notes": workout_log.notes,
        "logged_at": workout_log.logged_at,
    }


@router.get("/workout-logs", response_model=List[WorkoutLogResponse])
async def get_workout_logs(
    days: int = 7,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's workout logs for the specified number of days"""
    start_date = datetime.now().date() - timedelta(days=days)

    result = await db.execute(
        select(WorkoutLog)
        .where(
            WorkoutLog.user_id == current_user.id,
            WorkoutLog.workout_date >= start_date
        )
        .order_by(desc(WorkoutLog.workout_date))
    )
    logs = result.scalars().all()

    # Convert to response format
    return [
        {
            "id": log.id,
            "user_id": log.user_id,
            "workout_id": log.workout_id,
            "workout_date": log.workout_date,
            "workout_name": log.custom_workout_name,
            "duration_minutes": log.duration_minutes,
            "calories_burned": log.calories_burned,
            "perceived_exertion": log.difficulty_rating,
            "mood_after": log.energy_level,
            "completed": log.completed_fully,
            "completion_percentage": 100 if log.completed_fully else 0,
            "notes": log.notes,
            "logged_at": log.logged_at,
        }
        for log in logs
    ]
