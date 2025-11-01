from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List
from datetime import datetime

from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.progress import AIInsight, ChatMessage
from app.schemas.ai import (
    AIInsightResponse,
    ChatMessageRequest,
    ChatMessageResponse,
)

router = APIRouter()


@router.get("/insights", response_model=List[AIInsightResponse])
async def get_ai_insights(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get AI-generated insights for the user"""
    result = await db.execute(
        select(AIInsight)
        .where(AIInsight.user_id == current_user.id)
        .order_by(desc(AIInsight.created_at))
        .limit(limit)
    )
    insights = result.scalars().all()
    
    return [
        {
            "id": str(insight.id),
            "user_id": str(insight.user_id),
            "type": insight.insight_type,
            "title": insight.title,
            "message": insight.message,
            "explanation": insight.explanation,
            "action_items": insight.action_items or [],
            "created_at": insight.created_at.isoformat(),
            "priority": insight.priority,
        }
        for insight in insights
    ]


@router.post("/analyze", response_model=List[AIInsightResponse])
async def request_ai_analysis(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Request AI to analyze user data and generate new insights"""
    # TODO: Integrate with LangChain agent for real AI analysis
    
    # For now, create sample insights
    sample_insights = [
        AIInsight(
            user_id=current_user.id,
            insight_type="progress",
            title="Great Progress This Week!",
            message="Your consistency improved by 15% this week. Keep up the excellent work!",
            explanation="Based on your workout adherence and progressive overload data.",
            action_items=["Continue current routine", "Consider adding 5% more weight to compound exercises"],
            priority="high",
        ),
        AIInsight(
            user_id=current_user.id,
            insight_type="nutrition",
            title="Protein Intake Optimization",
            message="Your protein intake has been slightly below target for 3 days.",
            explanation="Adequate protein is crucial for muscle recovery and growth.",
            action_items=["Add a protein shake post-workout", "Include more lean protein in lunch"],
            priority="medium",
        ),
    ]
    
    for insight in sample_insights:
        db.add(insight)
    
    await db.commit()
    
    # Return newly created insights
    for insight in sample_insights:
        await db.refresh(insight)
    
    return [
        {
            "id": str(insight.id),
            "user_id": str(insight.user_id),
            "type": insight.insight_type,
            "title": insight.title,
            "message": insight.message,
            "explanation": insight.explanation,
            "action_items": insight.action_items or [],
            "created_at": insight.created_at.isoformat(),
            "priority": insight.priority,
        }
        for insight in sample_insights
    ]


@router.post("/chat", response_model=ChatMessageResponse)
async def chat_with_ai(
    message: ChatMessageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Chat with AI health coach"""
    # Save user message
    user_message = ChatMessage(
        user_id=current_user.id,
        message_type="user",
        content=message.message,
    )
    db.add(user_message)
    await db.commit()
    
    # TODO: Integrate with LangChain agent for real AI chat
    # For now, generate a simple response
    response_text = _generate_mock_response(message.message)
    
    # Save AI response
    ai_message = ChatMessage(
        user_id=current_user.id,
        message_type="assistant",
        content=response_text,
    )
    db.add(ai_message)
    await db.commit()
    
    return {
        "response": response_text,
        "explanation": "Based on your current progress and goals.",
    }


def _generate_mock_response(user_input: str) -> str:
    """Generate a mock AI response based on keywords"""
    input_lower = user_input.lower()
    
    if "progress" in input_lower or "doing" in input_lower:
        return "You're doing fantastic! This week you've maintained excellent adherence to your plan. Your consistency is impressive - keep up the great work!"
    elif "meal" in input_lower or "food" in input_lower or "nutrition" in input_lower:
        return "Based on your current macro needs, I recommend a grilled salmon bowl with quinoa and roasted vegetables. This provides 45g protein, 35g carbs, and healthy omega-3 fats, perfectly aligned with your muscle-building goals."
    elif "workout" in input_lower or "exercise" in input_lower or "fitness" in input_lower:
        return "Your next workout is upper body strength training. Since your last session showed great improvement in bench press, I've slightly increased the intensity. Focus on controlled movements and proper form!"
    elif "motivat" in input_lower or "tired" in input_lower:
        return "I understand you're feeling challenged right now, and that's completely normal! Remember, you've already achieved so much. Every champion has moments of doubt, but what separates them is pushing through. You've got this! 💪"
    else:
        return "I'm here to help with your health and fitness journey! I can analyze your progress, suggest meals, modify workouts, provide motivation, and answer questions about nutrition or exercise. What would you like to focus on today?"
