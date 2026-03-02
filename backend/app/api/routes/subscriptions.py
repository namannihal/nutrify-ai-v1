"""Subscription and payment routes"""

from fastapi import APIRouter, Depends, HTTPException, status, Request, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional
from datetime import datetime

from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.subscription import Subscription, Payment, SubscriptionStatus, SubscriptionTier
from app.schemas.subscription import (
    SubscriptionResponse,
    PaymentResponse,
    CheckoutSessionCreate,
    CheckoutSessionResponse,
    PortalSessionCreate,
    PortalSessionResponse,
)
from app.services.stripe_service import StripeService

router = APIRouter()


@router.get("/current", response_model=Optional[SubscriptionResponse])
async def get_current_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get the current user's subscription"""
    result = await db.execute(
        select(Subscription).where(Subscription.user_id == current_user.id)
    )
    subscription = result.scalar_one_or_none()

    return subscription


@router.post("/checkout", response_model=CheckoutSessionResponse)
async def create_checkout_session(
    checkout_data: CheckoutSessionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a Stripe checkout session for subscription"""
    # Check if user already has an active subscription
    result = await db.execute(
        select(Subscription).where(
            Subscription.user_id == current_user.id,
            Subscription.status == SubscriptionStatus.ACTIVE,
        )
    )
    existing_subscription = result.scalar_one_or_none()

    if existing_subscription and existing_subscription.tier != SubscriptionTier.FREE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have an active subscription. Please cancel it first or use the portal to upgrade.",
        )

    # Get or create Stripe customer
    stripe_customer_id = None
    if existing_subscription and existing_subscription.stripe_customer_id:
        stripe_customer_id = existing_subscription.stripe_customer_id
    else:
        stripe_customer_id = await StripeService.create_customer(
            email=current_user.email,
            name=current_user.name,
            user_id=str(current_user.id),
        )

    # Create checkout session
    session = await StripeService.create_checkout_session(
        customer_id=stripe_customer_id,
        tier=checkout_data.tier,
        billing_period=checkout_data.billing_period,
        success_url=checkout_data.success_url,
        cancel_url=checkout_data.cancel_url,
    )

    # Store or update subscription record
    if existing_subscription:
        existing_subscription.stripe_customer_id = stripe_customer_id
    else:
        new_subscription = Subscription(
            user_id=current_user.id,
            tier=SubscriptionTier.FREE,
            status=SubscriptionStatus.ACTIVE,
            stripe_customer_id=stripe_customer_id,
        )
        db.add(new_subscription)

    await db.commit()

    return CheckoutSessionResponse(**session)


@router.post("/portal", response_model=PortalSessionResponse)
async def create_portal_session(
    portal_data: PortalSessionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a Stripe customer portal session"""
    # Get user's subscription
    result = await db.execute(
        select(Subscription).where(Subscription.user_id == current_user.id)
    )
    subscription = result.scalar_one_or_none()

    if not subscription or not subscription.stripe_customer_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No subscription found. Please subscribe first.",
        )

    # Create portal session
    session = await StripeService.create_portal_session(
        customer_id=subscription.stripe_customer_id,
        return_url=portal_data.return_url,
    )

    return PortalSessionResponse(**session)


@router.post("/cancel")
async def cancel_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel the current subscription at period end"""
    # Get user's subscription
    result = await db.execute(
        select(Subscription).where(
            Subscription.user_id == current_user.id,
            Subscription.status == SubscriptionStatus.ACTIVE,
        )
    )
    subscription = result.scalar_one_or_none()

    if not subscription or not subscription.stripe_subscription_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active subscription found.",
        )

    # Cancel in Stripe
    await StripeService.cancel_subscription(
        subscription_id=subscription.stripe_subscription_id,
        at_period_end=True,
    )

    # Update local record
    subscription.cancel_at_period_end = True
    subscription.canceled_at = datetime.now()

    await db.commit()

    return {"message": "Subscription will be canceled at the end of the billing period"}


@router.get("/payments", response_model=List[PaymentResponse])
async def get_payment_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get payment history for the current user"""
    result = await db.execute(
        select(Payment)
        .where(Payment.user_id == current_user.id)
        .order_by(Payment.created_at.desc())
    )
    payments = result.scalars().all()

    return payments


@router.post("/webhook")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="stripe-signature"),
    db: AsyncSession = Depends(get_db),
):
    """Handle Stripe webhook events"""
    payload = await request.body()

    try:
        event = await StripeService.construct_webhook_event(payload, stripe_signature)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    # Handle different event types
    event_type = event["type"]
    data_object = event["data"]["object"]

    if event_type == "checkout.session.completed":
        # Payment successful, activate subscription
        await _handle_checkout_completed(data_object, db)

    elif event_type == "customer.subscription.updated":
        # Subscription updated
        await _handle_subscription_updated(data_object, db)

    elif event_type == "customer.subscription.deleted":
        # Subscription canceled
        await _handle_subscription_deleted(data_object, db)

    elif event_type == "invoice.payment_succeeded":
        # Payment succeeded
        await _handle_payment_succeeded(data_object, db)

    elif event_type == "invoice.payment_failed":
        # Payment failed
        await _handle_payment_failed(data_object, db)

    return {"status": "success"}


