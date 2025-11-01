from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List
from datetime import datetime, timedelta

from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.progress import ProgressEntry
from app.schemas.progress import (
    ProgressEntryResponse,
    ProgressEntryCreate,
)

router = APIRouter()


@router.get("", response_model=List[ProgressEntryResponse])
async def get_progress_history(
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user's progress history for the specified number of days"""
    start_date = datetime.now().date() - timedelta(days=days)
    
    result = await db.execute(
        select(ProgressEntry)
        .where(
            ProgressEntry.user_id == current_user.id,
            ProgressEntry.entry_date >= start_date
        )
        .order_by(desc(ProgressEntry.entry_date))
    )
    entries = result.scalars().all()
    
    return [
        {
            "id": str(entry.id),
            "user_id": str(entry.user_id),
            "date": entry.entry_date.isoformat(),
            "weight": float(entry.weight) if entry.weight else None,
            "body_fat": float(entry.body_fat_percentage) if entry.body_fat_percentage else None,
            "measurements": entry.measurements or {},
            "mood": entry.mood_rating,
            "energy": entry.energy_rating,
            "sleep_hours": float(entry.sleep_hours) if entry.sleep_hours else 0,
            "water_intake": entry.water_intake_ml or 0,
            "adherence_score": entry.adherence_score or 0,
        }
        for entry in entries
    ]


@router.post("", response_model=ProgressEntryResponse)
async def log_progress(
    progress_data: ProgressEntryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Log a new progress entry"""
    # Check if entry already exists for today
    today = datetime.now().date()
    result = await db.execute(
        select(ProgressEntry).where(
            ProgressEntry.user_id == current_user.id,
            ProgressEntry.entry_date == today
        )
    )
    existing_entry = result.scalar_one_or_none()
    
    if existing_entry:
        # Update existing entry
        update_data = progress_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            if field == "weight" and value:
                existing_entry.weight = value
            elif field == "body_fat" and value:
                existing_entry.body_fat_percentage = value
            elif field == "measurements" and value:
                existing_entry.measurements = value
            elif field == "mood" and value:
                existing_entry.mood_rating = value
            elif field == "energy" and value:
                existing_entry.energy_rating = value
            elif field == "sleep_hours" and value:
                existing_entry.sleep_hours = value
            elif field == "water_intake" and value:
                existing_entry.water_intake_ml = value
            elif field == "adherence_score" and value:
                existing_entry.adherence_score = value
        
        entry = existing_entry
    else:
        # Create new entry
        entry = ProgressEntry(
            user_id=current_user.id,
            entry_date=today,
            weight=progress_data.weight,
            body_fat_percentage=progress_data.body_fat,
            measurements=progress_data.measurements,
            mood_rating=progress_data.mood,
            energy_rating=progress_data.energy,
            sleep_hours=progress_data.sleep_hours,
            water_intake_ml=progress_data.water_intake,
            adherence_score=progress_data.adherence_score,
        )
        db.add(entry)
    
    await db.commit()
    await db.refresh(entry)
    
    return {
        "id": str(entry.id),
        "user_id": str(entry.user_id),
        "date": entry.entry_date.isoformat(),
        "weight": float(entry.weight) if entry.weight else None,
        "body_fat": float(entry.body_fat_percentage) if entry.body_fat_percentage else None,
        "measurements": entry.measurements or {},
        "mood": entry.mood_rating,
        "energy": entry.energy_rating,
        "sleep_hours": float(entry.sleep_hours) if entry.sleep_hours else 0,
        "water_intake": entry.water_intake_ml or 0,
        "adherence_score": entry.adherence_score or 0,
    }
