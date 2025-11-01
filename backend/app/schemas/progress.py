"""Progress tracking schemas"""

from typing import Optional, Dict, Any
from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field


class ProgressEntryBase(BaseModel):
    """Base progress entry schema"""
    entry_date: date
    weight: Optional[float] = Field(None, gt=0)
    body_fat_percentage: Optional[float] = Field(None, ge=0, le=100)
    muscle_mass: Optional[float] = Field(None, gt=0)
    measurements: Optional[Dict[str, float]] = None
    mood_score: Optional[int] = Field(None, ge=1, le=10)
    energy_score: Optional[int] = Field(None, ge=1, le=10)
    stress_score: Optional[int] = Field(None, ge=1, le=10)
    sleep_hours: Optional[float] = Field(None, ge=0, le=24)
    sleep_quality: Optional[int] = Field(None, ge=1, le=10)
    water_intake_ml: Optional[int] = Field(None, ge=0)
    adherence_score: Optional[int] = Field(None, ge=0, le=100)
    notes: Optional[str] = None
    photos: Optional[Dict[str, Any]] = None


class ProgressEntryCreate(ProgressEntryBase):
    """Progress entry creation schema"""
    pass


class ProgressEntryUpdate(BaseModel):
    """Progress entry update schema"""
    weight: Optional[float] = Field(None, gt=0)
    body_fat_percentage: Optional[float] = Field(None, ge=0, le=100)
    muscle_mass: Optional[float] = Field(None, gt=0)
    mood_score: Optional[int] = Field(None, ge=1, le=10)
    energy_score: Optional[int] = Field(None, ge=1, le=10)
    notes: Optional[str] = None


class ProgressEntryResponse(ProgressEntryBase):
    """Progress entry response schema"""
    id: UUID
    user_id: UUID
    created_at: datetime
    
    model_config = {"from_attributes": True}


class ProgressStatsResponse(BaseModel):
    """Progress statistics response"""
    weight_change: Optional[float] = None
    body_fat_change: Optional[float] = None
    avg_adherence: Optional[float] = None
    avg_mood: Optional[float] = None
    avg_energy: Optional[float] = None
    total_entries: int
    streak_days: int


class AIInsightBase(BaseModel):
    """Base AI insight schema"""
    insight_type: str
    title: str
    message: str
    explanation: str
    action_items: Optional[Dict[str, Any]] = None
    priority: str = "medium"


class AIInsightResponse(AIInsightBase):
    """AI insight response schema"""
    id: UUID
    user_id: UUID
    is_read: bool
    is_dismissed: bool
    ai_model_used: Optional[str] = None
    confidence_score: Optional[float] = None
    created_at: datetime
    
    model_config = {"from_attributes": True}


class ChatMessageBase(BaseModel):
    """Base chat message schema"""
    content: str


class ChatMessageCreate(ChatMessageBase):
    """Chat message creation schema"""
    pass


class ChatMessageResponse(ChatMessageBase):
    """Chat message response schema"""
    id: UUID
    user_id: UUID
    message_type: str
    category: Optional[str] = None
    explanation: Optional[str] = None
    suggestions: Optional[Dict[str, Any]] = None
    created_at: datetime
    
    model_config = {"from_attributes": True}


class ChatConversationResponse(BaseModel):
    """Chat conversation response"""
    messages: list[ChatMessageResponse]
    total: int
