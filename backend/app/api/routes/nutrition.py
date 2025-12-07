from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List
from datetime import datetime, timedelta

from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.nutrition import NutritionPlan, Meal
from app.schemas.nutrition import (
    SimplifiedNutritionPlanResponse as NutritionPlanResponse,
    NutritionPlanCreate,
    MealLogCreate,
)
from app.ai.nutrition_agent import NutritionAgent

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
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate nutrition plan: {str(e)}"
        )
    
    # Convert to response format
    return {
        "id": str(plan.id),
        "user_id": str(plan.user_id),
        "week_start": plan.week_start.isoformat(),
        "daily_calories": plan.daily_calories,
        "macros": plan.macros,
        "meals": [
            {
                "day": meal.day,
                "breakfast": [m.dict() for m in meal.breakfast],
                "lunch": [m.dict() for m in meal.lunch],
                "dinner": [m.dict() for m in meal.dinner],
                "snacks": [m.dict() for m in meal.snacks],
            }
            for meal in plan.meals
        ],
        "created_by_ai": True,
        "adaptation_reason": "AI-generated personalized meal plan",
    }
    
    # Fetch created meals
    meals_result = await db.execute(
        select(Meal).where(Meal.nutrition_plan_id == plan.id)
    )
    created_meals = meals_result.scalars().all()
    
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
        "meals": _organize_meals_by_day(created_meals),
        "created_by_ai": plan.created_by_ai,
        "adaptation_reason": plan.adaptation_reason,
    }


@router.post("/log-meal")
async def log_meal(
    meal_data: MealLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Log a consumed meal"""
    # TODO: Implement meal logging
    return {"message": "Meal logged successfully"}


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
        "protein": float(meal.protein_grams),
        "carbs": float(meal.carbs_grams),
        "fat": float(meal.fat_grams),
        "ingredients": meal.ingredients or [],
        "instructions": meal.instructions,
        "prep_time": meal.prep_time_minutes,
    }


def _create_sample_meals(plan_id) -> List[Meal]:
    """Create sample meals for testing"""
    meals = []
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    for day in days:
        # Breakfast
        meals.append(Meal(
            plan_id=plan_id,
            day_of_week=days.index(day),  # Convert to 0-6 index
            meal_type="breakfast",
            name=f"Protein Oatmeal Bowl",
            calories=450,
            protein_grams=25,
            carbs_grams=55,
            fat_grams=12,
            ingredients={"items": ["Oats", "Protein powder", "Banana", "Almond butter", "Berries"]},
            instructions="Mix oats with water, add protein powder, top with fruits and nut butter",
            prep_time_minutes=10,
        ))
        
        # Lunch
        meals.append(Meal(
            plan_id=plan_id,
            day_of_week=days.index(day),  # Convert to 0-6 index
            meal_type="lunch",
            name=f"Grilled Chicken Salad",
            calories=520,
            protein_grams=45,
            carbs_grams=25,
            fat_grams=28,
            ingredients={"items": ["Chicken breast", "Mixed greens", "Avocado", "Cherry tomatoes", "Olive oil"]},
            instructions="Grill chicken, toss with greens and vegetables, drizzle with olive oil",
            prep_time_minutes=15,
        ))
        
        # Dinner
        meals.append(Meal(
            plan_id=plan_id,
            day_of_week=days.index(day),  # Convert to 0-6 index
            meal_type="dinner",
            name=f"Salmon with Quinoa",
            calories=680,
            protein_grams=42,
            carbs_grams=45,
            fat_grams=32,
            ingredients={"items": ["Salmon fillet", "Quinoa", "Broccoli", "Sweet potato", "Lemon"]},
            instructions="Bake salmon, cook quinoa, steam vegetables",
            prep_time_minutes=25,
        ))
        
        # Snack
        meals.append(Meal(
            plan_id=plan_id,
            day_of_week=days.index(day),  # Convert to 0-6 index
            meal_type="snack",
            name=f"Greek Yogurt & Nuts",
            calories=280,
            protein_grams=20,
            carbs_grams=15,
            fat_grams=18,
            ingredients={"items": ["Greek yogurt", "Mixed nuts", "Honey"]},
            instructions="Mix yogurt with nuts and a drizzle of honey",
            prep_time_minutes=2,
        ))
    
    return meals
