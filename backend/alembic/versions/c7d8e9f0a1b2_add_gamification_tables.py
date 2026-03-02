"""add_gamification_tables

Revision ID: c7d8e9f0a1b2
Revises: b5c6d7e8f9a0
Create Date: 2026-01-25 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'c7d8e9f0a1b2'
down_revision: Union[str, Sequence[str], None] = 'b5c6d7e8f9a0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# Default achievements to seed
DEFAULT_ACHIEVEMENTS = [
    ("first_workout", "First Steps", "Complete your first workout", "🎯", "workout", "workout_count", 1, 10, "common", 1),
    ("workout_10", "Getting Serious", "Complete 10 workouts", "💪", "workout", "workout_count", 10, 25, "common", 2),
    ("workout_50", "Dedicated", "Complete 50 workouts", "🏋️", "workout", "workout_count", 50, 50, "rare", 3),
    ("workout_100", "Century Club", "Complete 100 workouts", "💯", "workout", "workout_count", 100, 100, "epic", 4),
    ("streak_3", "On a Roll", "Maintain a 3-day workout streak", "🔥", "streak", "streak", 3, 15, "common", 10),
    ("streak_7", "Week Warrior", "Maintain a 7-day workout streak", "🔥", "streak", "streak", 7, 30, "rare", 11),
    ("streak_14", "Two Week Terror", "Maintain a 14-day workout streak", "🔥", "streak", "streak", 14, 50, "rare", 12),
    ("streak_30", "Monthly Machine", "Maintain a 30-day workout streak", "🏆", "streak", "streak", 30, 100, "epic", 13),
    ("streak_100", "Unstoppable", "Maintain a 100-day workout streak", "👑", "streak", "streak", 100, 500, "legendary", 14),
    ("first_pr", "Personal Best", "Set your first personal record", "⭐", "progress", "pr_count", 1, 15, "common", 20),
    ("pr_10", "Record Breaker", "Set 10 personal records", "🌟", "progress", "pr_count", 10, 40, "rare", 21),
    ("pr_50", "Champion", "Set 50 personal records", "🏅", "progress", "pr_count", 50, 100, "epic", 22),
    ("volume_10k", "Heavy Lifter", "Lift a total of 10,000 kg", "🪨", "progress", "total_volume", 10000, 25, "common", 30),
    ("volume_100k", "Iron Will", "Lift a total of 100,000 kg", "⚔️", "progress", "total_volume", 100000, 75, "rare", 31),
    ("volume_1m", "Legendary Strength", "Lift a total of 1,000,000 kg", "🦁", "progress", "total_volume", 1000000, 250, "legendary", 32),
    ("perfect_week", "Perfect Week", "Work out every day for a week", "📅", "streak", "perfect_week", 1, 50, "rare", 40),
]


def upgrade() -> None:
    """Upgrade schema."""
    # Create user_streaks table
    op.create_table(
        'user_streaks',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('current_streak', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('longest_streak', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('last_workout_date', sa.Date(), nullable=True),
        sa.Column('streak_start_date', sa.Date(), nullable=True),
        sa.Column('current_week_workouts', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('week_start_date', sa.Date(), nullable=True),
        sa.Column('total_workouts', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('total_workout_minutes', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_user_streaks_user_id', 'user_streaks', ['user_id'], unique=True)

    # Create achievements table
    op.create_table(
        'achievements',
        sa.Column('id', sa.String(50), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('icon', sa.String(50), nullable=False),
        sa.Column('category', sa.String(50), nullable=False),
        sa.Column('requirement_type', sa.String(50), nullable=False),
        sa.Column('requirement_value', sa.Integer(), nullable=False),
        sa.Column('points', sa.Integer(), nullable=False, server_default='10'),
        sa.Column('rarity', sa.String(20), nullable=False, server_default="'common'"),
        sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.PrimaryKeyConstraint('id')
    )

    # Create user_achievements table
    op.create_table(
        'user_achievements',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('achievement_id', sa.String(50), nullable=False),
        sa.Column('earned_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('context', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('notified', sa.Boolean(), nullable=False, server_default='false'),
        sa.ForeignKeyConstraint(['achievement_id'], ['achievements.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_user_achievements_user_id', 'user_achievements', ['user_id'], unique=False)
    op.create_index('ix_user_achievements_achievement_id', 'user_achievements', ['achievement_id'], unique=False)
    # Unique constraint: each user can earn each achievement only once
    op.create_unique_constraint('uq_user_achievement', 'user_achievements', ['user_id', 'achievement_id'])

    # Seed default achievements
    achievements_table = sa.table(
        'achievements',
        sa.column('id', sa.String),
        sa.column('name', sa.String),
        sa.column('description', sa.Text),
        sa.column('icon', sa.String),
        sa.column('category', sa.String),
        sa.column('requirement_type', sa.String),
        sa.column('requirement_value', sa.Integer),
        sa.column('points', sa.Integer),
        sa.column('rarity', sa.String),
        sa.column('sort_order', sa.Integer),
    )

    op.bulk_insert(achievements_table, [
        {
            'id': a[0],
            'name': a[1],
            'description': a[2],
            'icon': a[3],
            'category': a[4],
            'requirement_type': a[5],
            'requirement_value': a[6],
            'points': a[7],
            'rarity': a[8],
            'sort_order': a[9],
        }
        for a in DEFAULT_ACHIEVEMENTS
    ])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('user_achievements')
    op.drop_table('achievements')
    op.drop_table('user_streaks')
