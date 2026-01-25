"""add_workout_session_tables

Revision ID: b5c6d7e8f9a0
Revises: a3b4c5d6e7f8
Create Date: 2026-01-24 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b5c6d7e8f9a0'
down_revision: Union[str, Sequence[str], None] = 'a3b4c5d6e7f8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create workout_sessions table
    op.create_table(
        'workout_sessions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('workout_id', sa.UUID(), nullable=True),
        sa.Column('workout_name', sa.String(length=255), nullable=False),
        sa.Column('started_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='active'),
        sa.Column('total_volume', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('duration_seconds', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['workout_id'], ['workouts.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_workout_sessions_user_id'), 'workout_sessions', ['user_id'])
    op.create_index(op.f('ix_workout_sessions_status'), 'workout_sessions', ['status'])

    # Create exercise_sets table
    op.create_table(
        'exercise_sets',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('session_id', sa.UUID(), nullable=False),
        sa.Column('exercise_id', sa.UUID(), nullable=True),
        sa.Column('exercise_name', sa.String(length=255), nullable=False),
        sa.Column('set_number', sa.Integer(), nullable=False),
        sa.Column('weight_kg', sa.DECIMAL(precision=6, scale=2), nullable=False, server_default='0'),
        sa.Column('reps', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_warmup', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('is_pr', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('rest_seconds', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('completed_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(['session_id'], ['workout_sessions.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['exercise_id'], ['exercises.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_exercise_sets_session_id'), 'exercise_sets', ['session_id'])
    op.create_index(op.f('ix_exercise_sets_exercise_name'), 'exercise_sets', ['exercise_name'])

    # Create personal_records table
    op.create_table(
        'personal_records',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('exercise_name', sa.String(length=255), nullable=False),
        sa.Column('record_type', sa.String(length=20), nullable=False),
        sa.Column('value', sa.DECIMAL(precision=10, scale=2), nullable=False),
        sa.Column('weight_kg', sa.DECIMAL(precision=6, scale=2), nullable=True),
        sa.Column('reps', sa.Integer(), nullable=True),
        sa.Column('achieved_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('session_id', sa.UUID(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['session_id'], ['workout_sessions.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_personal_records_user_id'), 'personal_records', ['user_id'])
    op.create_index(op.f('ix_personal_records_exercise_name'), 'personal_records', ['exercise_name'])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_personal_records_exercise_name'), table_name='personal_records')
    op.drop_index(op.f('ix_personal_records_user_id'), table_name='personal_records')
    op.drop_table('personal_records')

    op.drop_index(op.f('ix_exercise_sets_exercise_name'), table_name='exercise_sets')
    op.drop_index(op.f('ix_exercise_sets_session_id'), table_name='exercise_sets')
    op.drop_table('exercise_sets')

    op.drop_index(op.f('ix_workout_sessions_status'), table_name='workout_sessions')
    op.drop_index(op.f('ix_workout_sessions_user_id'), table_name='workout_sessions')
    op.drop_table('workout_sessions')
