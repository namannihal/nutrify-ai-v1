"""Fitness plan and workout models"""

from datetime import date, datetime
from typing import Optional
from uuid import UUID, uuid4
from sqlalchemy import Boolean, String, Integer, Text, Date, ARRAY, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.sql import func

from app.core.database import Base


class FitnessPlan(Base):
    """Weekly fitness plan"""
    
    __tablename__ = "fitness_plans"
    
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # Week Range
    week_start: Mapped[date] = mapped_column(Date, nullable=False)
    week_end: Mapped[date] = mapped_column(Date, nullable=False)
    
    # Plan Metadata
    difficulty_level: Mapped[Optional[int]] = mapped_column(Integer)
    focus_areas: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text))
    estimated_calories_burn: Mapped[Optional[int]] = mapped_column(Integer)
    
    # AI Metadata
    created_by_ai: Mapped[bool] = mapped_column(Boolean, default=True)
    adaptation_reason: Mapped[Optional[str]] = mapped_column(Text)
    ai_model_version: Mapped[Optional[str]] = mapped_column(String(50))
    
    # Status
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    version: Mapped[int] = mapped_column(Integer, default=1)
    
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    
    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="fitness_plans")
    workouts: Mapped[list["Workout"]] = relationship(
        "Workout",
        back_populates="plan",
        cascade="all, delete-orphan"
    )


class Workout(Base):
    """Individual workout session"""
    
    __tablename__ = "workouts"
    
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    plan_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("fitness_plans.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    day_of_week: Mapped[int] = mapped_column(Integer, nullable=False)  # 0=Monday
    workout_type: Mapped[str] = mapped_column(String(50), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    estimated_calories: Mapped[Optional[int]] = mapped_column(Integer)
    intensity_level: Mapped[Optional[int]] = mapped_column(Integer)
    
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    
    # Relationships
    plan: Mapped["FitnessPlan"] = relationship("FitnessPlan", back_populates="workouts")
    exercises: Mapped[list["Exercise"]] = relationship(
        "Exercise",
        back_populates="workout",
        cascade="all, delete-orphan"
    )


class Exercise(Base):
    """Individual exercise in a workout"""
    
    __tablename__ = "exercises"
    
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    workout_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("workouts.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    exercise_order: Mapped[int] = mapped_column(Integer, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    
    # Exercise Details
    sets: Mapped[Optional[int]] = mapped_column(Integer)
    reps: Mapped[Optional[int]] = mapped_column(Integer)
    duration_seconds: Mapped[Optional[int]] = mapped_column(Integer)
    rest_time_seconds: Mapped[Optional[int]] = mapped_column(Integer)
    
    # Targets
    muscle_groups: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text))
    equipment_required: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text))
    
    # Instructions
    instructions: Mapped[Optional[str]] = mapped_column(Text)
    video_url: Mapped[Optional[str]] = mapped_column(Text)
    form_cues: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text))
    
    difficulty_level: Mapped[Optional[int]] = mapped_column(Integer)
    
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    
    # Relationships
    workout: Mapped["Workout"] = relationship("Workout", back_populates="exercises")
