"""Gamification models for streaks and achievements"""

from datetime import datetime, date
from typing import Optional
from uuid import UUID, uuid4
from sqlalchemy import String, Integer, Text, Boolean, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB
from sqlalchemy.sql import func

from app.core.database import Base


class UserStreak(Base):
    """Track user workout streaks"""

    __tablename__ = "user_streaks"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True
    )

    # Current streak
    current_streak: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    longest_streak: Mapped[int] = mapped_column(Integer, default=0, server_default="0")

    # Tracking dates
    last_workout_date: Mapped[Optional[date]] = mapped_column(Date)
    streak_start_date: Mapped[Optional[date]] = mapped_column(Date)

    # Weekly tracking (bitmask: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64)
    current_week_workouts: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    week_start_date: Mapped[Optional[date]] = mapped_column(Date)

    # Stats
    total_workouts: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    total_workout_minutes: Mapped[int] = mapped_column(Integer, default=0, server_default="0")

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(nullable=False, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now(),
        onupdate=func.now()
    )

    # Relationships
    user: Mapped["User"] = relationship("User", backref="streak")


class Achievement(Base):
    """Achievement definitions"""

    __tablename__ = "achievements"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)  # e.g., "first_workout", "streak_7"
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    icon: Mapped[str] = mapped_column(String(50), nullable=False)  # Icon name or emoji
    category: Mapped[str] = mapped_column(String(50), nullable=False)  # "workout", "streak", "progress", "nutrition"

    # Requirements (JSONB for flexible conditions)
    requirement_type: Mapped[str] = mapped_column(String(50), nullable=False)  # "count", "streak", "pr", "custom"
    requirement_value: Mapped[int] = mapped_column(Integer, nullable=False)

    # Display
    points: Mapped[int] = mapped_column(Integer, default=10, server_default="10")
    rarity: Mapped[str] = mapped_column(String(20), default="common", server_default="'common'")  # common, rare, epic, legendary
    sort_order: Mapped[int] = mapped_column(Integer, default=0, server_default="0")

    # Active status
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")

    created_at: Mapped[datetime] = mapped_column(nullable=False, server_default=func.now())


