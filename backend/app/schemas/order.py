from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class AddressIn(BaseModel):
    full_name: str = Field(min_length=1, max_length=200)
    line1: str = Field(min_length=1, max_length=200)
    line2: str | None = Field(default=None, max_length=200)
    city: str = Field(min_length=1, max_length=100)
    state: str | None = Field(default=None, max_length=100)
    postal_code: str = Field(min_length=1, max_length=40)
    country: str = Field(default="US", min_length=2, max_length=2)
    phone: str | None = Field(default=None, max_length=40)


class OrderItemIn(BaseModel):
    product_id: int
    quantity: int = Field(ge=1)


class CreateOrderRequest(BaseModel):
    items: list[OrderItemIn] = Field(min_length=1)
    shipping_address: AddressIn


class OrderItemOut(BaseModel):
    id: int
    product_id: int
    title: str
    unit_price_cents: int
    quantity: int
    line_total_cents: int


class OrderOut(BaseModel):
    id: int
    buyer_id: int
    seller_id: int
    status: str
    currency: str
    subtotal_cents: int
    total_cents: int
    created_at: datetime
    items: list[OrderItemOut]

