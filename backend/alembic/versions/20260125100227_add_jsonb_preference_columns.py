"""Add JSONB preference columns to user_profiles

Revision ID: 20260125100227
Revises: de151ea0af79
Create Date: 2026-01-25 10:02:27

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '20260125100227'
down_revision: Union[str, None] = 'c7d8e9f0a1b2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add JSONB columns for detailed preferences from questionnaires
    op.add_column('user_profiles', sa.Column('unit_preferences', postgresql.JSONB(astext_type=sa.Text()), nullable=True))
    op.add_column('user_profiles', sa.Column('fitness_preferences', postgresql.JSONB(astext_type=sa.Text()), nullable=True))
    op.add_column('user_profiles', sa.Column('nutrition_preferences', postgresql.JSONB(astext_type=sa.Text()), nullable=True))


def downgrade() -> None:
    op.drop_column('user_profiles', 'nutrition_preferences')
    op.drop_column('user_profiles', 'fitness_preferences')
    op.drop_column('user_profiles', 'unit_preferences')
