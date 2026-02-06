from __future__ import annotations

import os
import uuid

import boto3

from app.core.config import settings


def _s3_client():
    return boto3.client(
        "s3",
        region_name=settings.s3_region,
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
    )


def build_s3_key(*, product_id: int, filename: str) -> str:
    _, ext = os.path.splitext(filename)
    ext = ext[:10]  # guard absurd extensions
    return f"products/{product_id}/{uuid.uuid4().hex}{ext}"


def presign_put(*, s3_key: str, content_type: str, expires_seconds: int = 900) -> str:
    if not settings.s3_bucket or not settings.s3_region:
        raise RuntimeError("S3 is not configured. Set S3_BUCKET and S3_REGION.")

    client = _s3_client()
    return client.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": settings.s3_bucket,
            "Key": s3_key,
            "ContentType": content_type,
        },
        ExpiresIn=expires_seconds,
    )


def public_url_for_key(s3_key: str) -> str | None:
    """
    If your bucket is public (or fronted by CloudFront), this URL will resolve.
    For private buckets you should serve via signed GET or a CDN.
    """
    if not settings.s3_bucket or not settings.s3_region:
        return None

    region = settings.s3_region
    bucket = settings.s3_bucket
    if region == "us-east-1":
        return f"https://{bucket}.s3.amazonaws.com/{s3_key}"
    return f"https://{bucket}.s3.{region}.amazonaws.com/{s3_key}"

