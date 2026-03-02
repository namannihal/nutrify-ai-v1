"""add_subscription_and_payment_tables

Revision ID: de151ea0af79
Revises: 01b54ac28e7d
Create Date: 2026-01-10 15:38:00.559874

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'de151ea0af79'
down_revision: Union[str, Sequence[str], None] = '01b54ac28e7d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create subscriptions table
    op.create_table(
        'subscriptions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('tier', sa.String(length=50), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('stripe_customer_id', sa.String(length=255), nullable=True),
        sa.Column('stripe_subscription_id', sa.String(length=255), nullable=True),
        sa.Column('stripe_price_id', sa.String(length=255), nullable=True),
        sa.Column('billing_period', sa.String(length=50), nullable=True),
        sa.Column('amount', sa.DECIMAL(precision=10, scale=2), nullable=True),
        sa.Column('currency', sa.String(length=3), nullable=False, server_default='USD'),
        sa.Column('trial_start', sa.DateTime(), nullable=True),
        sa.Column('trial_end', sa.DateTime(), nullable=True),
        sa.Column('current_period_start', sa.DateTime(), nullable=True),
        sa.Column('current_period_end', sa.DateTime(), nullable=True),
        sa.Column('cancel_at_period_end', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('canceled_at', sa.DateTime(), nullable=True),
        sa.Column('cancellation_reason', sa.String(length=500), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_subscriptions_user_id'), 'subscriptions', ['user_id'])
    op.create_index(op.f('ix_subscriptions_stripe_customer_id'), 'subscriptions', ['stripe_customer_id'])
    op.create_index(op.f('ix_subscriptions_stripe_subscription_id'), 'subscriptions', ['stripe_subscription_id'])

    # Create payments table
    op.create_table(
        'payments',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('subscription_id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('amount', sa.DECIMAL(precision=10, scale=2), nullable=False),
        sa.Column('currency', sa.String(length=3), nullable=False, server_default='USD'),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('stripe_payment_intent_id', sa.String(length=255), nullable=True),
        sa.Column('stripe_invoice_id', sa.String(length=255), nullable=True),
        sa.Column('payment_method', sa.String(length=50), nullable=True),
        sa.Column('last_four_digits', sa.String(length=4), nullable=True),
        sa.Column('failure_code', sa.String(length=100), nullable=True),
        sa.Column('failure_message', sa.String(length=500), nullable=True),
        sa.Column('payment_metadata', sa.dialects.postgresql.JSONB(), nullable=True),
        sa.Column('paid_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['subscription_id'], ['subscriptions.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_payments_subscription_id'), 'payments', ['subscription_id'])
    op.create_index(op.f('ix_payments_user_id'), 'payments', ['user_id'])
    op.create_index(op.f('ix_payments_stripe_payment_intent_id'), 'payments', ['stripe_payment_intent_id'])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_payments_stripe_payment_intent_id'), table_name='payments')
    op.drop_index(op.f('ix_payments_user_id'), table_name='payments')
    op.drop_index(op.f('ix_payments_subscription_id'), table_name='payments')
    op.drop_table('payments')

    op.drop_index(op.f('ix_subscriptions_stripe_subscription_id'), table_name='subscriptions')
    op.drop_index(op.f('ix_subscriptions_stripe_customer_id'), table_name='subscriptions')
    op.drop_index(op.f('ix_subscriptions_user_id'), table_name='subscriptions')
    op.drop_table('subscriptions')
