from __future__ import annotations

from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter(tags=["stripe"])


@router.get("/stripe/success", response_class=HTMLResponse)
def stripe_success() -> str:
    return """
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>Payment successful</title></head>
  <body style="font-family: system-ui; padding: 32px;">
    <h2>Payment successful</h2>
    <p>You can close this tab and return to the app.</p>
  </body>
</html>
""".strip()


@router.get("/stripe/cancel", response_class=HTMLResponse)
def stripe_cancel() -> str:
    return """
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>Payment cancelled</title></head>
  <body style="font-family: system-ui; padding: 32px;">
    <h2>Payment cancelled</h2>
    <p>You can close this tab and return to the app.</p>
  </body>
</html>
""".strip()

