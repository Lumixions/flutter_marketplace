from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True)

    buyer_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    seller_id: Mapped[int] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=False, index=True
    )
    shipping_address_id: Mapped[int] = mapped_column(
        ForeignKey("addresses.id"), nullable=False
    )

    status: Mapped[str] = mapped_column(String(32), default="PENDING_PAYMENT")
    currency: Mapped[str] = mapped_column(String(3), default="USD")

    subtotal_cents: Mapped[int] = mapped_column(Integer(), default=0)
    total_cents: Mapped[int] = mapped_column(Integer(), default=0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    items = relationship(
        "OrderItem",
        back_populates="order",
        cascade="all, delete-orphan",
        order_by="OrderItem.id",
    )

