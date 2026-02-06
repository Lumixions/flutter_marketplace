# Backend (FastAPI)

## Setup (local)

1) Create a virtualenv and install deps:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

2) Configure env:

```bash
cp .env.example .env
```

3) Start Postgres (from repo root):

```bash
cd ../infra
docker compose up
```

4) Run migrations:

```bash
alembic upgrade head
```

5) Run API:

```bash
uvicorn app.main:app --reload --port 8000
```

## Core endpoints (MVP)

- Public:
  - `GET /health`
  - `GET /products`
  - `GET /products/{id}`
- Seller (requires Firebase bearer token):
  - `GET /seller/profile`
  - `POST /seller/profile`
  - `GET /seller/products`
  - `POST /seller/products`
  - `PATCH /seller/products/{id}`
  - `POST /seller/products/{id}/images/presign`
  - `POST /seller/products/{id}/images/attach`
- Buyer (requires Firebase bearer token):
  - `POST /orders`
  - `GET /orders`
  - `POST /orders/{id}/checkout` (Stripe Checkout URL)
- Stripe:
  - `POST /webhooks/stripe`
  - `GET /stripe/success`
  - `GET /stripe/cancel`

## Auth

Clients must send Firebase ID tokens:

`Authorization: Bearer <firebase_id_token>`

## Stripe (local notes)

- Set:
  - `STRIPE_SECRET_KEY`
  - `STRIPE_WEBHOOK_SECRET`
  - `STRIPE_SUCCESS_URL` (defaults in `.env.example`)
  - `STRIPE_CANCEL_URL`
- Orders are created as `PENDING_PAYMENT`, then marked `PAID` via webhook `checkout.session.completed`.

