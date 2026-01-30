"""Workout session API routes for set-level tracking"""

from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, desc, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.dependencies import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.models.workout_session import WorkoutSession, ExerciseSet, PersonalRecord
from app.schemas.workout_session import (
    WorkoutSessionResponse,
    WorkoutSessionSummary,
    ExerciseSetResponse,
    PersonalRecordResponse,
    ExerciseHistory,
    ExerciseHistoryEntry,
    StartWorkoutRequest,
    LogSetRequest,
    CompleteWorkoutRequest,
    BatchSyncWorkoutRequest,
    BatchSyncWorkoutResponse,
)
from app.api.routes.gamification import update_streak_on_workout

router = APIRouter()


@router.post("/start", response_model=WorkoutSessionResponse)
async def start_workout_session(
    request: StartWorkoutRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Start a new workout session"""
    # Check if user already has an active session - if so, abandon it silently
    result = await db.execute(
        select(WorkoutSession).where(
            and_(
                WorkoutSession.user_id == current_user.id,
                WorkoutSession.status == "active"
            )
        )
    )
    existing_session = result.scalar_one_or_none()

    if existing_session:
        # Automatically abandon the old session
        existing_session.status = "abandoned"
        existing_session.completed_at = datetime.utcnow()

    # Create new session
    session = WorkoutSession(
        user_id=current_user.id,
        workout_id=request.workout_id,
        workout_name=request.workout_name,
        status="active"
    )

    db.add(session)
    await db.commit()

    # Re-query with selectinload to eagerly load the sets relationship
    # This is necessary because lazy loading fails in async context
    result = await db.execute(
        select(WorkoutSession)
        .options(selectinload(WorkoutSession.sets))
        .where(WorkoutSession.id == session.id)
    )
    session = result.scalar_one()

    return session


@router.get("/active", response_model=Optional[WorkoutSessionResponse])
async def get_active_session(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get the current active workout session if any"""
    result = await db.execute(
        select(WorkoutSession)
        .options(selectinload(WorkoutSession.sets))
        .where(
            and_(
                WorkoutSession.user_id == current_user.id,
                WorkoutSession.status == "active"
            )
        )
    )
    session = result.scalar_one_or_none()
    return session


@router.post("/{session_id}/sets", response_model=ExerciseSetResponse)
async def log_set(
    session_id: UUID,
    request: LogSetRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Log a single set in the workout session"""
    # Get session
    result = await db.execute(
        select(WorkoutSession).where(WorkoutSession.id == session_id)
    )
    session = result.scalar_one_or_none()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Workout session not found"
        )

    if session.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to modify this session"
        )

    if session.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot log sets to a completed or abandoned session"
        )

    # Check if this is a PR
    is_pr = await _check_if_pr(
        db,
        current_user.id,
        request.exercise_name,
        request.weight_kg,
        request.reps
    )

    # Create the set
    exercise_set = ExerciseSet(
        session_id=session_id,
        exercise_id=request.exercise_id,
        exercise_name=request.exercise_name,
        set_number=request.set_number,
        weight_kg=request.weight_kg,
        reps=request.reps,
        is_warmup=request.is_warmup,
        is_pr=is_pr and not request.is_warmup,
        rest_seconds=request.rest_seconds,
        notes=request.notes
    )

    db.add(exercise_set)

    # Update session volume
    if not request.is_warmup:
        set_volume = int(request.weight_kg * request.reps)
        session.total_volume += set_volume

    await db.commit()
    await db.refresh(exercise_set)

    # If it's a PR, record it
    if is_pr and not request.is_warmup:
        await _record_pr(
            db,
            current_user.id,
            request.exercise_name,
            request.weight_kg,
            request.reps,
            session_id
        )

    return exercise_set


@router.put("/{session_id}/complete", response_model=WorkoutSessionSummary)
async def complete_workout(
    session_id: UUID,
    request: CompleteWorkoutRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Complete a workout session"""
    # Get session with sets
    result = await db.execute(
        select(WorkoutSession)
        .options(selectinload(WorkoutSession.sets))
        .where(WorkoutSession.id == session_id)
    )
    session = result.scalar_one_or_none()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Workout session not found"
        )

    if session.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to modify this session"
        )

    if session.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session is not active"
        )

    # Update session
    now = datetime.utcnow()
    session.completed_at = now
    session.status = "completed"
    session.duration_seconds = int((now - session.started_at).total_seconds())

    if request.notes:
        session.notes = request.notes

    # Update streak and check for achievements
    workout_minutes = session.duration_seconds // 60
    streak, new_achievements = await update_streak_on_workout(
        db, current_user.id, workout_minutes
    )

    await db.commit()

    # Get PRs from this session
    new_prs = [
        {"exercise": s.exercise_name, "weight_kg": float(s.weight_kg), "reps": s.reps}
        for s in session.sets if s.is_pr
    ]

    # Count unique exercises
    unique_exercises = len(set(s.exercise_name for s in session.sets if not s.is_warmup))

    return WorkoutSessionSummary(
        id=session.id,
        workout_name=session.workout_name,
        started_at=session.started_at,
        completed_at=session.completed_at,
        duration_seconds=session.duration_seconds,
        total_volume=session.total_volume,
        total_sets=len([s for s in session.sets if not s.is_warmup]),
        exercises_completed=unique_exercises,
        new_prs=new_prs
    )


