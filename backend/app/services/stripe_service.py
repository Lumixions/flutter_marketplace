from __future__ import annotations

import stripe
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.order import Order
from app.models.payment import Payment


def _ensure_stripe() -> None:
    if not settings.stripe_secret_key:
        raise HTTPException(status_code=500, detail="Stripe not configured (STRIPE_SECRET_KEY)")
    stripe.api_key = settings.stripe_secret_key


def create_checkout_session(*, db: Session, order: Order) -> Payment:
    _ensure_stripe()
    if not settings.stripe_success_url or not settings.stripe_cancel_url:
        raise HTTPException(
            status_code=500,
            detail="Stripe redirect URLs not configured (STRIPE_SUCCESS_URL/STRIPE_CANCEL_URL)",
        )

    payment = db.scalar(select(Payment).where(Payment.order_id == order.id))
    if payment and payment.stripe_session_id:
        return payment

    if not order.items:
        raise HTTPException(status_code=400, detail="Order has no items")

    line_items = []
    for it in order.items:
        line_items.append(
            {
                "price_data": {
                    "currency": order.currency.lower(),
                    "product_data": {"name": it.title},
                    "unit_amount": it.unit_price_cents,
                },
                "quantity": it.quantity,
            }
        )

    session = stripe.checkout.Session.create(
        mode="payment",
        line_items=line_items,
        success_url=settings.stripe_success_url,
        cancel_url=settings.stripe_cancel_url,
        client_reference_id=str(order.id),
        metadata={"order_id": str(order.id)},
    )

    if payment:
        payment.stripe_session_id = session["id"]
        payment.status = "PENDING"
        db.add(payment)
    else:
        payment = Payment(order_id=order.id, stripe_session_id=session["id"], status="PENDING")
        db.add(payment)

    db.commit()
    db.refresh(payment)
    return payment

