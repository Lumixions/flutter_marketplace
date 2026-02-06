from __future__ import annotations

from pydantic import BaseModel, Field


class ProductCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=4000)
    price_cents: int = Field(ge=0)
    currency: str = Field(default="USD", min_length=3, max_length=3)
    stock_qty: int = Field(default=0, ge=0)
    is_active: bool = True


class ProductUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=4000)
    price_cents: int | None = Field(default=None, ge=0)
    currency: str | None = Field(default=None, min_length=3, max_length=3)
    stock_qty: int | None = Field(default=None, ge=0)
    is_active: bool | None = None


class ProductImageOut(BaseModel):
    id: int
    s3_key: str
    sort_order: int
    url: str | None = None


class ProductOut(BaseModel):
    id: int
    seller_id: int
    title: str
    description: str | None
    price_cents: int
    currency: str
    stock_qty: int
    is_active: bool
    images: list[ProductImageOut] = []


class PresignRequest(BaseModel):
    content_type: str = Field(min_length=1, max_length=200)
    filename: str = Field(min_length=1, max_length=512)


class PresignResponse(BaseModel):
    s3_key: str
    upload_url: str
    public_url: str | None = None


class AttachImagesRequest(BaseModel):
    s3_keys: list[str] = Field(min_length=1)

