from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.auth import CurrentUser
from app.core.db import get_db
from app.models.address import Address
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.product import Product
from app.schemas.order import CreateOrderRequest, OrderOut, OrderItemOut
from app.schemas.stripe import CheckoutResponse
from app.services.stripe_service import create_checkout_session

router = APIRouter(prefix="/orders", tags=["orders"])


def _order_to_out(o: Order) -> OrderOut:
    return OrderOut(
        id=o.id,
        buyer_id=o.buyer_id,
        seller_id=o.seller_id,
        status=o.status,
        currency=o.currency,
        subtotal_cents=o.subtotal_cents,
        total_cents=o.total_cents,
        created_at=o.created_at,
        items=[
            OrderItemOut(
                id=i.id,
                product_id=i.product_id,
                title=i.title,
                unit_price_cents=i.unit_price_cents,
                quantity=i.quantity,
                line_total_cents=i.line_total_cents,
            )
            for i in (o.items or [])
        ],
    )


@router.post("", response_model=OrderOut)
def create_order(
    body: CreateOrderRequest,
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> OrderOut:
    product_ids = [i.product_id for i in body.items]
    products = db.scalars(select(Product).where(Product.id.in_(product_ids))).all()
    by_id = {p.id: p for p in products}

    # Validate items
    seller_id: int | None = None
    subtotal = 0
    items: list[OrderItem] = []
    for req in body.items:
        p = by_id.get(req.product_id)
        if not p or not p.is_active:
            raise HTTPException(status_code=400, detail=f"Invalid product: {req.product_id}")
        if req.quantity < 1:
            raise HTTPException(status_code=400, detail="Invalid quantity")
        if p.stock_qty < req.quantity:
            raise HTTPException(status_code=400, detail=f"Insufficient stock for {p.id}")

        if seller_id is None:
            seller_id = p.seller_id
        elif seller_id != p.seller_id:
            raise HTTPException(
                status_code=400,
                detail="MVP limitation: one order can only contain items from one seller",
            )

        line_total = p.price_cents * req.quantity
        subtotal += line_total
        items.append(
            OrderItem(
                product_id=p.id,
                title=p.title,
                unit_price_cents=p.price_cents,
                quantity=req.quantity,
                line_total_cents=line_total,
            )
        )

    assert seller_id is not None

    addr = Address(user_id=user.id, **body.shipping_address.model_dump())
    db.add(addr)
    db.commit()
    db.refresh(addr)

    order = Order(
        buyer_id=user.id,
        seller_id=seller_id,
        shipping_address_id=addr.id,
        status="PENDING_PAYMENT",
        currency="USD",
        subtotal_cents=subtotal,
        total_cents=subtotal,
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    for it in items:
        it.order_id = order.id
        db.add(it)
    db.commit()
    db.refresh(order)

    return _order_to_out(order)


@router.get("", response_model=list[OrderOut])
def list_my_orders(
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> list[OrderOut]:
    orders = (
        db.scalars(select(Order).where(Order.buyer_id == user.id).order_by(Order.id.desc()))
        .unique()
        .all()
    )
    return [_order_to_out(o) for o in orders]


@router.post("/{order_id}/checkout", response_model=CheckoutResponse)
def checkout_order(
    order_id: int,
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> CheckoutResponse:
    order = db.get(Order, order_id)
    if not order or order.buyer_id != user.id:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.status != "PENDING_PAYMENT":
        raise HTTPException(status_code=400, detail=f"Order not payable (status={order.status})")

    payment = create_checkout_session(db=db, order=order)
    # Fetch session url from Stripe (we didn't store it).
    import stripe  # local import to avoid import-time config

    session = stripe.checkout.Session.retrieve(payment.stripe_session_id)
    url = session.get("url")
    if not url:
        raise HTTPException(status_code=500, detail="Stripe session missing url")
    return CheckoutResponse(checkout_url=url, stripe_session_id=payment.stripe_session_id or "")

