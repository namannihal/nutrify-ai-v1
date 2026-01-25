"""Stripe payment service"""

import os
from typing import Optional
import stripe
from datetime import datetime

# Initialize Stripe
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")


class StripeService:
    """Service for handling Stripe payment operations"""

    # Pricing configuration (in paise for INR)
    PRICES = {
        "premium_monthly": {
            "amount": 124900,  # ₹1,249
            "currency": "inr",
            "interval": "month",
        },
        "premium_yearly": {
            "amount": 999900,  # ₹9,999 (~33% discount)
            "currency": "inr",
            "interval": "year",
        },
        "enterprise_monthly": {
            "amount": 299900,  # ₹2,999
            "currency": "inr",
            "interval": "month",
        },
        "enterprise_yearly": {
            "amount": 2499900,  # ₹24,999 (~30% discount)
            "currency": "inr",
            "interval": "year",
        },
    }

    @staticmethod
    async def create_customer(email: str, name: str, user_id: str) -> str:
        """Create a Stripe customer"""
        try:
            customer = stripe.Customer.create(
                email=email,
                name=name,
                metadata={"user_id": str(user_id)},
            )
            return customer.id
        except stripe.error.StripeError as e:
            raise Exception(f"Failed to create Stripe customer: {str(e)}")

    @staticmethod
    async def create_checkout_session(
        customer_id: str,
        tier: str,
        billing_period: str,
        success_url: str,
        cancel_url: str,
    ) -> dict:
        """Create a Stripe checkout session"""
        try:
            price_key = f"{tier}_{billing_period}"
            price_config = StripeService.PRICES.get(price_key)

            if not price_config:
                raise ValueError(f"Invalid tier or billing period: {price_key}")

            # Create or retrieve price
            price = stripe.Price.create(
                unit_amount=price_config["amount"],
                currency=price_config["currency"],
                recurring={"interval": price_config["interval"]},
                product_data={
                    "name": f"Nutrify-AI {tier.capitalize()} Subscription",
                },
            )

            session = stripe.checkout.Session.create(
                customer=customer_id,
                payment_method_types=["card"],
                line_items=[
                    {
                        "price": price.id,
                        "quantity": 1,
                    }
                ],
                mode="subscription",
                success_url=success_url,
                cancel_url=cancel_url,
                subscription_data={
                    "trial_period_days": 14,  # 14-day free trial
                },
            )

            return {"session_id": session.id, "url": session.url}
        except stripe.error.StripeError as e:
            raise Exception(f"Failed to create checkout session: {str(e)}")

    @staticmethod
    async def create_portal_session(customer_id: str, return_url: str) -> dict:
        """Create a Stripe customer portal session"""
        try:
            session = stripe.billing_portal.Session.create(
                customer=customer_id,
                return_url=return_url,
            )
            return {"url": session.url}
        except stripe.error.StripeError as e:
            raise Exception(f"Failed to create portal session: {str(e)}")

    @staticmethod
    async def cancel_subscription(subscription_id: str, at_period_end: bool = True) -> dict:
        """Cancel a Stripe subscription"""
        try:
            if at_period_end:
                subscription = stripe.Subscription.modify(
                    subscription_id,
                    cancel_at_period_end=True,
                )
            else:
                subscription = stripe.Subscription.delete(subscription_id)

            return subscription
        except stripe.error.StripeError as e:
            raise Exception(f"Failed to cancel subscription: {str(e)}")

    @staticmethod
    async def update_subscription(subscription_id: str, new_price_id: str) -> dict:
        """Update a Stripe subscription"""
        try:
            subscription = stripe.Subscription.retrieve(subscription_id)

            updated_subscription = stripe.Subscription.modify(
                subscription_id,
                items=[
                    {
                        "id": subscription["items"]["data"][0].id,
                        "price": new_price_id,
                    }
                ],
            )

            return updated_subscription
        except stripe.error.StripeError as e:
            raise Exception(f"Failed to update subscription: {str(e)}")

    @staticmethod
    async def retrieve_subscription(subscription_id: str) -> dict:
        """Retrieve a Stripe subscription"""
        try:
            subscription = stripe.Subscription.retrieve(subscription_id)
            return subscription
        except stripe.error.StripeError as e:
            raise Exception(f"Failed to retrieve subscription: {str(e)}")

    @staticmethod
    async def construct_webhook_event(payload: bytes, sig_header: str) -> dict:
        """Construct and verify a Stripe webhook event"""
        try:
            webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET")
            event = stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
            return event
        except ValueError as e:
            raise Exception(f"Invalid payload: {str(e)}")
        except stripe.error.SignatureVerificationError as e:
            raise Exception(f"Invalid signature: {str(e)}")
