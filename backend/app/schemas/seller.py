from __future__ import annotations

from pydantic import BaseModel, Field


class SellerProfileUpsert(BaseModel):
    store_name: str = Field(min_length=1, max_length=200)


class SellerProfileOut(BaseModel):
    id: int
    user_id: int
    store_name: str
    status: str

