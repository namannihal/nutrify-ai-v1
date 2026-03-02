"""Background generation service for AI plans with SSE support"""

import asyncio
import uuid
from datetime import datetime
from typing import Optional, Dict, Any, AsyncGenerator
from enum import Enum
from dataclasses import dataclass, field
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


class GenerationStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"


class GenerationType(str, Enum):
    NUTRITION = "nutrition"
    FITNESS = "fitness"


@dataclass
class GenerationTask:
    id: str
    user_id: str
    generation_type: GenerationType
    status: GenerationStatus
    progress: int = 0
    message: str = ""
    result_id: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)


class GenerationService:
    """Service for managing background AI plan generation"""

    # In-memory storage for generation tasks (for MVP)
    # In production, use Redis or a database
    _tasks: Dict[str, GenerationTask] = {}
    _user_tasks: Dict[str, str] = {}  # user_id -> latest task_id mapping

    @classmethod
    def create_task(cls, user_id: str, generation_type: GenerationType) -> GenerationTask:
        """Create a new generation task"""
        task_id = str(uuid.uuid4())
        task = GenerationTask(
            id=task_id,
            user_id=user_id,
            generation_type=generation_type,
            status=GenerationStatus.PENDING,
            message="Task created, waiting to start..."
        )
        cls._tasks[task_id] = task
        cls._user_tasks[f"{user_id}:{generation_type.value}"] = task_id
        return task

    @classmethod
    def get_task(cls, task_id: str) -> Optional[GenerationTask]:
        """Get a generation task by ID"""
        return cls._tasks.get(task_id)

    @classmethod
    def get_user_task(cls, user_id: str, generation_type: GenerationType) -> Optional[GenerationTask]:
        """Get the latest task for a user and generation type"""
        task_id = cls._user_tasks.get(f"{user_id}:{generation_type.value}")
        if task_id:
            return cls._tasks.get(task_id)
        return None

    @classmethod
    def update_task(
        cls,
        task_id: str,
        status: Optional[GenerationStatus] = None,
        progress: Optional[int] = None,
        message: Optional[str] = None,
        result_id: Optional[str] = None,
        error: Optional[str] = None
    ) -> Optional[GenerationTask]:
        """Update a generation task"""
        task = cls._tasks.get(task_id)
        if not task:
            return None

        if status is not None:
            task.status = status
        if progress is not None:
            task.progress = progress
        if message is not None:
            task.message = message
        if result_id is not None:
            task.result_id = result_id
        if error is not None:
            task.error = error
        task.updated_at = datetime.utcnow()

        return task

    @classmethod
    def delete_task(cls, task_id: str) -> bool:
        """Delete a generation task"""
        task = cls._tasks.pop(task_id, None)
        if task:
            key = f"{task.user_id}:{task.generation_type.value}"
            if cls._user_tasks.get(key) == task_id:
                del cls._user_tasks[key]
            return True
        return False

    @classmethod
    def cleanup_old_tasks(cls, max_age_hours: int = 24) -> int:
        """Clean up tasks older than max_age_hours"""
        now = datetime.utcnow()
        old_task_ids = [
            task_id for task_id, task in cls._tasks.items()
            if (now - task.created_at).total_seconds() > max_age_hours * 3600
        ]
        for task_id in old_task_ids:
            cls.delete_task(task_id)
        return len(old_task_ids)

    @classmethod
    async def run_nutrition_generation(
        cls,
        task_id: str,
        user: User,
        db: AsyncSession
    ) -> None:
        """Run nutrition plan generation in background"""
        from app.ai.nutrition_agent import NutritionAgent

        try:
            cls.update_task(
                task_id,
                status=GenerationStatus.IN_PROGRESS,
                progress=0,
                message="Starting nutrition plan generation..."
            )

            # Initialize AI agent
            agent = NutritionAgent(db)

            # Update progress - analyzing user data
            cls.update_task(task_id, progress=10, message="Analyzing your profile and preferences...")
            await asyncio.sleep(0.5)  # Small delay for UX

            # Update progress - generating meals
            cls.update_task(task_id, progress=30, message="Generating meal recommendations...")

            # Generate plan
            plan = await agent.generate_weekly_plan(user)
            await db.flush()

            # Update progress - finalizing
            cls.update_task(task_id, progress=90, message="Finalizing your nutrition plan...")
            await asyncio.sleep(0.3)

            # Complete
            cls.update_task(
                task_id,
                status=GenerationStatus.COMPLETED,
                progress=100,
                message="Your nutrition plan is ready!",
                result_id=str(plan.id)
            )

        except Exception as e:
            cls.update_task(
                task_id,
                status=GenerationStatus.FAILED,
                error=str(e),
                message=f"Failed to generate plan: {str(e)}"
            )
            await db.rollback()

    @classmethod
    async def run_fitness_generation(
        cls,
        task_id: str,
        user: User,
        db: AsyncSession
    ) -> None:
        """Run fitness plan generation in background"""
        from app.ai.fitness_agent import FitnessAgent

        try:
            cls.update_task(
                task_id,
                status=GenerationStatus.IN_PROGRESS,
                progress=0,
                message="Starting workout plan generation..."
            )

            # Initialize AI agent
            agent = FitnessAgent(db)

            # Update progress - analyzing user data
            cls.update_task(task_id, progress=10, message="Analyzing your fitness level and goals...")
            await asyncio.sleep(0.5)

            # Update progress - generating workouts
            cls.update_task(task_id, progress=30, message="Creating personalized workouts...")

            # Generate plan
            plan = await agent.generate_weekly_plan(user)
            await db.flush()

            # Update progress - finalizing
            cls.update_task(task_id, progress=90, message="Finalizing your workout plan...")
            await asyncio.sleep(0.3)

            # Complete
            cls.update_task(
                task_id,
                status=GenerationStatus.COMPLETED,
                progress=100,
                message="Your workout plan is ready!",
                result_id=str(plan.id)
            )

        except Exception as e:
            cls.update_task(
                task_id,
                status=GenerationStatus.FAILED,
                error=str(e),
                message=f"Failed to generate plan: {str(e)}"
            )
            await db.rollback()

    @classmethod
    async def stream_task_status(cls, task_id: str) -> AsyncGenerator[str, None]:
        """Stream task status updates as SSE events"""
        while True:
            task = cls.get_task(task_id)
            if not task:
                yield f"event: error\ndata: {{\"error\": \"Task not found\"}}\n\n"
                break

            # Send current status
            data = {
                "id": task.id,
                "status": task.status.value,
                "progress": task.progress,
                "message": task.message,
            }

            if task.result_id:
                data["result_id"] = task.result_id
            if task.error:
                data["error"] = task.error

            import json
            yield f"event: status\ndata: {json.dumps(data)}\n\n"

            # If task is complete or failed, send final event and stop
            if task.status in (GenerationStatus.COMPLETED, GenerationStatus.FAILED):
                yield f"event: done\ndata: {json.dumps(data)}\n\n"
                break

            # Wait before next update
            await asyncio.sleep(1)
