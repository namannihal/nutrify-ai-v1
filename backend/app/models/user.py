"""User and Profile models"""

from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4
from sqlalchemy import Boolean, String, Integer, Text, ARRAY, DECIMAL, Enum as SQLEnum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.sql import func

from app.core.database import Base


class User(Base):
    """User authentication model"""
    
    __tablename__ = "users"
    
    # Primary Key
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    
    # Authentication
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[Optional[str]] = mapped_column(String(255))
    
    # Profile
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    avatar_url: Mapped[Optional[str]] = mapped_column(Text)
    
    # Subscription
    subscription_tier: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="free",
        server_default="free"
    )
    
    # OAuth
    oauth_provider: Mapped[Optional[str]] = mapped_column(String(50))
    oauth_id: Mapped[Optional[str]] = mapped_column(String(255))
    
    # Status
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now(),
        onupdate=func.now()
    )
    last_login_at: Mapped[Optional[datetime]]
    
    # Relationships
    profile: Mapped[Optional["UserProfile"]] = relationship(
        "UserProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan"
    )
    nutrition_plans: Mapped[list["NutritionPlan"]] = relationship(
        "NutritionPlan",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    fitness_plans: Mapped[list["FitnessPlan"]] = relationship(
        "FitnessPlan",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    progress_entries: Mapped[list["ProgressEntry"]] = relationship(
        "ProgressEntry",
        back_populates="user",
        cascade="all, delete-orphan"
    )


class UserProfile(Base):
    """User profile with preferences and goals"""
    
    __tablename__ = "user_profiles"
    
    # Primary Key
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True
    )
    
    # Personal Info
    age: Mapped[Optional[int]] = mapped_column(Integer)
    gender: Mapped[Optional[str]] = mapped_column(String(50))
    height: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2))  # cm
    weight: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2))  # kg
    
    # Goals & Activity
    primary_goal: Mapped[Optional[str]] = mapped_column(String(50))
    secondary_goals: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text))
    activity_level: Mapped[Optional[str]] = mapped_column(String(50))
    fitness_experience: Mapped[Optional[str]] = mapped_column(String(50))
    
    # Dietary Info
    dietary_restrictions: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text))
    allergies: Mapped[Optional[str]] = mapped_column(Text)
    meals_per_day: Mapped[Optional[int]] = mapped_column(Integer)
    cooking_time: Mapped[Optional[str]] = mapped_column(String(50))
    
    # Workout Preferences
    workout_days_per_week: Mapped[Optional[str]] = mapped_column(String(20))
    workout_duration: Mapped[Optional[str]] = mapped_column(String(20))
    preferred_workout_time: Mapped[Optional[str]] = mapped_column(String(50))
    equipment_access: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text))
    
    # Privacy & Consent
    data_consent: Mapped[bool] = mapped_column(Boolean, default=False)
    marketing_consent: Mapped[bool] = mapped_column(Boolean, default=False)
    health_disclaimer: Mapped[bool] = mapped_column(Boolean, default=False)
    
    # Status
    onboarding_completed: Mapped[bool] = mapped_column(Boolean, default=False)
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now(),
        onupdate=func.now()
    )
    
    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="profile")
