# ---------- Builder Stage ----------
FROM python:3.11-slim as builder

WORKDIR /app

# Avoid debconf frontend errors
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies for building wheels
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    ca-certificates \
    curl \
    git \
    pkg-config \
    cmake \
    libpq-dev \
    libssl-dev \
    libffi-dev \
    libgomp1 \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install uv (Python dependency manager)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Copy source code and README (required by hatchling)
COPY README.md ./
COPY app ./app

# Install dependencies in isolated virtual environment
RUN uv venv && uv pip install --upgrade pip && uv sync --frozen --no-dev

# ---------- Runtime Stage ----------
FROM python:3.11-slim

WORKDIR /app

# Avoid debconf frontend errors
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

# Copy virtual environment from builder
COPY --from=builder --chown=appuser:appuser /app/.venv /app/.venv

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Health check (ensure requests is installed or switch to curl)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose backend port
EXPOSE 8000

# Run the FastAPI app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