@router.post("/batch-sync", response_model=BatchSyncWorkoutResponse)
async def batch_sync_workout(
    request: BatchSyncWorkoutRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Batch sync entire workout session with all sets in one API call.
    This is the local-first endpoint that accepts complete workout data from device.
    """
    from uuid import UUID as PyUUID

    session_data = request.session
    sets_data = request.sets

    # Convert string UUID to Python UUID
    session_id = PyUUID(session_data.id)

    # Check if session already exists
    result = await db.execute(
        select(WorkoutSession).where(WorkoutSession.id == session_id)
    )
    session = result.scalar_one_or_none()

    if session:
        # Update existing session
        if session.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to modify this session"
            )

        # Update session fields
        session.workout_id = session_data.workout_id
        session.workout_name = session_data.workout_name
        session.started_at = session_data.started_at
        session.completed_at = session_data.completed_at
        session.status = session_data.status
        session.total_volume = session_data.total_volume
        session.duration_seconds = session_data.duration_seconds
        session.notes = session_data.notes
    else:
        # Create new session
        session = WorkoutSession(
            id=session_id,
            user_id=current_user.id,
            workout_id=session_data.workout_id,
            workout_name=session_data.workout_name,
            started_at=session_data.started_at,
            completed_at=session_data.completed_at,
            status=session_data.status,
            total_volume=session_data.total_volume,
            duration_seconds=session_data.duration_seconds,
            notes=session_data.notes
        )
        db.add(session)

    # Process all sets
    prs = []
    for set_data in sets_data:
        set_id = PyUUID(set_data.id)

        # Check if set already exists
        set_result = await db.execute(
            select(ExerciseSet).where(ExerciseSet.id == set_id)
        )
        existing_set = set_result.scalar_one_or_none()

        if existing_set:
            # Update existing set
            existing_set.exercise_id = set_data.exercise_id
            existing_set.exercise_name = set_data.exercise_name
            existing_set.set_number = set_data.set_number
            existing_set.weight_kg = set_data.weight_kg
            existing_set.reps = set_data.reps
            existing_set.is_warmup = set_data.is_warmup
            existing_set.rest_seconds = set_data.rest_seconds
            existing_set.completed_at = set_data.completed_at
            existing_set.notes = set_data.notes
            exercise_set = existing_set
        else:
            # Create new set
            exercise_set = ExerciseSet(
                id=set_id,
                session_id=session_id,
                exercise_id=set_data.exercise_id,
                exercise_name=set_data.exercise_name,
                set_number=set_data.set_number,
                weight_kg=set_data.weight_kg,
                reps=set_data.reps,
                is_warmup=set_data.is_warmup,
                rest_seconds=set_data.rest_seconds,
                completed_at=set_data.completed_at,
                notes=set_data.notes
            )
            db.add(exercise_set)

        # Check for personal record (only for non-warmup sets)
        if not set_data.is_warmup:
            is_pr = await _check_if_pr(
                db,
                current_user.id,
                set_data.exercise_name,
                set_data.weight_kg,
                set_data.reps
            )

            if is_pr:
                exercise_set.is_pr = True
                prs.append({
                    "exercise": set_data.exercise_name,
                    "weight_kg": float(set_data.weight_kg),
                    "reps": set_data.reps,
                    "set_id": str(set_id)
                })

    # Commit all changes
    await db.commit()

    # Record all PRs in the PersonalRecord table
    for set_data in sets_data:
        if not set_data.is_warmup:
            is_pr = await _check_if_pr(
                db,
                current_user.id,
                set_data.exercise_name,
                set_data.weight_kg,
                set_data.reps
            )
            if is_pr:
                await _record_pr(
                    db,
                    current_user.id,
                    set_data.exercise_name,
                    set_data.weight_kg,
                    set_data.reps,
                    session_id
                )

    # Update streak and check achievements if workout is completed
    achievements = []
    if session_data.status == "completed" and session_data.completed_at:
        workout_minutes = session_data.duration_seconds // 60
        streak, new_achievements = await update_streak_on_workout(
            db,
            current_user.id,  # Fixed: pass user_id not user object
            workout_minutes    # Fixed: pass duration in minutes, not completed_at datetime
        )
        achievements = [
            {"name": ach.name, "description": ach.description, "points": ach.points}
            for ach in new_achievements
        ]

    await db.commit()  # Commit streak and achievement updates

    return BatchSyncWorkoutResponse(
        session_id=session_id,
        prs=prs,
        achievements=achievements,
        synced_at=datetime.now()
    )


@router.delete("/{session_id}")
async def abandon_workout(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Abandon a workout session"""
    result = await db.execute(
        select(WorkoutSession).where(WorkoutSession.id == session_id)
    )
    session = result.scalar_one_or_none()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Workout session not found"
        )

    if session.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to modify this session"
        )

    if session.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session is not active"
        )

    session.status = "abandoned"
    session.completed_at = datetime.utcnow()

    await db.commit()

    return {"message": "Workout session abandoned"}


