from __future__ import annotations

import stripe
from fastapi import APIRouter, Depends, Header, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.db import get_db
from app.models.order import Order
from app.models.payment import Payment
from app.models.product import Product
from app.models.stripe_event import StripeEvent

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


@router.post("/stripe")
async def stripe_webhook(
    request: Request,
    stripe_signature: str | None = Header(default=None, alias="Stripe-Signature"),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    if not settings.stripe_webhook_secret:
        raise HTTPException(status_code=500, detail="Stripe webhook not configured")

    payload = await request.body()
    try:
        event = stripe.Webhook.construct_event(
            payload=payload,
            sig_header=stripe_signature,
            secret=settings.stripe_webhook_secret,
        )
    except Exception as e:  # noqa: BLE001
        raise HTTPException(status_code=400, detail=f"Invalid webhook: {e}") from e

    # Idempotency: store event id (unique)
    try:
        db.add(StripeEvent(event_id=event["id"]))
        db.commit()
    except IntegrityError:
        db.rollback()
        return {"status": "duplicate"}

    if event["type"] == "checkout.session.completed":
        session_obj = event["data"]["object"]
        session_id = session_obj.get("id")
        payment_intent = session_obj.get("payment_intent")
        order_id = session_obj.get("metadata", {}).get("order_id")

        if not order_id:
            return {"status": "ignored"}

        order = db.get(Order, int(order_id))
        if not order:
            return {"status": "ignored"}

        payment = db.scalar(select(Payment).where(Payment.order_id == order.id))
        if not payment:
            payment = Payment(order_id=order.id, stripe_session_id=session_id, status="PAID")
            db.add(payment)
        else:
            payment.stripe_session_id = payment.stripe_session_id or session_id
            payment.stripe_payment_intent_id = payment_intent
            payment.status = "PAID"
            db.add(payment)

        if order.status != "PAID":
            order.status = "PAID"
            db.add(order)

            # Reduce stock (best-effort)
            for it in order.items or []:
                p = db.get(Product, it.product_id)
                if p:
                    p.stock_qty = max(0, p.stock_qty - it.quantity)
                    db.add(p)

        db.commit()
        return {"status": "ok"}

    return {"status": "unhandled"}

