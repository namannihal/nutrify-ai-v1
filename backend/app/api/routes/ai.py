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
from app.ai.motivation_agent import MotivationAgent

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
    # Initialize AI agent
    agent = MotivationAgent(db)
    
    # Generate insights using AI
    try:
        insights_text = await agent.generate_weekly_insights(current_user)
        
        # Create insight record
        insight = AIInsight(
            user_id=current_user.id,
            insight_type="weekly_summary",
            title="Weekly Progress Insights",
            message=insights_text,
            explanation="AI-generated analysis of your weekly progress",
            action_items=[],
            priority="high",
        )
        
        db.add(insight)
        await db.commit()
        await db.refresh(insight)
        
        return [{
            "id": str(insight.id),
            "user_id": str(insight.user_id),
            "type": insight.insight_type,
            "title": insight.title,
            "message": insight.message,
            "explanation": insight.explanation,
            "action_items": insight.action_items or [],
            "created_at": insight.created_at.isoformat(),
            "priority": insight.priority,
        }]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate insights: {str(e)}"
        )


@router.post("/chat", response_model=ChatMessageResponse)
async def chat_with_ai(
    message: ChatMessageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Chat with AI health coach"""
    # Get recent conversation history
    result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.user_id == current_user.id)
        .order_by(desc(ChatMessage.timestamp))
        .limit(10)
    )
    history = list(reversed(result.scalars().all()))
    
    # Initialize AI agent
    agent = MotivationAgent(db)
    
    # Get AI response
    try:
        ai_message = await agent.chat(current_user, message.message, history)
        
        return {
            "response": ai_message.message,
            "explanation": "AI-powered coaching response based on your profile and progress.",
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate chat response: {str(e)}"
        )


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
