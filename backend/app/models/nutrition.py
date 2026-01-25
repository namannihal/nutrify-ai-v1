"""Nutrition plan and meal models"""

from datetime import date, datetime
from typing import Optional
from uuid import UUID, uuid4
from sqlalchemy import Boolean, String, Integer, Text, Date, ARRAY, DECIMAL, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB
from sqlalchemy.sql import func

from app.core.database import Base


class NutritionPlan(Base):
    """Weekly nutrition plan"""
    
    __tablename__ = "nutrition_plans"
    
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
    
    # Targets
    daily_calories: Mapped[int] = mapped_column(Integer, nullable=False)
    protein_grams: Mapped[int] = mapped_column(Integer, nullable=False)
    carbs_grams: Mapped[int] = mapped_column(Integer, nullable=False)
    fat_grams: Mapped[int] = mapped_column(Integer, nullable=False)
    
    # AI Metadata
    created_by_ai: Mapped[bool] = mapped_column(Boolean, default=True)
    adaptation_reason: Mapped[Optional[str]] = mapped_column(Text)
    ai_model_version: Mapped[Optional[str]] = mapped_column(String(50))
    generation_prompt_hash: Mapped[Optional[str]] = mapped_column(String(64))
    
    # Status
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    version: Mapped[int] = mapped_column(Integer, default=1)
    
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    
    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="nutrition_plans")
    meals: Mapped[list["Meal"]] = relationship(
        "Meal",
        back_populates="plan",
        cascade="all, delete-orphan"
    )


class Meal(Base):
    """Individual meal in a nutrition plan"""
    
    __tablename__ = "meals"
    
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    plan_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("nutrition_plans.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # Meal Info
    day_of_week: Mapped[int] = mapped_column(Integer, nullable=False)  # 0=Monday
    meal_type: Mapped[str] = mapped_column(String(50), nullable=False)
    meal_order: Mapped[int] = mapped_column(Integer, default=1)
    
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    
    # Nutrition
    calories: Mapped[int] = mapped_column(Integer, nullable=False)
    protein_grams: Mapped[float] = mapped_column(DECIMAL(5, 2), nullable=False)
    carbs_grams: Mapped[float] = mapped_column(DECIMAL(5, 2), nullable=False)
    fat_grams: Mapped[float] = mapped_column(DECIMAL(5, 2), nullable=False)
    fiber_grams: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2))
    
    # Recipe Details
    ingredients: Mapped[dict] = mapped_column(JSONB, nullable=False)
    instructions: Mapped[Optional[str]] = mapped_column(Text)
    prep_time_minutes: Mapped[Optional[int]] = mapped_column(Integer)
    cook_time_minutes: Mapped[Optional[int]] = mapped_column(Integer)
    
    # Preferences
    cuisine_type: Mapped[Optional[str]] = mapped_column(String(100))
    dietary_tags: Mapped[Optional[list[str]]] = mapped_column(ARRAY(Text))
    
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    
    # Relationships
    plan: Mapped["NutritionPlan"] = relationship("NutritionPlan", back_populates="meals")


class MealLog(Base):
    """Log of meals consumed by user"""

    __tablename__ = "meal_logs"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Optional reference to a planned meal
    meal_id: Mapped[Optional[UUID]] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("meals.id", ondelete="SET NULL"),
        nullable=True
    )

    # Meal details
    meal_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    meal_type: Mapped[str] = mapped_column(String(50), nullable=False)  # breakfast, lunch, dinner, snack

    # If logging a custom meal (not from plan)
    custom_meal_name: Mapped[Optional[str]] = mapped_column(String(255))
    custom_foods: Mapped[Optional[dict]] = mapped_column(JSONB)

    # Nutrition info (can differ from planned if user modified portions)
    calories: Mapped[Optional[int]] = mapped_column(Integer)
    protein_grams: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2))
    carbs_grams: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2))
    fat_grams: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2))

    # User feedback
    satisfaction_rating: Mapped[Optional[int]] = mapped_column(Integer)  # 1-5
    notes: Mapped[Optional[str]] = mapped_column(Text)

    # Tracking how meal was logged
    log_method: Mapped[Optional[str]] = mapped_column(String(50))  # manual, ocr, barcode

    logged_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="meal_logs")
    meal: Mapped[Optional["Meal"]] = relationship("Meal")
