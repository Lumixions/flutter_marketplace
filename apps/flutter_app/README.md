# Flutter app (mobile + web)

Single Flutter app that serves:

- Buyer experience (mobile-first UI)
- Seller portal (mobile-first UI under `/seller`)

## Prerequisites

- Install Flutter SDK locally
- Create a Firebase project with Google + Apple sign-in enabled

## First-time setup

This repository is scaffolded without platform folders (because Flutter CLI isn't available in this environment).
On your machine, from this directory run:

```bash
flutter create .
```

Then add Firebase configs:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Web: provide Firebase web config via `--dart-define` values (see below)

## Navigation

- Buyer: bottom tabs (Shop / Cart / Orders)
- Seller: go to `/seller` (bottom tabs: Home / Products / Orders)

## Run (web)

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=...
```

## Config notes (`--dart-define` and `fromEnvironment`)

The app reads values like `API_BASE_URL` from compile-time defines:

- run/build time: `--dart-define=API_BASE_URL=http://localhost:8000`
- code: `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000')`

## Run (mobile)

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000
```

