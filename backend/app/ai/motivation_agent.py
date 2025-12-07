"""
Motivation Agent - Provides coaching, insights, and chat support
Implements conversational AI for motivation and guidance
"""

from typing import Dict, List, Optional
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

from app.models.user import User
from app.models.progress import ChatMessage, ProgressEntry
from app.memory.hierarchical_memory import HierarchicalMemory
from app.core.config import settings


class MotivationAgent:
    """
    AI Agent for coaching, motivation, and chat interactions
    Provides personalized insights and support
    """
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.llm = ChatOpenAI(
            model=settings.AI_MODEL,
            temperature=0.8,  # Higher temperature for more conversational responses
            api_key=settings.OPENAI_API_KEY
        )
        self.memory = HierarchicalMemory(db)
        
    async def chat(
        self,
        user: User,
        message: str,
        conversation_history: Optional[List[ChatMessage]] = None
    ) -> ChatMessage:
        """
        Handle chat interaction with user
        
        Args:
            user: User object
            message: User's message
            conversation_history: Recent chat history
            
        Returns:
            ChatMessage with AI response
        """
        # Retrieve user context
        context = await self.memory.get_user_context(
            user_id=user.id,
            context_type="coaching"
        )
        
        # Build conversation with context
        messages = self._build_chat_messages(user, message, conversation_history, context)
        
        # Get AI response
        response = await self.llm.ainvoke(messages)
        
        # Store user message
        user_msg = ChatMessage(
            user_id=user.id,
            message=message,
            message_type="user",
            timestamp=datetime.utcnow()
        )
        self.db.add(user_msg)
        
        # Store AI response
        ai_msg = ChatMessage(
            user_id=user.id,
            message=response.content,
            message_type="ai",
            timestamp=datetime.utcnow()
        )
        self.db.add(ai_msg)
        
        await self.db.commit()
        await self.db.refresh(ai_msg)
        
        return ai_msg
        
    async def generate_weekly_insights(
        self,
        user: User
    ) -> str:
        """
        Generate weekly progress insights and recommendations
        
        Args:
            user: User object
            
        Returns:
            Insight text
        """
        # Get user's progress data for the week
        week_ago = datetime.utcnow() - timedelta(days=7)
        
        from sqlalchemy import select
        stmt = select(ProgressEntry).where(
            ProgressEntry.user_id == user.id,
            ProgressEntry.date >= week_ago
        ).order_by(ProgressEntry.date.desc())
        result = await self.db.execute(stmt)
        progress_entries = result.scalars().all()
        
        # Retrieve user context
        context = await self.memory.get_user_context(
            user_id=user.id,
            context_type="insights"
        )
        
        # Build insight generation prompt
        system_prompt = self._build_insights_system_prompt()
        user_prompt = self._build_insights_user_prompt(user, progress_entries, context)
        
        response = await self.llm.ainvoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ])
        
        return response.content
        
    def _build_chat_messages(
        self,
        user: User,
        current_message: str,
        history: Optional[List[ChatMessage]],
        context: Dict
    ) -> List:
        """Build message list for chat"""
        messages = []
        
        # System prompt with user context
        system_prompt = f"""You are a supportive and knowledgeable fitness and nutrition coach AI.
Your role is to motivate, guide, and answer questions for users on their health journey.

USER CONTEXT:
- Name: {user.name or 'User'}
- Goal: {user.profile.primary_goal if user.profile else 'general health'}
- Current Progress: {context.get('progress_summary', 'Starting their journey')}

Communication Style:
- Be encouraging and positive
- Provide actionable advice
- Use empathy and understanding
- Keep responses concise but helpful
- Reference their specific goals and progress when relevant

Remember: You're their coach, not just an information source. Build rapport and trust."""
        
        messages.append(SystemMessage(content=system_prompt))
        
        # Add conversation history (last 5 messages for context)
        if history:
            for msg in history[-5:]:
                if msg.message_type == "user":
                    messages.append(HumanMessage(content=msg.message))
                else:
                    messages.append(AIMessage(content=msg.message))
                    
        # Add current message
        messages.append(HumanMessage(content=current_message))
        
        return messages
        
    def _build_insights_system_prompt(self) -> str:
        """System prompt for insights generation"""
        return """You are an expert fitness and nutrition analyst.
Your role is to analyze user progress data and provide actionable insights.

Key principles:
- Identify patterns and trends in the data
- Highlight achievements and positive behaviors
- Point out areas for improvement with specific suggestions
- Be encouraging but honest
- Provide 3-5 key insights per analysis
- Make recommendations concrete and achievable

Keep insights concise, motivating, and data-driven."""
        
    def _build_insights_user_prompt(
        self,
        user: User,
        progress_entries: List[ProgressEntry],
        context: Dict
    ) -> str:
        """Build user-specific insights prompt"""
        profile = user.profile
        
        prompt = f"""Analyze this week's progress and provide insights:

USER PROFILE:
- Goal: {profile.primary_goal if profile else 'general health'}
- Current Weight: {progress_entries[0].current_weight if progress_entries and progress_entries[0].current_weight else 'N/A'} kg
- Target Weight: {profile.target_weight if profile else 'N/A'} kg

WEEKLY PROGRESS DATA:
"""
        
        for entry in progress_entries:
            prompt += f"""
- Date: {entry.date.strftime('%Y-%m-%d')}
  Weight: {entry.current_weight or 'N/A'} kg
  Calories Consumed: {entry.calories_consumed or 0}
  Workouts Completed: {entry.workouts_completed or 0}
  Notes: {entry.notes or 'None'}
"""
        
        if not progress_entries:
            prompt += "No progress entries recorded this week.\n"
            
        prompt += """
Generate 3-5 key insights and recommendations based on this data.
Focus on actionable advice and celebrating wins."""
        
        return prompt
