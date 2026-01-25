import asyncio
from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form, BackgroundTasks
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional
from datetime import datetime, timedelta

from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.nutrition import NutritionPlan, Meal, MealLog
from app.schemas.nutrition import (
    SimplifiedNutritionPlanResponse as NutritionPlanResponse,
    NutritionPlanCreate,
    MealLogCreate,
    MealLogResponse,
)
from app.ai.nutrition_agent import NutritionAgent
from app.services.vision_service import VisionService
from app.services.generation_service import GenerationService, GenerationType

router = APIRouter()


@router.get("/current-plan", response_model=NutritionPlanResponse)
async def get_current_nutrition_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user's current nutrition plan"""
    # Get most recent plan
    result = await db.execute(
        select(NutritionPlan)
        .where(NutritionPlan.user_id == current_user.id)
        .order_by(desc(NutritionPlan.week_start))
        .limit(1)
    )
    plan = result.scalar_one_or_none()
    
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No nutrition plan found. Please generate one first."
        )
    
    # Get meals for this plan
    meals_result = await db.execute(
        select(Meal).where(Meal.plan_id == plan.id)
    )
    meals = meals_result.scalars().all()
    
    return {
        "id": str(plan.id),
        "user_id": str(plan.user_id),
        "week_start": plan.week_start.isoformat(),
        "daily_calories": plan.daily_calories,
        "macros": {
            "protein": plan.protein_grams,
            "carbs": plan.carbs_grams,
            "fat": plan.fat_grams,
        },
        "meals": _organize_meals_by_day(meals),
        "created_by_ai": plan.created_by_ai,
        "adaptation_reason": plan.adaptation_reason,
    }


@router.post("/generate", response_model=NutritionPlanResponse)
async def generate_nutrition_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate a new AI-powered nutrition plan"""
    # Initialize AI agent
    agent = NutritionAgent(db)
    
    # Generate plan using AI
    try:
        plan = await agent.generate_weekly_plan(current_user)
        # Note: Commit is handled by get_db() dependency
        await db.flush()  # Ensure all changes are flushed
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate nutrition plan: {str(e)}"
        )
    
    # Query meals from the database (don't rely on relationships)
    meals_result = await db.execute(
        select(Meal)
        .where(Meal.plan_id == plan.id)
        .order_by(Meal.day_of_week, Meal.meal_order)
    )
    meals = meals_result.scalars().all()
    
    return {
        "id": str(plan.id),
        "user_id": str(plan.user_id),
        "week_start": plan.week_start.isoformat(),
        "daily_calories": plan.daily_calories,
        "macros": {
            "protein": plan.protein_grams,
            "carbs": plan.carbs_grams,
            "fat": plan.fat_grams,
        },
        "meals": _organize_meals_by_day(meals),
        "created_by_ai": plan.created_by_ai,
        "adaptation_reason": plan.adaptation_reason,
    }


@router.post("/generate-async")
async def generate_nutrition_plan_async(
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Start async generation of a new AI-powered nutrition plan"""
    # Check if there's already an active generation for this user
    existing_task = GenerationService.get_user_task(
        str(current_user.id),
        GenerationType.NUTRITION
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
        GenerationType.NUTRITION
    )

    # Start generation in background
    background_tasks.add_task(
        GenerationService.run_nutrition_generation,
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


@router.post("/log-meal", response_model=MealLogResponse)
async def log_meal(
    meal_data: MealLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Log a consumed meal"""
    # If meal_id is provided, fetch the planned meal for reference nutrition
    planned_meal = None
    if meal_data.meal_id:
        result = await db.execute(
            select(Meal).where(Meal.id == meal_data.meal_id)
        )
        planned_meal = result.scalar_one_or_none()

    # Create meal log entry
    meal_log = MealLog(
        user_id=current_user.id,
        meal_id=meal_data.meal_id,
        meal_date=meal_data.meal_date,
        meal_type=meal_data.meal_type,
        custom_meal_name=meal_data.custom_meal_name,
        custom_foods=meal_data.custom_foods,
        # Use provided nutrition or fall back to planned meal nutrition
        calories=meal_data.calories or (planned_meal.calories if planned_meal else None),
        protein_grams=meal_data.protein_grams or (float(planned_meal.protein_grams) if planned_meal else None),
        carbs_grams=meal_data.carbs_grams or (float(planned_meal.carbs_grams) if planned_meal else None),
        fat_grams=meal_data.fat_grams or (float(planned_meal.fat_grams) if planned_meal else None),
        satisfaction_rating=meal_data.satisfaction_rating,
        log_method="manual"
    )

    db.add(meal_log)
    await db.commit()
    await db.refresh(meal_log)

    return meal_log


@router.get("/meal-logs", response_model=List[MealLogResponse])
async def get_meal_logs(
    days: int = 7,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user's meal logs for the specified number of days"""
    start_date = datetime.now().date() - timedelta(days=days)

    result = await db.execute(
        select(MealLog)
        .where(
            MealLog.user_id == current_user.id,
            MealLog.meal_date >= start_date
        )
        .order_by(desc(MealLog.meal_date), MealLog.meal_type)
    )
    logs = result.scalars().all()

    return logs


@router.post("/analyze-food-image")
async def analyze_food_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Analyze a food image using OCR/Vision AI"""
    try:
        # Read image data
        image_data = await file.read()

        # Get image format from filename
        image_format = file.filename.split('.')[-1].lower() if '.' in file.filename else 'jpeg'

        # Analyze using Vision AI
        result = await VisionService.analyze_food_image(image_data, image_format)

        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze food image: {str(e)}"
        )


@router.post("/analyze-food-url")
async def analyze_food_url(
    image_url: str = Form(...),
    current_user: User = Depends(get_current_user),
):
    """Analyze a food image from URL using Vision AI"""
    try:
        result = await VisionService.analyze_food_from_url(image_url)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze food image: {str(e)}"
        )


@router.get("/food-suggestions")
async def get_food_suggestions(
    query: str,
    current_user: User = Depends(get_current_user),
):
    """Get food suggestions based on partial name"""
    try:
        suggestions = await VisionService.get_food_suggestions(query)
        return {"suggestions": suggestions}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get food suggestions: {str(e)}"
        )


def _organize_meals_by_day(meals: List[Meal]) -> List[dict]:
    """Organize meals by day of week"""
    days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    organized = []

    for day_index, day in enumerate(days):
        day_meals = [m for m in meals if m.day_of_week == day_index]

        organized.append({
            "day": day,
            "breakfast": [_meal_to_dict(m) for m in day_meals if m.meal_type == "breakfast"],
            "lunch": [_meal_to_dict(m) for m in day_meals if m.meal_type == "lunch"],
            "dinner": [_meal_to_dict(m) for m in day_meals if m.meal_type == "dinner"],
            "snacks": [_meal_to_dict(m) for m in day_meals if m.meal_type == "snack"],
        })

    return organized


def _meal_to_dict(meal: Meal) -> dict:
    """Convert meal model to dict"""
    return {
        "id": str(meal.id),
        "name": meal.name,
        "calories": meal.calories,
        "protein_grams": float(meal.protein_grams),
        "carbs_grams": float(meal.carbs_grams),
        "fat_grams": float(meal.fat_grams),
        "ingredients": meal.ingredients or {},
        "instructions": meal.instructions,
        "prep_time_minutes": meal.prep_time_minutes,
    }
