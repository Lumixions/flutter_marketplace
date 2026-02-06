# Infra (local dev)

## Postgres

From this directory:

```bash
docker compose up
```

Database defaults:

- host: `localhost`
- port: `5432`
- user: `postgres`
- password: `postgres`
- db: `marketplace_v2`

## MinIO (optional)

MinIO is included for local S3-like storage. Console:

- `http://localhost:9001`
- user: `minio`
- pass: `minio12345`

Note: the backend MVP uses AWS credentials + region only; if you want to use MinIO,
we can add an `AWS_ENDPOINT_URL` setting and configure boto3 to use it.

