"""Add performance indexes for workout queries

Revision ID: a2dc7488002c
Revises: c28b4abf6b77
Create Date: 2026-01-26 23:29:17.392574

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a2dc7488002c'
down_revision: Union[str, Sequence[str], None] = 'c28b4abf6b77'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add performance indexes for workout queries."""
    # Index for filtering workout sessions by status (doesn't exist in model)
    op.create_index('ix_workout_sessions_status', 'workout_sessions', ['status'])
    
    # Composite index for user achievements queries
    op.create_index('ix_user_achievements_user_notified', 'user_achievements', ['user_id', 'notified'])
    
    # Note: exercise_name index already exists in model (index=True on line 79)
    # Note: user_id indexes already exist in models (index=True)



def downgrade() -> None:
    """Remove performance indexes."""
    op.drop_index('ix_user_achievements_user_notified', 'user_achievements')
    op.drop_index('ix_workout_sessions_status', 'workout_sessions')
