# syntax=docker/dockerfile:1

# ---- builder: resolve and install deps into an in-project venv ----
FROM python:3.12-slim AS builder

ENV POETRY_VERSION=1.8.5 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN pip install "poetry==${POETRY_VERSION}"

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN poetry install --only main --no-root

# ---- runtime ----
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:${PATH}" \
    PORT=8000

# Claude CLI is bundled with claude-agent-sdk; no Node.js needed.
RUN useradd --create-home --uid 1000 app

WORKDIR /app
COPY --from=builder --chown=app:app /app/.venv /app/.venv
COPY --chown=app:app src ./src
COPY --chown=app:app pyproject.toml README.md ./

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD python -c "import os,urllib.request as u; u.urlopen(f'http://127.0.0.1:{os.environ.get(\"PORT\",\"8000\")}/health', timeout=4)" || exit 1

CMD ["sh", "-c", "exec uvicorn src.main:app --host 0.0.0.0 --port ${PORT}"]
