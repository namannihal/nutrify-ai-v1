"""Fitness schemas"""

from typing import Optional, List
from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field


class ExerciseBase(BaseModel):
    """Base exercise schema"""
    exercise_order: int = Field(..., ge=1)
    name: str
    description: Optional[str] = None
    sets: Optional[int] = Field(None, ge=1)
    reps: Optional[int] = Field(None, ge=1)
    duration_seconds: Optional[int] = Field(None, ge=0)
    rest_time_seconds: Optional[int] = Field(None, ge=0)
    muscle_groups: Optional[List[str]] = None
    equipment_required: Optional[List[str]] = None
    instructions: Optional[str] = None
    video_url: Optional[str] = None
    form_cues: Optional[List[str]] = None
    difficulty_level: Optional[int] = Field(None, ge=1, le=10)


class ExerciseResponse(ExerciseBase):
    """Exercise response schema"""
    id: UUID
    workout_id: UUID
    created_at: datetime
    
    model_config = {"from_attributes": True}


class WorkoutBase(BaseModel):
    """Base workout schema"""
    day_of_week: int = Field(..., ge=0, le=6)
    workout_type: str
    name: str
    description: Optional[str] = None
    duration_minutes: int = Field(..., gt=0)
    estimated_calories: Optional[int] = Field(None, ge=0)
    intensity_level: Optional[int] = Field(None, ge=1, le=10)


class WorkoutResponse(WorkoutBase):
    """Workout response schema"""
    id: UUID
    plan_id: UUID
    created_at: datetime
    exercises: List[ExerciseResponse] = []
    
    model_config = {"from_attributes": True}


class FitnessPlanBase(BaseModel):
    """Base fitness plan schema"""
    week_start: date
    week_end: date
    difficulty_level: Optional[int] = Field(None, ge=1, le=10)
    focus_areas: Optional[List[str]] = None
    estimated_calories_burn: Optional[int] = Field(None, ge=0)


class FitnessPlanCreate(FitnessPlanBase):
    """Fitness plan creation schema"""
    workouts: Optional[List[WorkoutBase]] = None


class FitnessPlanResponse(FitnessPlanBase):
    """Fitness plan response schema"""
    id: UUID
    user_id: UUID
    created_by_ai: bool
    adaptation_reason: Optional[str] = None
    is_active: bool
    version: int
    created_at: datetime
    workouts: List[WorkoutResponse] = []
    
    model_config = {"from_attributes": True}


class FitnessPlanListResponse(BaseModel):
    """List of fitness plans"""
    plans: List[FitnessPlanResponse]
    total: int


class WorkoutLogBase(BaseModel):
    """Base workout log schema"""
    workout_date: date
    workout_name: Optional[str] = None
    duration_minutes: int = Field(..., gt=0)
    calories_burned: Optional[int] = Field(None, ge=0)
    perceived_exertion: Optional[int] = Field(None, ge=1, le=10)
    mood_after: Optional[int] = Field(None, ge=1, le=10)
    completed: bool = True
    completion_percentage: Optional[int] = Field(100, ge=0, le=100)
    notes: Optional[str] = None


class WorkoutLogCreate(WorkoutLogBase):
    """Workout log creation schema"""
    workout_id: Optional[UUID] = None


class WorkoutLogResponse(WorkoutLogBase):
    """Workout log response schema"""
    id: UUID
    user_id: UUID
    workout_id: Optional[UUID] = None
    logged_at: datetime
    
    model_config = {"from_attributes": True}


# Additional schemas for API routes
class WorkoutPlanResponse(BaseModel):
    """Simplified workout plan response for API"""
    id: str
    user_id: str
    week_start: str
    workouts: List[dict]
    difficulty_level: int
    created_by_ai: bool
    adaptation_reason: Optional[str] = None
