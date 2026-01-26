"""Workout session models for set-level tracking"""

from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID, uuid4
from sqlalchemy import Boolean, String, Integer, Text, DECIMAL, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.sql import func

from app.core.database import Base


class WorkoutSession(Base):
    """Active or completed workout session with set-level data"""

    __tablename__ = "workout_sessions"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Optional reference to a planned workout (string to support custom workouts)
    workout_id: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True
    )

    # Session details
    workout_name: Mapped[str] = mapped_column(String(255), nullable=False)
    started_at: Mapped[datetime] = mapped_column(nullable=False, server_default=func.now())
    completed_at: Mapped[Optional[datetime]] = mapped_column(nullable=True)

    # Status: 'active', 'completed', 'abandoned'
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="active")

    # Computed metrics (updated on completion)
    total_volume: Mapped[int] = mapped_column(Integer, default=0)  # Total weight × reps
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0)

    notes: Mapped[Optional[str]] = mapped_column(Text)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="workout_sessions")
    workout: Mapped[Optional["Workout"]] = relationship("Workout")
    sets: Mapped[list["ExerciseSet"]] = relationship(
        "ExerciseSet",
        back_populates="session",
        cascade="all, delete-orphan",
        order_by="ExerciseSet.completed_at"
    )


class ExerciseSet(Base):
    """Individual set within a workout session"""

    __tablename__ = "exercise_sets"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    session_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("workout_sessions.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Optional reference to a planned exercise (string to support custom exercises)
    exercise_id: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True
    )

    # Denormalized for flexibility (in case exercise is deleted or for ad-hoc exercises)
    exercise_name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)

    # Set details
    set_number: Mapped[int] = mapped_column(Integer, nullable=False)
    weight_kg: Mapped[Decimal] = mapped_column(DECIMAL(6, 2), nullable=False, default=0)
    reps: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    # Set flags
    is_warmup: Mapped[bool] = mapped_column(Boolean, default=False)
    is_pr: Mapped[bool] = mapped_column(Boolean, default=False)  # Personal record

    # Rest tracking
    rest_seconds: Mapped[int] = mapped_column(Integer, default=0)  # Rest after this set

    completed_at: Mapped[datetime] = mapped_column(nullable=False, server_default=func.now())
    notes: Mapped[Optional[str]] = mapped_column(Text)

    # Relationships
    session: Mapped["WorkoutSession"] = relationship("WorkoutSession", back_populates="sets")
    exercise: Mapped[Optional["Exercise"]] = relationship("Exercise")


class PersonalRecord(Base):
    """Track personal records per exercise"""

    __tablename__ = "personal_records"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Normalized exercise name for grouping
    exercise_name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)

    # Record type: 'weight' (max weight lifted), 'volume' (max weight × reps in one set), 'reps' (max reps at any weight)
    record_type: Mapped[str] = mapped_column(String(20), nullable=False)

    # The record value
    value: Mapped[Decimal] = mapped_column(DECIMAL(10, 2), nullable=False)

    # Additional context
    weight_kg: Mapped[Optional[Decimal]] = mapped_column(DECIMAL(6, 2))  # For reps PR
    reps: Mapped[Optional[int]] = mapped_column(Integer)  # For weight PR

    achieved_at: Mapped[datetime] = mapped_column(nullable=False, server_default=func.now())

    # Reference to the session where this PR was achieved
    session_id: Mapped[Optional[UUID]] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("workout_sessions.id", ondelete="SET NULL"),
        nullable=True
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="personal_records")
    session: Mapped[Optional["WorkoutSession"]] = relationship("WorkoutSession")
