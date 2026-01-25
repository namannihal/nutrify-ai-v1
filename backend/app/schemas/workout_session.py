"""Workout session schemas"""

from typing import Optional, List
from uuid import UUID
from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, Field


class ExerciseSetBase(BaseModel):
    """Base exercise set schema"""
    exercise_name: str
    set_number: int = Field(..., ge=1)
    weight_kg: Decimal = Field(default=0, ge=0)
    reps: int = Field(default=0, ge=0)
    is_warmup: bool = False
    rest_seconds: int = Field(default=0, ge=0)
    notes: Optional[str] = None


class ExerciseSetCreate(ExerciseSetBase):
    """Create exercise set schema"""
    exercise_id: Optional[UUID] = None


class ExerciseSetResponse(ExerciseSetBase):
    """Exercise set response schema"""
    id: UUID
    session_id: UUID
    exercise_id: Optional[UUID] = None
    is_pr: bool = False
    completed_at: datetime

    model_config = {"from_attributes": True}


class WorkoutSessionBase(BaseModel):
    """Base workout session schema"""
    workout_name: str
    notes: Optional[str] = None


class WorkoutSessionCreate(WorkoutSessionBase):
    """Create workout session schema"""
    workout_id: Optional[UUID] = None


class WorkoutSessionResponse(WorkoutSessionBase):
    """Workout session response schema"""
    id: UUID
    user_id: UUID
    workout_id: Optional[UUID] = None
    started_at: datetime
    completed_at: Optional[datetime] = None
    status: str
    total_volume: int
    duration_seconds: int
    sets: List[ExerciseSetResponse] = []

    model_config = {"from_attributes": True}


class WorkoutSessionSummary(BaseModel):
    """Summary shown after completing a workout"""
    id: UUID
    workout_name: str
    started_at: datetime
    completed_at: datetime
    duration_seconds: int
    total_volume: int
    total_sets: int
    exercises_completed: int
    new_prs: List[dict] = []


class PersonalRecordBase(BaseModel):
    """Base personal record schema"""
    exercise_name: str
    record_type: str  # 'weight', 'volume', 'reps'
    value: Decimal


class PersonalRecordResponse(PersonalRecordBase):
    """Personal record response schema"""
    id: UUID
    user_id: UUID
    weight_kg: Optional[Decimal] = None
    reps: Optional[int] = None
    achieved_at: datetime
    session_id: Optional[UUID] = None

    model_config = {"from_attributes": True}


class ExerciseHistoryEntry(BaseModel):
    """Single entry in exercise history"""
    date: datetime
    weight_kg: Decimal
    reps: int
    is_pr: bool


class ExerciseHistory(BaseModel):
    """History for a specific exercise"""
    exercise_name: str
    entries: List[ExerciseHistoryEntry]
    best_weight: Optional[Decimal] = None
    best_volume: Optional[Decimal] = None  # weight × reps


class StartWorkoutRequest(BaseModel):
    """Request to start a new workout"""
    workout_id: Optional[UUID] = None
    workout_name: str


class LogSetRequest(BaseModel):
    """Request to log a single set"""
    exercise_id: Optional[UUID] = None
    exercise_name: str
    set_number: int = Field(..., ge=1)
    weight_kg: Decimal = Field(..., ge=0)
    reps: int = Field(..., ge=0)
    is_warmup: bool = False
    rest_seconds: int = Field(default=90, ge=0)
    notes: Optional[str] = None


class CompleteWorkoutRequest(BaseModel):
    """Request to complete a workout"""
    notes: Optional[str] = None
