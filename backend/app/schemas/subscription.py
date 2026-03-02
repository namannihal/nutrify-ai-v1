"""Subscription and Payment schemas"""

from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field, validator


class SubscriptionBase(BaseModel):
    """Base subscription schema"""
    tier: str = Field(..., description="Subscription tier")


class SubscriptionCreate(SubscriptionBase):
    """Create subscription schema"""
    payment_method_id: Optional[str] = Field(None, description="Stripe payment method ID")
    billing_period: str = Field("monthly", description="Billing period: monthly or yearly")


class SubscriptionUpdate(BaseModel):
    """Update subscription schema"""
    tier: Optional[str] = None
    cancel_at_period_end: Optional[bool] = None


class SubscriptionResponse(BaseModel):
    """Subscription response schema"""
    id: UUID
    user_id: UUID
    tier: str
    status: str
    billing_period: Optional[str] = None
    amount: Optional[float] = None
    currency: str
    trial_start: Optional[datetime] = None
    trial_end: Optional[datetime] = None
    current_period_start: Optional[datetime] = None
    current_period_end: Optional[datetime] = None
    cancel_at_period_end: bool
    canceled_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PaymentResponse(BaseModel):
    """Payment response schema"""
    id: UUID
    subscription_id: UUID
    user_id: UUID
    amount: float
    currency: str
    status: str
    payment_method: Optional[str] = None
    last_four_digits: Optional[str] = None
    paid_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


class CheckoutSessionCreate(BaseModel):
    """Create Stripe checkout session"""
    tier: str = Field(..., description="Subscription tier: premium or enterprise")
    billing_period: str = Field("monthly", description="Billing period: monthly or yearly")
    success_url: str = Field(..., description="URL to redirect on success")
    cancel_url: str = Field(..., description="URL to redirect on cancel")

    @validator('tier')
    def validate_tier(cls, v):
        if v not in ['premium', 'enterprise']:
            raise ValueError('Tier must be either premium or enterprise')
        return v

    @validator('billing_period')
    def validate_billing_period(cls, v):
        if v not in ['monthly', 'yearly']:
            raise ValueError('Billing period must be either monthly or yearly')
        return v


class CheckoutSessionResponse(BaseModel):
    """Checkout session response"""
    session_id: str
    url: str


class PortalSessionCreate(BaseModel):
    """Create Stripe customer portal session"""
    return_url: str = Field(..., description="URL to redirect after portal session")


class PortalSessionResponse(BaseModel):
    """Portal session response"""
    url: str


class WebhookEvent(BaseModel):
    """Stripe webhook event"""
    type: str
    data: dict
