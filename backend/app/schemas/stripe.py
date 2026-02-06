from __future__ import annotations

from pydantic import BaseModel


class CheckoutResponse(BaseModel):
    checkout_url: str
    stripe_session_id: str