@router.get("/history", response_model=List[WorkoutSessionResponse])
async def get_workout_history(
    limit: int = 20,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get past workout sessions"""
    result = await db.execute(
        select(WorkoutSession)
        .options(selectinload(WorkoutSession.sets))
        .where(
            and_(
                WorkoutSession.user_id == current_user.id,
                WorkoutSession.status == "completed"
            )
        )
        .order_by(desc(WorkoutSession.completed_at))
        .limit(limit)
        .offset(offset)
    )
    sessions = result.scalars().all()
    return sessions


@router.get("/exercises/{exercise_name}/history", response_model=ExerciseHistory)
async def get_exercise_history(
    exercise_name: str,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get history for a specific exercise"""
    # Normalize exercise name for matching
    normalized_name = exercise_name.lower().strip()

    result = await db.execute(
        select(ExerciseSet)
        .join(WorkoutSession)
        .where(
            and_(
                WorkoutSession.user_id == current_user.id,
                WorkoutSession.status == "completed",
                ExerciseSet.is_warmup == False,
                ExerciseSet.exercise_name.ilike(f"%{normalized_name}%")
            )
        )
        .order_by(desc(ExerciseSet.completed_at))
        .limit(limit)
    )
    sets = result.scalars().all()

    if not sets:
        return ExerciseHistory(
            exercise_name=exercise_name,
            entries=[],
            best_weight=None,
            best_volume=None
        )

    entries = [
        ExerciseHistoryEntry(
            date=s.completed_at,
            weight_kg=s.weight_kg,
            reps=s.reps,
            is_pr=s.is_pr
        )
        for s in sets
    ]

    best_weight = max(s.weight_kg for s in sets)
    best_volume = max(s.weight_kg * s.reps for s in sets)

    return ExerciseHistory(
        exercise_name=exercise_name,
        entries=entries,
        best_weight=best_weight,
        best_volume=best_volume
    )


@router.get("/personal-records", response_model=List[PersonalRecordResponse])
async def get_personal_records(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all personal records for the user"""
    result = await db.execute(
        select(PersonalRecord)
        .where(PersonalRecord.user_id == current_user.id)
        .order_by(desc(PersonalRecord.achieved_at))
    )
    records = result.scalars().all()
    return records


async def _check_if_pr(
    db: AsyncSession,
    user_id: UUID,
    exercise_name: str,
    weight_kg: Decimal,
    reps: int
) -> bool:
    """Check if this set is a personal record for weight"""
    # Get the current best weight for this exercise
    result = await db.execute(
        select(PersonalRecord)
        .where(
            and_(
                PersonalRecord.user_id == user_id,
                PersonalRecord.exercise_name.ilike(exercise_name),
                PersonalRecord.record_type == "weight"
            )
        )
    )
    current_record = result.scalar_one_or_none()

    if not current_record:
        return True  # First time doing this exercise

    return weight_kg > current_record.value


async def _record_pr(
    db: AsyncSession,
    user_id: UUID,
    exercise_name: str,
    weight_kg: Decimal,
    reps: int,
    session_id: UUID
):
    """Record a new personal record"""
    # Update or create weight PR
    result = await db.execute(
        select(PersonalRecord)
        .where(
            and_(
                PersonalRecord.user_id == user_id,
                PersonalRecord.exercise_name.ilike(exercise_name),
                PersonalRecord.record_type == "weight"
            )
        )
    )
    existing = result.scalar_one_or_none()

    if existing:
        existing.value = weight_kg
        existing.reps = reps
        existing.achieved_at = datetime.utcnow()
        existing.session_id = session_id
    else:
        pr = PersonalRecord(
            user_id=user_id,
            exercise_name=exercise_name,
            record_type="weight",
            value=weight_kg,
            reps=reps,
            session_id=session_id
        )
        db.add(pr)

    await db.commit()
