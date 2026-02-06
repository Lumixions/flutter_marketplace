# Architecture (MVP)

## Components

- Flutter app (mobile + web)
  - Firebase Auth (Google/Apple) for sign-in
  - Buyer UI (mobile-first): browse, cart, checkout
  - Seller portal UI (mobile-first): manage products, upload images, manage orders
- Backend (FastAPI)
  - Verifies Firebase ID tokens (Firebase Admin)
  - Stores marketplace data in Postgres
  - Issues S3 pre-signed URLs for product image uploads
  - Creates Stripe Checkout sessions + processes Stripe webhooks

## Auth

Flutter obtains a Firebase ID token and sends it to the backend:

`Authorization: Bearer <firebase_id_token>`

Backend verifies token, creates/updates internal `users` record by Firebase `uid`.

## Payments (Stripe Checkout)

1. App creates an order.
2. App requests checkout for that order.
3. Backend creates a Stripe Checkout session and returns `checkoutUrl`.
4. Buyer pays on Stripe hosted page.
5. Stripe webhook marks order `PAID`.

