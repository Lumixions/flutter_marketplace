# Deployment notes (MVP)

## Backend (FastAPI)

- Run migrations:
  - `alembic upgrade head`
- Start server:
  - `uvicorn app.main:app --host 0.0.0.0 --port 8000`

### Required environment variables

- `DATABASE_URL`
- `FIREBASE_SERVICE_ACCOUNT_PATH` (or `FIREBASE_SERVICE_ACCOUNT_JSON`)
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_SUCCESS_URL`
- `STRIPE_CANCEL_URL`
- `S3_BUCKET`, `S3_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

## Stripe webhooks

In production, configure a webhook endpoint:

- `POST /webhooks/stripe`

For local testing, you can use the Stripe CLI to forward webhooks to localhost.

## Firebase Auth

- Create a Firebase project.
- Enable Google sign-in and Apple sign-in.
- Create a service account JSON and point backend at it.

## S3

For MVP, `public_url` assumes the bucket/object is publicly readable.
If you want private buckets, add either:

- CloudFront + signed URLs, or
- backend-signed GET URLs for downloads.

