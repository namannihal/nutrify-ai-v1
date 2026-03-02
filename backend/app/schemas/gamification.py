"""Gamification schemas for streaks and achievements"""

from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field
from uuid import UUID


class StreakResponse(BaseModel):
    """User streak information"""
    current_streak: int = Field(ge=0)
    longest_streak: int = Field(ge=0)
    last_workout_date: Optional[date] = None
    streak_start_date: Optional[date] = None
    total_workouts: int = Field(ge=0)
    total_workout_minutes: int = Field(ge=0)

    # Weekly breakdown (Mon-Sun)
    current_week_workouts: int = Field(ge=0)  # Bitmask
    week_workout_days: List[str] = []  # ["monday", "wednesday", "friday"]

    class Config:
        from_attributes = True


class AchievementResponse(BaseModel):
    """Achievement definition"""
    id: str
    name: str
    description: str
    icon: str
    category: str
    requirement_type: str
    requirement_value: int
    points: int
    rarity: str
    sort_order: int

    class Config:
        from_attributes = True


class UserAchievementResponse(BaseModel):
    """User's earned achievement"""
    id: UUID
    achievement_id: str
    earned_at: datetime
    context: Optional[dict] = None
    notified: bool = False

    # Nested achievement details
    achievement: AchievementResponse

    class Config:
        from_attributes = True


class AchievementProgressResponse(BaseModel):
    """Achievement with user's progress"""
    achievement: AchievementResponse
    earned: bool = False
    earned_at: Optional[datetime] = None
    current_progress: int = 0  # Current value towards the achievement
    progress_percentage: float = 0.0  # 0-100

    class Config:
        from_attributes = True


class GamificationStatsResponse(BaseModel):
    """Complete gamification stats for a user"""
    streak: StreakResponse
    total_points: int = 0
    achievements_earned: int = 0
    achievements_total: int = 0
    recent_achievements: List[UserAchievementResponse] = []

    class Config:
        from_attributes = True


class NewAchievementNotification(BaseModel):
    """Notification for newly earned achievement"""
    achievement: AchievementResponse
    earned_at: datetime
    context: Optional[dict] = None
