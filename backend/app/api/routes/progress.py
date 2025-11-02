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
    
    return entries


@router.post("", response_model=ProgressEntryResponse)
async def log_progress(
    progress_data: ProgressEntryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Log a new progress entry"""
    # Check if entry already exists for today
    entry_date = progress_data.entry_date or datetime.now().date()
    result = await db.execute(
        select(ProgressEntry).where(
            ProgressEntry.user_id == current_user.id,
            ProgressEntry.entry_date == entry_date
        )
    )
    existing_entry = result.scalar_one_or_none()
    
    if existing_entry:
        # Update existing entry
        update_data = progress_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            if field == "entry_date" and value is not None:
                existing_entry.entry_date = value
            elif field == "weight" and value is not None:
                existing_entry.weight = value
            elif field == "body_fat_percentage" and value is not None:
                existing_entry.body_fat_percentage = value
            elif field == "muscle_mass" and value is not None:
                existing_entry.muscle_mass = value
            elif field == "measurements" and value is not None:
                existing_entry.measurements = value
            elif field == "mood_score" and value is not None:
                existing_entry.mood_score = value
            elif field == "energy_score" and value is not None:
                existing_entry.energy_score = value
            elif field == "stress_score" and value is not None:
                existing_entry.stress_score = value
            elif field == "sleep_hours" and value is not None:
                existing_entry.sleep_hours = value
            elif field == "sleep_quality" and value is not None:
                existing_entry.sleep_quality = value
            elif field == "water_intake_ml" and value is not None:
                existing_entry.water_intake_ml = value
            elif field == "adherence_score" and value is not None:
                existing_entry.adherence_score = value
            elif field == "notes" and value is not None:
                existing_entry.notes = value
            elif field == "photos" and value is not None:
                existing_entry.photos = value
        
        entry = existing_entry
    else:
        # Create new entry
        entry = ProgressEntry(
            user_id=current_user.id,
            entry_date=entry_date,
            weight=progress_data.weight,
            body_fat_percentage=progress_data.body_fat_percentage,
            muscle_mass=progress_data.muscle_mass,
            measurements=progress_data.measurements,
            mood_score=progress_data.mood_score,
            energy_score=progress_data.energy_score,
            stress_score=progress_data.stress_score,
            sleep_hours=progress_data.sleep_hours,
            sleep_quality=progress_data.sleep_quality,
            water_intake_ml=progress_data.water_intake_ml,
            adherence_score=progress_data.adherence_score,
            notes=progress_data.notes,
            photos=progress_data.photos,
        )
        db.add(entry)
    
    await db.commit()
    await db.refresh(entry)
    
    return entry