class UserAchievement(Base):
    """User's earned achievements"""

    __tablename__ = "user_achievements"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    achievement_id: Mapped[str] = mapped_column(
        String(50),
        ForeignKey("achievements.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # When earned
    earned_at: Mapped[datetime] = mapped_column(nullable=False, server_default=func.now())

    # Optional context (e.g., which PR, which workout)
    context: Mapped[Optional[dict]] = mapped_column(JSONB)

    # Notification status
    notified: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")

    # Relationships
    user: Mapped["User"] = relationship("User", backref="achievements")
    achievement: Mapped["Achievement"] = relationship("Achievement")

    # Unique constraint
    __table_args__ = (
        # Each user can earn each achievement only once
        {"sqlite_autoincrement": True},
    )


# Default achievements to seed
DEFAULT_ACHIEVEMENTS = [
    # Workout achievements
    {
        "id": "first_workout",
        "name": "First Steps",
        "description": "Complete your first workout",
        "icon": "🎯",
        "category": "workout",
        "requirement_type": "workout_count",
        "requirement_value": 1,
        "points": 10,
        "rarity": "common",
        "sort_order": 1,
    },
    {
        "id": "workout_10",
        "name": "Getting Serious",
        "description": "Complete 10 workouts",
        "icon": "💪",
        "category": "workout",
        "requirement_type": "workout_count",
        "requirement_value": 10,
        "points": 25,
        "rarity": "common",
        "sort_order": 2,
    },
    {
        "id": "workout_50",
        "name": "Dedicated",
        "description": "Complete 50 workouts",
        "icon": "🏋️",
        "category": "workout",
        "requirement_type": "workout_count",
        "requirement_value": 50,
        "points": 50,
        "rarity": "rare",
        "sort_order": 3,
    },
    {
        "id": "workout_100",
        "name": "Century Club",
        "description": "Complete 100 workouts",
        "icon": "💯",
        "category": "workout",
        "requirement_type": "workout_count",
        "requirement_value": 100,
        "points": 100,
        "rarity": "epic",
        "sort_order": 4,
    },
    # Streak achievements
    {
        "id": "streak_3",
        "name": "On a Roll",
        "description": "Maintain a 3-day workout streak",
        "icon": "🔥",
        "category": "streak",
        "requirement_type": "streak",
        "requirement_value": 3,
        "points": 15,
        "rarity": "common",
        "sort_order": 10,
    },
    {
        "id": "streak_7",
        "name": "Week Warrior",
        "description": "Maintain a 7-day workout streak",
        "icon": "🔥",
        "category": "streak",
        "requirement_type": "streak",
        "requirement_value": 7,
        "points": 30,
        "rarity": "rare",
        "sort_order": 11,
    },
    {
        "id": "streak_14",
        "name": "Two Week Terror",
        "description": "Maintain a 14-day workout streak",
        "icon": "🔥",
        "category": "streak",
        "requirement_type": "streak",
        "requirement_value": 14,
        "points": 50,
        "rarity": "rare",
        "sort_order": 12,
    },
    {
        "id": "streak_30",
        "name": "Monthly Machine",
        "description": "Maintain a 30-day workout streak",
        "icon": "🏆",
        "category": "streak",
        "requirement_type": "streak",
        "requirement_value": 30,
        "points": 100,
        "rarity": "epic",
        "sort_order": 13,
    },
    {
        "id": "streak_100",
        "name": "Unstoppable",
        "description": "Maintain a 100-day workout streak",
        "icon": "👑",
        "category": "streak",
        "requirement_type": "streak",
        "requirement_value": 100,
        "points": 500,
        "rarity": "legendary",
        "sort_order": 14,
    },
    # PR achievements
    {
        "id": "first_pr",
        "name": "Personal Best",
        "description": "Set your first personal record",
        "icon": "⭐",
        "category": "progress",
        "requirement_type": "pr_count",
        "requirement_value": 1,
        "points": 15,
        "rarity": "common",
        "sort_order": 20,
    },
    {
        "id": "pr_10",
        "name": "Record Breaker",
        "description": "Set 10 personal records",
        "icon": "🌟",
        "category": "progress",
        "requirement_type": "pr_count",
        "requirement_value": 10,
        "points": 40,
        "rarity": "rare",
        "sort_order": 21,
    },
    {
        "id": "pr_50",
        "name": "Champion",
        "description": "Set 50 personal records",
        "icon": "🏅",
        "category": "progress",
        "requirement_type": "pr_count",
        "requirement_value": 50,
        "points": 100,
        "rarity": "epic",
        "sort_order": 22,
    },
    # Volume achievements
    {
        "id": "volume_10k",
        "name": "Heavy Lifter",
        "description": "Lift a total of 10,000 kg",
        "icon": "🪨",
        "category": "progress",
        "requirement_type": "total_volume",
        "requirement_value": 10000,
        "points": 25,
        "rarity": "common",
        "sort_order": 30,
    },
    {
        "id": "volume_100k",
        "name": "Iron Will",
        "description": "Lift a total of 100,000 kg",
        "icon": "⚔️",
        "category": "progress",
        "requirement_type": "total_volume",
        "requirement_value": 100000,
        "points": 75,
        "rarity": "rare",
        "sort_order": 31,
    },
    {
        "id": "volume_1m",
        "name": "Legendary Strength",
        "description": "Lift a total of 1,000,000 kg",
        "icon": "🦁",
        "category": "progress",
        "requirement_type": "total_volume",
        "requirement_value": 1000000,
        "points": 250,
        "rarity": "legendary",
        "sort_order": 32,
    },
    # Weekly achievements
    {
        "id": "perfect_week",
        "name": "Perfect Week",
        "description": "Work out every day for a week",
        "icon": "📅",
        "category": "streak",
        "requirement_type": "perfect_week",
        "requirement_value": 1,
        "points": 50,
        "rarity": "rare",
        "sort_order": 40,
    },
]
