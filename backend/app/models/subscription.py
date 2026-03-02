"""Subscription and Payment models"""

from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4
from sqlalchemy import String, Integer, DECIMAL, Boolean, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB
from sqlalchemy.sql import func
from enum import Enum

from app.core.database import Base


class SubscriptionTier(str, Enum):
    """Subscription tier enum"""
    FREE = "free"
    PREMIUM = "premium"
    ENTERPRISE = "enterprise"


class SubscriptionStatus(str, Enum):
    """Subscription status enum"""
    ACTIVE = "active"
    CANCELED = "canceled"
    PAST_DUE = "past_due"
    TRIALING = "trialing"
    EXPIRED = "expired"


class PaymentStatus(str, Enum):
    """Payment status enum"""
    PENDING = "pending"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    REFUNDED = "refunded"


class Subscription(Base):
    """User subscription model"""

    __tablename__ = "subscriptions"

    # Primary Key
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)

    # User Reference
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Subscription Details
    tier: Mapped[str] = mapped_column(
        SQLEnum(SubscriptionTier, native_enum=False),
        nullable=False,
        default=SubscriptionTier.FREE
    )
    status: Mapped[str] = mapped_column(
        SQLEnum(SubscriptionStatus, native_enum=False),
        nullable=False,
        default=SubscriptionStatus.ACTIVE
    )

    # Stripe Integration
    stripe_customer_id: Mapped[Optional[str]] = mapped_column(String(255), index=True)
    stripe_subscription_id: Mapped[Optional[str]] = mapped_column(String(255), index=True)
    stripe_price_id: Mapped[Optional[str]] = mapped_column(String(255))

    # Billing
    billing_period: Mapped[Optional[str]] = mapped_column(String(50))  # monthly, yearly
    amount: Mapped[Optional[float]] = mapped_column(DECIMAL(10, 2))
    currency: Mapped[str] = mapped_column(String(3), default="USD")

    # Trial
    trial_start: Mapped[Optional[datetime]]
    trial_end: Mapped[Optional[datetime]]

    # Subscription Period
    current_period_start: Mapped[Optional[datetime]]
    current_period_end: Mapped[Optional[datetime]]
    cancel_at_period_end: Mapped[bool] = mapped_column(Boolean, default=False)

    # Cancellation
    canceled_at: Mapped[Optional[datetime]]
    cancellation_reason: Mapped[Optional[str]] = mapped_column(String(500))

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now(),
        onupdate=func.now()
    )

    # Relationships
    user: Mapped["User"] = relationship("User")
    payments: Mapped[list["Payment"]] = relationship(
        "Payment",
        back_populates="subscription",
        cascade="all, delete-orphan"
    )


class Payment(Base):
    """Payment transaction model"""

    __tablename__ = "payments"

    # Primary Key
    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)

    # References
    subscription_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("subscriptions.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Payment Details
    amount: Mapped[float] = mapped_column(DECIMAL(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="USD")
    status: Mapped[str] = mapped_column(
        SQLEnum(PaymentStatus, native_enum=False),
        nullable=False,
        default=PaymentStatus.PENDING
    )

    # Stripe Integration
    stripe_payment_intent_id: Mapped[Optional[str]] = mapped_column(String(255), index=True)
    stripe_invoice_id: Mapped[Optional[str]] = mapped_column(String(255))

    # Payment Method
    payment_method: Mapped[Optional[str]] = mapped_column(String(50))  # card, paypal, etc.
    last_four_digits: Mapped[Optional[str]] = mapped_column(String(4))

    # Failure Information
    failure_code: Mapped[Optional[str]] = mapped_column(String(100))
    failure_message: Mapped[Optional[str]] = mapped_column(String(500))

    # Metadata
    payment_metadata: Mapped[Optional[dict]] = mapped_column(JSONB)

    # Timestamps
    paid_at: Mapped[Optional[datetime]]
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=func.now(),
        onupdate=func.now()
    )

    # Relationships
    subscription: Mapped["Subscription"] = relationship("Subscription", back_populates="payments")
    user: Mapped["User"] = relationship("User")