async def _handle_checkout_completed(session: dict, db: AsyncSession):
    """Handle successful checkout"""
    customer_id = session.get("customer")
    subscription_id = session.get("subscription")

    # Find subscription by customer ID
    result = await db.execute(
        select(Subscription).where(Subscription.stripe_customer_id == customer_id)
    )
    subscription = result.scalar_one_or_none()

    if subscription:
        subscription.stripe_subscription_id = subscription_id
        subscription.status = SubscriptionStatus.ACTIVE

        # Get subscription details from Stripe
        stripe_sub = await StripeService.retrieve_subscription(subscription_id)

        subscription.tier = _map_stripe_tier(stripe_sub)
        subscription.current_period_start = datetime.fromtimestamp(
            stripe_sub["current_period_start"]
        )
        subscription.current_period_end = datetime.fromtimestamp(
            stripe_sub["current_period_end"]
        )

        # Update user's subscription tier
        user = await db.get(User, subscription.user_id)
        if user:
            user.subscription_tier = subscription.tier

        await db.commit()


async def _handle_subscription_updated(subscription_data: dict, db: AsyncSession):
    """Handle subscription update"""
    subscription_id = subscription_data["id"]

    result = await db.execute(
        select(Subscription).where(Subscription.stripe_subscription_id == subscription_id)
    )
    subscription = result.scalar_one_or_none()

    if subscription:
        subscription.status = subscription_data["status"]
        subscription.current_period_start = datetime.fromtimestamp(
            subscription_data["current_period_start"]
        )
        subscription.current_period_end = datetime.fromtimestamp(
            subscription_data["current_period_end"]
        )
        subscription.cancel_at_period_end = subscription_data.get("cancel_at_period_end", False)

        await db.commit()


async def _handle_subscription_deleted(subscription_data: dict, db: AsyncSession):
    """Handle subscription deletion"""
    subscription_id = subscription_data["id"]

    result = await db.execute(
        select(Subscription).where(Subscription.stripe_subscription_id == subscription_id)
    )
    subscription = result.scalar_one_or_none()

    if subscription:
        subscription.status = SubscriptionStatus.CANCELED
        subscription.tier = SubscriptionTier.FREE

        # Update user's subscription tier
        user = await db.get(User, subscription.user_id)
        if user:
            user.subscription_tier = SubscriptionTier.FREE

        await db.commit()


async def _handle_payment_succeeded(invoice: dict, db: AsyncSession):
    """Handle successful payment"""
    subscription_id = invoice.get("subscription")
    customer_id = invoice.get("customer")

    result = await db.execute(
        select(Subscription).where(Subscription.stripe_subscription_id == subscription_id)
    )
    subscription = result.scalar_one_or_none()

    if subscription:
        # Create payment record
        payment = Payment(
            subscription_id=subscription.id,
            user_id=subscription.user_id,
            amount=invoice["amount_paid"] / 100,  # Convert from cents
            currency=invoice["currency"],
            status="succeeded",
            stripe_payment_intent_id=invoice.get("payment_intent"),
            stripe_invoice_id=invoice["id"],
            paid_at=datetime.fromtimestamp(invoice["status_transitions"]["paid_at"])
            if invoice.get("status_transitions", {}).get("paid_at")
            else None,
        )
        db.add(payment)
        await db.commit()


async def _handle_payment_failed(invoice: dict, db: AsyncSession):
    """Handle failed payment"""
    subscription_id = invoice.get("subscription")

    result = await db.execute(
        select(Subscription).where(Subscription.stripe_subscription_id == subscription_id)
    )
    subscription = result.scalar_one_or_none()

    if subscription:
        subscription.status = SubscriptionStatus.PAST_DUE

        # Create payment record
        payment = Payment(
            subscription_id=subscription.id,
            user_id=subscription.user_id,
            amount=invoice["amount_due"] / 100,  # Convert from cents
            currency=invoice["currency"],
            status="failed",
            stripe_payment_intent_id=invoice.get("payment_intent"),
            stripe_invoice_id=invoice["id"],
        )
        db.add(payment)
        await db.commit()


def _map_stripe_tier(stripe_subscription: dict) -> str:
    """Map Stripe subscription to internal tier"""
    # This is a simple implementation - adjust based on your Stripe price IDs
    price = stripe_subscription["items"]["data"][0]["price"]
    product_name = price.get("product", {}).get("name", "").lower() if isinstance(price.get("product"), dict) else ""

    if "enterprise" in product_name:
        return SubscriptionTier.ENTERPRISE
    elif "premium" in product_name:
        return SubscriptionTier.PREMIUM
    else:
        return SubscriptionTier.FREE
