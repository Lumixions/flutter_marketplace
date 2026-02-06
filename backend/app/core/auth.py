from __future__ import annotations

import json
from functools import lru_cache
from typing import Annotated

import firebase_admin
from fastapi import Depends, Header, HTTPException
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.db import get_db
from app.models.user import User


@lru_cache(maxsize=1)
def _init_firebase() -> None:
    if firebase_admin._apps:  # pragma: no cover
        return

    cred = None
    if settings.firebase_service_account_path:
        cred = credentials.Certificate(settings.firebase_service_account_path)
    elif settings.firebase_service_account_json:
        cred = credentials.Certificate(json.loads(settings.firebase_service_account_json))

    if cred is None:
        raise RuntimeError(
            "Firebase Admin is not configured. Set FIREBASE_SERVICE_ACCOUNT_PATH or "
            "FIREBASE_SERVICE_ACCOUNT_JSON."
        )

    firebase_admin.initialize_app(cred)


def _parse_bearer(authorization: str | None) -> str | None:
    if not authorization:
        return None
    parts = authorization.split(" ", 1)
    if len(parts) != 2:
        return None
    scheme, token = parts[0].lower(), parts[1].strip()
    if scheme != "bearer" or not token:
        return None
    return token


def get_current_user(
    authorization: Annotated[str | None, Header()] = None,
    db: Session = Depends(get_db),
) -> User:
    token = _parse_bearer(authorization)
    if not token:
        raise HTTPException(status_code=401, detail="Missing bearer token")

    _init_firebase()
    try:
        decoded = firebase_auth.verify_id_token(token)
    except Exception as e:  # noqa: BLE001
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}") from e

    uid = decoded.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Invalid token: missing uid")

    email = decoded.get("email")
    name = decoded.get("name")

    existing = db.scalar(select(User).where(User.firebase_uid == uid))
    if existing:
        existing.email = email or existing.email
        existing.display_name = name or existing.display_name
        db.add(existing)
        db.commit()
        db.refresh(existing)
        return existing

    user = User(firebase_uid=uid, email=email, display_name=name)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]

