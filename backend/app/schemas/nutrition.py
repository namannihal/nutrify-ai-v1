"""Nutrition schemas"""

from typing import Optional, List, Dict, Any
from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field


class MealBase(BaseModel):
    """Base meal schema"""
    day_of_week: int = Field(..., ge=0, le=6)
    meal_type: str
    name: str
    description: Optional[str] = None
    calories: int = Field(..., gt=0)
    protein_grams: float = Field(..., ge=0)
    carbs_grams: float = Field(..., ge=0)
    fat_grams: float = Field(..., ge=0)
    fiber_grams: Optional[float] = Field(None, ge=0)
    ingredients: Dict[str, Any]
    instructions: Optional[str] = None
    prep_time_minutes: Optional[int] = Field(None, ge=0)
    cook_time_minutes: Optional[int] = Field(None, ge=0)
    cuisine_type: Optional[str] = None
    dietary_tags: Optional[List[str]] = None


class MealResponse(MealBase):
    """Meal response schema"""
    id: UUID
    plan_id: UUID
    created_at: datetime
    
    model_config = {"from_attributes": True}


class NutritionPlanBase(BaseModel):
    """Base nutrition plan schema"""
    week_start: date
    week_end: date
    daily_calories: int = Field(..., gt=0)
    protein_grams: int = Field(..., gt=0)
    carbs_grams: int = Field(..., gt=0)
    fat_grams: int = Field(..., gt=0)


class NutritionPlanCreate(NutritionPlanBase):
    """Nutrition plan creation schema"""
    meals: Optional[List[MealBase]] = None


class NutritionPlanResponse(NutritionPlanBase):
    """Nutrition plan response schema"""
    id: UUID
    user_id: UUID
    created_by_ai: bool
    adaptation_reason: Optional[str] = None
    is_active: bool
    version: int
    created_at: datetime
    meals: List[MealResponse] = []
    
    model_config = {"from_attributes": True}


class NutritionPlanListResponse(BaseModel):
    """List of nutrition plans"""
    plans: List[NutritionPlanResponse]
    total: int


class MealLogBase(BaseModel):
    """Base meal log schema"""
    meal_date: date
    meal_type: str
    calories: Optional[int] = None
    protein_grams: Optional[float] = None
    carbs_grams: Optional[float] = None
    fat_grams: Optional[float] = None
    custom_meal_name: Optional[str] = None
    satisfaction_rating: Optional[int] = Field(None, ge=1, le=5)


class MealLogCreate(MealLogBase):
    """Meal log creation schema"""
    meal_id: Optional[UUID] = None
    custom_foods: Optional[Dict[str, Any]] = None


class MealLogResponse(MealLogBase):
    """Meal log response schema"""
    id: UUID
    user_id: UUID
    meal_id: Optional[UUID] = None
    logged_at: datetime
    log_method: Optional[str] = None
    
    model_config = {"from_attributes": True}


# Additional schemas for API routes - override the complex ones above for simpler API responses
class SimplifiedNutritionPlanResponse(BaseModel):
    """Simplified nutrition plan response for API"""
    id: str
    user_id: str
    week_start: str
    daily_calories: int
    macros: dict
    meals: List[dict]
    created_by_ai: bool
    adaptation_reason: Optional[str] = None
