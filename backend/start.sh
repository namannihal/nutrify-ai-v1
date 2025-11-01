#!/bin/bash

# Nutrify-AI Backend Start Script

set -e

echo "🚀 Starting Nutrify-AI Backend..."

# Activate virtual environment
if [ -d ".venv" ]; then
    source .venv/bin/activate
else
    echo "❌ Virtual environment not found. Run ./setup.sh first"
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found. Run ./setup.sh first"
    exit 1
fi

# Start the server
echo "✅ Starting FastAPI server..."
echo "📡 API: http://localhost:8000"
echo "📚 Docs: http://localhost:8000/docs"
echo "🔄 Press Ctrl+C to stop"
echo ""

uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
