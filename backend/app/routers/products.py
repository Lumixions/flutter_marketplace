from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.product import Product
from app.schemas.product import ProductOut, ProductImageOut
from app.services.s3 import public_url_for_key

router = APIRouter(prefix="/products", tags=["products"])


def _product_to_out(p: Product) -> ProductOut:
    return ProductOut(
        id=p.id,
        seller_id=p.seller_id,
        title=p.title,
        description=p.description,
        price_cents=p.price_cents,
        currency=p.currency,
        stock_qty=p.stock_qty,
        is_active=p.is_active,
        images=[
            ProductImageOut(
                id=img.id,
                s3_key=img.s3_key,
                sort_order=img.sort_order,
                url=public_url_for_key(img.s3_key),
            )
            for img in (p.images or [])
        ],
    )


@router.get("", response_model=list[ProductOut])
def list_products(db: Session = Depends(get_db)) -> list[ProductOut]:
    rows = db.scalars(select(Product).where(Product.is_active == True)).all()  # noqa: E712
    return [_product_to_out(p) for p in rows]


@router.get("/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)) -> ProductOut:
    p = db.get(Product, product_id)
    if not p or not p.is_active:
        raise HTTPException(status_code=404, detail="Product not found")
    return _product_to_out(p)

