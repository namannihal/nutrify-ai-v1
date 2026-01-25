"""
Hierarchical Memory System for Nutrify-AI
Implements three-tier memory architecture for efficient context management

Based on research: "Leave No Context Behind" (Infini-attention, 2024)
- Working Memory: Immediate context (always loaded)
- Episodic Memory: Retrievable behavioral patterns (RAG)
- Semantic Memory: Compressed long-term knowledge
"""

from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
import json

from app.models.user import User, UserProfile
from app.models.progress import ProgressEntry
from app.models.nutrition import NutritionPlan
from app.models.fitness import FitnessPlan


class HierarchicalMemory:
    """
    Three-tier memory system for AI agent context management
    Optimizes token usage while maintaining personalization
    """
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.working_memory_cache = {}  # In-memory cache for active sessions
        
    async def get_user_context(
        self,
        user_id: str,
        context_type: str = "general"
    ) -> Dict[str, Any]:
        """
        Retrieve hierarchical user context for AI agents
        
        Args:
            user_id: User UUID
            context_type: Type of context needed (nutrition_planning, fitness_planning, coaching, insights)
            
        Returns:
            Dictionary with relevant context
        """
        # Tier 1: Working Memory (always loaded)
        working_memory = await self._get_working_memory(user_id)
        
        # Tier 2: Episodic Memory (context-specific retrieval)
        episodic_memory = await self._get_episodic_memory(user_id, context_type)
        
        # Tier 3: Semantic Memory (compressed profile)
        semantic_memory = await self._get_semantic_memory(user_id)
        
        return {
            "working_memory": working_memory,
            "episodic_memory": episodic_memory,
            "semantic_memory": semantic_memory
        }
        
    async def _get_working_memory(self, user_id: str) -> Dict[str, Any]:
        """
        Tier 1: Immediate context (last 2 hours, current state)
        Target: ~2000 tokens
        """
        # Check cache first
        if user_id in self.working_memory_cache:
            cache_entry = self.working_memory_cache[user_id]
            if datetime.utcnow() - cache_entry["cached_at"] < timedelta(minutes=10):
                return cache_entry["data"]
                
        # Recent progress entries (last 2 hours)
        two_hours_ago = datetime.utcnow() - timedelta(hours=2)
        stmt = select(ProgressEntry).where(
            and_(
                ProgressEntry.user_id == user_id,
                ProgressEntry.entry_date >= two_hours_ago
            )
        ).order_by(ProgressEntry.entry_date.desc()).limit(5)
        result = await self.db.execute(stmt)
        recent_entries = result.scalars().all()
        
        # Current user profile
        stmt = select(User).where(User.id == user_id)
        result = await self.db.execute(stmt)
        user = result.scalar_one_or_none()
        
        working_memory = {
            "current_state": {
                "timestamp": datetime.utcnow().isoformat(),
                "active_goals": user.profile.primary_goal if user and user.profile else None,
                "current_weight": float(recent_entries[0].weight) if recent_entries and recent_entries[0].weight else None
            },
            "recent_activity": [
                {
                    "date": entry.entry_date.isoformat() if hasattr(entry.entry_date, 'isoformat') else str(entry.entry_date),
                    "weight": float(entry.weight) if entry.weight else None,
                    "mood_score": entry.mood_score,
                    "energy_score": entry.energy_score,
                    "notes": entry.notes
                }
                for entry in recent_entries
            ],
            "immediate_constraints": self._get_immediate_constraints(user)
        }
        
        # Cache it
        self.working_memory_cache[user_id] = {
            "data": working_memory,
            "cached_at": datetime.utcnow()
        }
        
        return working_memory
        
    async def _get_episodic_memory(
        self,
        user_id: str,
        context_type: str
    ) -> Dict[str, Any]:
        """
        Tier 2: Retrievable behavioral patterns and history
        Target: ~3000-6000 tokens (dynamic based on relevance)
        """
        episodic = {}
        
        if context_type in ["nutrition_planning", "general"]:
            episodic["nutrition_history"] = await self._get_nutrition_episodes(user_id)
            
        if context_type in ["fitness_planning", "general"]:
            episodic["fitness_history"] = await self._get_fitness_episodes(user_id)
            
        if context_type in ["coaching", "insights", "general"]:
            episodic["progress_patterns"] = await self._get_progress_patterns(user_id)
            
        return episodic
        
    async def _get_semantic_memory(self, user_id: str) -> Dict[str, Any]:
        """
        Tier 3: Compressed long-term knowledge about user
        Target: ~1000 tokens
        """
        stmt = select(User).where(User.id == user_id)
        result = await self.db.execute(stmt)
        user = result.scalar_one_or_none()
        
        if not user or not user.profile:
            return {}
            
        profile = user.profile
        
        # Compress profile into essential patterns
        semantic = {
            "core_identity": {
                "age": profile.age,
                "gender": profile.gender,
                "primary_goal": profile.primary_goal,
                "fitness_experience": profile.fitness_experience
            },
            "preferences": {
                "dietary": profile.dietary_restrictions or [],
                "restrictions": profile.dietary_restrictions or [],
                "allergies": profile.allergies or ""
            },
            "constraints": {
                "equipment": profile.equipment_access or []
            },
            "targets": {
                "current_weight": profile.weight,
                "activity_level": profile.activity_level
            }
        }
        
        return semantic
        
    async def _get_nutrition_episodes(self, user_id: str) -> List[Dict]:
        """Retrieve nutrition-related behavioral episodes"""
        from app.models.nutrition import Meal
        from sqlalchemy import func

        # Get last 4 weeks of nutrition plans with meal counts
        four_weeks_ago = datetime.utcnow() - timedelta(weeks=4)

        # Query plans and count meals separately to avoid lazy loading
        stmt = select(
            NutritionPlan.id,
            NutritionPlan.week_start,
            NutritionPlan.daily_calories,
            NutritionPlan.protein_grams,
            NutritionPlan.carbs_grams,
            NutritionPlan.fat_grams,
            func.count(Meal.id).label('meal_count')
        ).outerjoin(
            Meal, Meal.plan_id == NutritionPlan.id
        ).where(
            and_(
                NutritionPlan.user_id == user_id,
                NutritionPlan.week_start >= four_weeks_ago
            )
        ).group_by(
            NutritionPlan.id,
            NutritionPlan.week_start,
            NutritionPlan.daily_calories,
            NutritionPlan.protein_grams,
            NutritionPlan.carbs_grams,
            NutritionPlan.fat_grams
        ).order_by(NutritionPlan.week_start.desc()).limit(4)

        result = await self.db.execute(stmt)
        plans = result.all()

        episodes = []
        for plan in plans:
            episodes.append({
                "week_start": plan.week_start.isoformat(),
                "daily_calories": plan.daily_calories,
                "macros": {
                    "protein": plan.protein_grams,
                    "carbs": plan.carbs_grams,
                    "fat": plan.fat_grams
                },
                "meal_count": plan.meal_count
            })

        return episodes
        
    async def _get_fitness_episodes(self, user_id: str) -> List[Dict]:
        """Retrieve fitness-related behavioral episodes"""
        from app.models.fitness import Workout
        from sqlalchemy import func

        # Get last 4 weeks of workout plans with workout counts
        four_weeks_ago = datetime.utcnow() - timedelta(weeks=4)

        # Query plans and count workouts separately to avoid lazy loading
        stmt = select(
            FitnessPlan.id,
            FitnessPlan.week_start,
            func.count(Workout.id).label('workout_count')
        ).outerjoin(
            Workout, Workout.plan_id == FitnessPlan.id
        ).where(
            and_(
                FitnessPlan.user_id == user_id,
                FitnessPlan.week_start >= four_weeks_ago
            )
        ).group_by(
            FitnessPlan.id,
            FitnessPlan.week_start
        ).order_by(FitnessPlan.week_start.desc()).limit(4)

        result = await self.db.execute(stmt)
        plans = result.all()

        episodes = []
        for plan in plans:
            episodes.append({
                "week_start": plan.week_start.isoformat(),
                "workout_count": plan.workout_count
            })

        return episodes
        
    async def _get_progress_patterns(self, user_id: str) -> Dict:
        """Analyze progress patterns for insights"""
        # Get last 30 days of progress
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        stmt = select(ProgressEntry).where(
            and_(
                ProgressEntry.user_id == user_id,
                ProgressEntry.entry_date >= thirty_days_ago
            )
        ).order_by(ProgressEntry.entry_date.desc())
        result = await self.db.execute(stmt)
        entries = result.scalars().all()
        
        if not entries:
            return {}

        # Calculate patterns
        # Note: workouts_completed and calories_consumed are not direct fields on ProgressEntry
        # They may be stored in measurements JSONB if needed
        total_entries_with_measurements = sum(1 for e in entries if e.measurements)

        weights = [float(e.weight) for e in entries if e.weight]
        weight_trend = "stable"
        if len(weights) >= 2:
            if weights[0] < weights[-1]:
                weight_trend = "decreasing"
            elif weights[0] > weights[-1]:
                weight_trend = "increasing"
                
        # Calculate average mood and energy scores
        mood_scores = [e.mood_score for e in entries if e.mood_score]
        energy_scores = [e.energy_score for e in entries if e.energy_score]
        avg_mood = sum(mood_scores) / len(mood_scores) if mood_scores else None
        avg_energy = sum(energy_scores) / len(energy_scores) if energy_scores else None

        return {
            "total_entries": len(entries),
            "entries_with_measurements": total_entries_with_measurements,
            "avg_mood": round(avg_mood, 1) if avg_mood else None,
            "avg_energy": round(avg_energy, 1) if avg_energy else None,
            "weight_trend": weight_trend,
            "consistency_score": round((len(entries) / 30) * 100, 1)  # Percentage of days logged
        }
        
    def _get_immediate_constraints(self, user: Optional[User]) -> Dict:
        """Get immediate constraints for planning"""
        if not user or not user.profile:
            return {}
            
        profile = user.profile
        return {
            "dietary_restrictions": profile.dietary_restrictions or [],
            "allergies": profile.allergies or ""
        }
        
    async def store_episode(
        self,
        user_id: str,
        episode_type: str,
        content: Dict[str, Any]
    ):
        """
        Store a new episodic memory (for future RAG retrieval)
        
        Args:
            user_id: User UUID
            episode_type: Type of episode (nutrition_plan_generated, workout_completed, etc.)
            content: Episode data
        """
        # For MVP, we're storing episodes as part of the existing models (NutritionPlan, FitnessPlan, ProgressEntry)
        # In production, you'd want a dedicated EpisodicMemory table with vector embeddings for RAG
        
        # Clear working memory cache for this user
        if user_id in self.working_memory_cache:
            del self.working_memory_cache[user_id]
            
        # TODO: In production, implement vector storage for semantic search
        # - Generate embedding of episode content
        # - Store in ChromaDB/Pinecone/Weaviate
        # - Enable semantic retrieval in _get_episodic_memory()
        pass
