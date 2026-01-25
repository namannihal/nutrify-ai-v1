"""User and profile schemas"""

from typing import Optional, List, Any, Dict
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    """Base user schema"""
    email: EmailStr
    name: str


class UserCreate(UserBase):
    """User creation schema"""
    password: str = Field(..., min_length=8)


class UserUpdate(BaseModel):
    """User update schema"""
    name: Optional[str] = None
    avatar_url: Optional[str] = None


class UserResponse(UserBase):
    """User response schema"""
    id: UUID
    avatar_url: Optional[str] = None
    subscription_tier: str
    email_verified: bool
    is_active: bool
    created_at: datetime
    
    model_config = {"from_attributes": True}


class UserProfileBase(BaseModel):
    """Base profile schema"""
    age: Optional[int] = Field(None, gt=0, lt=150)
    gender: Optional[str] = None
    height: Optional[float] = Field(None, gt=0)  # cm
    weight: Optional[float] = Field(None, gt=0)  # kg
    primary_goal: Optional[str] = None
    secondary_goals: Optional[List[str]] = None
    activity_level: Optional[str] = None
    fitness_experience: Optional[str] = None
    dietary_restrictions: Optional[List[str]] = None
    allergies: Optional[str] = None
    meals_per_day: Optional[int] = Field(None, ge=1, le=10)
    cooking_time: Optional[str] = None
    workout_days_per_week: Optional[str] = None
    workout_duration: Optional[str] = None
    preferred_workout_time: Optional[str] = None
    equipment_access: Optional[List[str]] = None
    # JSONB fields for detailed preferences
    unit_preferences: Optional[Dict[str, Any]] = None
    fitness_preferences: Optional[Dict[str, Any]] = None
    nutrition_preferences: Optional[Dict[str, Any]] = None


class UserProfileCreate(UserProfileBase):
    """Profile creation schema"""
    data_consent: bool = True
    health_disclaimer: bool = True
    marketing_consent: bool = False


class UserProfileUpdate(UserProfileBase):
    """Profile update schema"""
    onboarding_completed: Optional[bool] = None
    data_consent: Optional[bool] = None
    health_disclaimer: Optional[bool] = None
    marketing_consent: Optional[bool] = None


class UserProfileResponse(UserProfileBase):
    """Profile response schema"""
    id: UUID
    user_id: UUID
    onboarding_completed: bool
    unit_preferences: Optional[Dict[str, Any]] = None
    fitness_preferences: Optional[Dict[str, Any]] = None
    nutrition_preferences: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
