#!/bin/bash

# Render startup script for Nutrify-AI Backend

set -e

echo "🚀 Starting Nutrify-AI Backend on Render..."

# Run database migrations (if needed)
if [ "$ENVIRONMENT" = "production" ]; then
    echo "📊 Running database migrations..."
    # alembic upgrade head
fi

# Start the FastAPI server
echo "✅ Starting FastAPI server..."
exec uvicorn app.main:app --host 0.0.0.0 --port $PORT