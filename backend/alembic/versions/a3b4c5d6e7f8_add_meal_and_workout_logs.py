"""add_meal_and_workout_logs

Revision ID: a3b4c5d6e7f8
Revises: de151ea0af79
Create Date: 2026-01-21 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'a3b4c5d6e7f8'
down_revision: Union[str, Sequence[str], None] = 'de151ea0af79'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create meal_logs table
    op.create_table(
        'meal_logs',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('meal_id', sa.UUID(), nullable=True),
        sa.Column('meal_date', sa.Date(), nullable=False),
        sa.Column('meal_type', sa.String(length=50), nullable=False),
        sa.Column('custom_meal_name', sa.String(length=255), nullable=True),
        sa.Column('custom_foods', postgresql.JSONB(), nullable=True),
        sa.Column('calories', sa.Integer(), nullable=True),
        sa.Column('protein_grams', sa.DECIMAL(precision=5, scale=2), nullable=True),
        sa.Column('carbs_grams', sa.DECIMAL(precision=5, scale=2), nullable=True),
        sa.Column('fat_grams', sa.DECIMAL(precision=5, scale=2), nullable=True),
        sa.Column('satisfaction_rating', sa.Integer(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('log_method', sa.String(length=50), nullable=True),
        sa.Column('logged_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['meal_id'], ['meals.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_meal_logs_user_id'), 'meal_logs', ['user_id'])
    op.create_index(op.f('ix_meal_logs_meal_date'), 'meal_logs', ['meal_date'])

    # Create workout_logs table
    op.create_table(
        'workout_logs',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('workout_id', sa.UUID(), nullable=True),
        sa.Column('workout_date', sa.Date(), nullable=False),
        sa.Column('custom_workout_name', sa.String(length=255), nullable=True),
        sa.Column('duration_minutes', sa.Integer(), nullable=True),
        sa.Column('calories_burned', sa.Integer(), nullable=True),
        sa.Column('exercises_completed', postgresql.JSONB(), nullable=True),
        sa.Column('difficulty_rating', sa.Integer(), nullable=True),
        sa.Column('energy_level', sa.Integer(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('completed_fully', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('logged_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['workout_id'], ['workouts.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_workout_logs_user_id'), 'workout_logs', ['user_id'])
    op.create_index(op.f('ix_workout_logs_workout_date'), 'workout_logs', ['workout_date'])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_workout_logs_workout_date'), table_name='workout_logs')
    op.drop_index(op.f('ix_workout_logs_user_id'), table_name='workout_logs')
    op.drop_table('workout_logs')

    op.drop_index(op.f('ix_meal_logs_meal_date'), table_name='meal_logs')
    op.drop_index(op.f('ix_meal_logs_user_id'), table_name='meal_logs')
    op.drop_table('meal_logs')
