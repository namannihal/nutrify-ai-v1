"""Progress tracking models"""

from datetime import date, datetime
from typing import Optional
from uuid import UUID, uuid4
from sqlalchemy import String, Integer, Text, Date, DECIMAL, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB
from sqlalchemy.sql import func

from app.core.database import Base


class ProgressEntry(Base):
    """Daily progress entry"""
    
    __tablename__ = "progress_entries"
    
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    entry_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    
    # Body Metrics
    weight: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2))
    body_fat_percentage: Mapped[Optional[float]] = mapped_column(DECIMAL(4, 2))
    muscle_mass: Mapped[Optional[float]] = mapped_column(DECIMAL(5, 2))
    
    # Body Measurements
    measurements: Mapped[Optional[dict]] = mapped_column(JSONB)
    
    # Subjective Metrics
    mood_score: Mapped[Optional[int]] = mapped_column(Integer)
    energy_score: Mapped[Optional[int]] = mapped_column(Integer)
    stress_score: Mapped[Optional[int]] = mapped_column(Integer)
    
    # Sleep & Hydration
    sleep_hours: Mapped[Optional[float]] = mapped_column(DECIMAL(3, 1))
    sleep_quality: Mapped[Optional[int]] = mapped_column(Integer)
    water_intake_ml: Mapped[Optional[int]] = mapped_column(Integer)
    
    # Adherence
    adherence_score: Mapped[Optional[int]] = mapped_column(Integer)
    
    # Notes & Media
    notes: Mapped[Optional[str]] = mapped_column(Text)
    photos: Mapped[Optional[dict]] = mapped_column(JSONB)
    
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    
    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="progress_entries")


class AIInsight(Base):
    """AI-generated insights and recommendations"""
    
    __tablename__ = "ai_insights"
    
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    insight_type: Mapped[str] = mapped_column(String(50), nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    explanation: Mapped[str] = mapped_column(Text, nullable=False)
    
    # Action Items
    action_items: Mapped[Optional[dict]] = mapped_column(JSONB)
    
    # Priority & Status
    priority: Mapped[str] = mapped_column(String(20), nullable=False)
    is_read: Mapped[bool] = mapped_column(Integer, default=False)
    is_dismissed: Mapped[bool] = mapped_column(Integer, default=False)
    
    # AI Metadata
    ai_model_used: Mapped[Optional[str]] = mapped_column(String(100))
    confidence_score: Mapped[Optional[float]] = mapped_column(DECIMAL(3, 2))
    generated_from_data: Mapped[Optional[dict]] = mapped_column(JSONB)
    
    # Display Control
    display_until: Mapped[Optional[datetime]]
    
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    read_at: Mapped[Optional[datetime]]
    dismissed_at: Mapped[Optional[datetime]]


class ChatMessage(Base):
    """AI chat message history"""
    
    __tablename__ = "chat_messages"
    
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    message_type: Mapped[str] = mapped_column(String(20), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    
    # AI Response Metadata
    category: Mapped[Optional[str]] = mapped_column(String(50))
    explanation: Mapped[Optional[str]] = mapped_column(Text)
    suggestions: Mapped[Optional[dict]] = mapped_column(JSONB)
    
    # Context
    context_data: Mapped[Optional[dict]] = mapped_column(JSONB)
    ai_model_used: Mapped[Optional[str]] = mapped_column(String(100))
    
    # Feedback
    user_rating: Mapped[Optional[int]] = mapped_column(Integer)
    user_feedback: Mapped[Optional[str]] = mapped_column(Text)
    
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
