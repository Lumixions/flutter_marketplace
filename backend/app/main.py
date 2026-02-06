from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import health, orders, products, seller, stripe_redirects, webhooks


def create_app() -> FastAPI:
    app = FastAPI(title="Marketplace V2 API")

    allow_origins = [o.strip() for o in settings.allow_origins.split(",") if o.strip()]
    if allow_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=allow_origins,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    app.include_router(health.router)
    app.include_router(products.router)
    app.include_router(seller.router)
    app.include_router(orders.router)
    app.include_router(webhooks.router)
    app.include_router(stripe_redirects.router)
    return app


app = create_app()

