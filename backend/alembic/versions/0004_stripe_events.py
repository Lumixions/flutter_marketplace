"""stripe event idempotency

Revision ID: 0004_stripe_events
Revises: 0003_orders_addresses_payments
Create Date: 2026-02-06
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0004_stripe_events"
down_revision = "0003_orders_addresses_payments"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "stripe_events",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column("event_id", sa.String(length=255), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.UniqueConstraint("event_id", name="uq_stripe_events_event_id"),
    )


def downgrade() -> None:
    op.drop_table("stripe_events")

