from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.auth import CurrentUser
from app.core.db import get_db
from app.models.product import Product
from app.models.product_image import ProductImage
from app.models.seller_profile import SellerProfile
from app.schemas.product import (
    AttachImagesRequest,
    PresignRequest,
    PresignResponse,
    ProductCreate,
    ProductOut,
    ProductUpdate,
    ProductImageOut,
)
from app.schemas.seller import SellerProfileOut, SellerProfileUpsert
from app.services.s3 import build_s3_key, presign_put, public_url_for_key

router = APIRouter(prefix="/seller", tags=["seller"])


def _ensure_seller_profile(db: Session, user_id: int) -> SellerProfile | None:
    return db.scalar(select(SellerProfile).where(SellerProfile.user_id == user_id))


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


@router.get("/profile", response_model=SellerProfileOut | None)
def get_profile(
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> SellerProfileOut | None:
    seller = _ensure_seller_profile(db, user.id)
    if not seller:
        return None
    return SellerProfileOut(
        id=seller.id, user_id=seller.user_id, store_name=seller.store_name, status=seller.status
    )


@router.post("/profile", response_model=SellerProfileOut)
def upsert_profile(
    body: SellerProfileUpsert,
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> SellerProfileOut:
    seller = _ensure_seller_profile(db, user.id)
    if seller:
        seller.store_name = body.store_name
        db.add(seller)
        db.commit()
        db.refresh(seller)
    else:
        seller = SellerProfile(user_id=user.id, store_name=body.store_name, status="ACTIVE")
        db.add(seller)
        db.commit()
        db.refresh(seller)
    return SellerProfileOut(
        id=seller.id, user_id=seller.user_id, store_name=seller.store_name, status=seller.status
    )


@router.get("/products", response_model=list[ProductOut])
def list_my_products(
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> list[ProductOut]:
    seller = _ensure_seller_profile(db, user.id)
    if not seller:
        return []
    rows = db.scalars(select(Product).where(Product.seller_id == seller.id)).all()
    return [_product_to_out(p) for p in rows]


@router.post("/products", response_model=ProductOut)
def create_product(
    body: ProductCreate,
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> ProductOut:
    seller = _ensure_seller_profile(db, user.id)
    if not seller:
        raise HTTPException(status_code=403, detail="Seller profile required")

    p = Product(
        seller_id=seller.id,
        title=body.title,
        description=body.description,
        price_cents=body.price_cents,
        currency=body.currency.upper(),
        stock_qty=body.stock_qty,
        is_active=body.is_active,
    )
    db.add(p)
    db.commit()
    db.refresh(p)
    return _product_to_out(p)


@router.patch("/products/{product_id}", response_model=ProductOut)
def update_product(
    product_id: int,
    body: ProductUpdate,
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> ProductOut:
    seller = _ensure_seller_profile(db, user.id)
    if not seller:
        raise HTTPException(status_code=403, detail="Seller profile required")

    p = db.get(Product, product_id)
    if not p or p.seller_id != seller.id:
        raise HTTPException(status_code=404, detail="Product not found")

    for field, value in body.model_dump(exclude_unset=True).items():
        if field == "currency" and value is not None:
            value = value.upper()
        setattr(p, field, value)

    db.add(p)
    db.commit()
    db.refresh(p)
    return _product_to_out(p)


@router.post("/products/{product_id}/images/presign", response_model=PresignResponse)
def presign_product_image_upload(
    product_id: int,
    body: PresignRequest,
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> PresignResponse:
    seller = _ensure_seller_profile(db, user.id)
    if not seller:
        raise HTTPException(status_code=403, detail="Seller profile required")

    p = db.get(Product, product_id)
    if not p or p.seller_id != seller.id:
        raise HTTPException(status_code=404, detail="Product not found")

    s3_key = build_s3_key(product_id=p.id, filename=body.filename)
    upload_url = presign_put(s3_key=s3_key, content_type=body.content_type)
    return PresignResponse(
        s3_key=s3_key,
        upload_url=upload_url,
        public_url=public_url_for_key(s3_key),
    )


@router.post("/products/{product_id}/images/attach", response_model=ProductOut)
def attach_product_images(
    product_id: int,
    body: AttachImagesRequest,
    user: CurrentUser,
    db: Session = Depends(get_db),
) -> ProductOut:
    seller = _ensure_seller_profile(db, user.id)
    if not seller:
        raise HTTPException(status_code=403, detail="Seller profile required")

    p = db.get(Product, product_id)
    if not p or p.seller_id != seller.id:
        raise HTTPException(status_code=404, detail="Product not found")

    existing = db.scalars(
        select(ProductImage).where(ProductImage.product_id == p.id).order_by(ProductImage.sort_order)
    ).all()
    next_sort = (existing[-1].sort_order + 1) if existing else 0

    for key in body.s3_keys:
        img = ProductImage(product_id=p.id, s3_key=key, sort_order=next_sort)
        next_sort += 1
        db.add(img)

    db.commit()
    db.refresh(p)
    return _product_to_out(p)

