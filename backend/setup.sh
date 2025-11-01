#!/bin/bash

# Nutrify-AI Backend Setup and Start Script

set -e

echo "🚀 Nutrify-AI Backend Setup"
echo "=============================="

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "❌ uv is not installed. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "✅ uv installed successfully"
else
    echo "✅ uv is already installed"
fi

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment..."
    uv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source .venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
uv pip install -e .
echo "✅ Dependencies installed"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Copying from .env.example..."
    cp .env.example .env
    echo "✅ .env file created. Please update it with your configuration."
    echo "❗ Required: DATABASE_URL, REDIS_URL, SECRET_KEY, OPENAI_API_KEY"
    exit 1
fi

# Check if Docker is available
echo "🔍 Checking Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker found"
    
    # Check if docker-compose.yml exists
    if [ -f "docker-compose.yml" ]; then
        echo "🐳 Starting PostgreSQL and Redis with Docker..."
        docker compose up -d postgres redis
        
        # Wait for services to be healthy
        echo "⏳ Waiting for services to be ready..."
        sleep 5
        
        if docker compose ps postgres | grep -q "healthy"; then
            echo "✅ PostgreSQL is running"
        else
            echo "⏳ PostgreSQL is starting..."
        fi
        
        if docker compose ps redis | grep -q "healthy"; then
            echo "✅ Redis is running"
        else
            echo "⏳ Redis is starting..."
        fi
    else
        echo "⚠️  docker-compose.yml not found"
    fi
else
    echo "⚠️  Docker not found. Checking for local installations..."
    
    # Check if PostgreSQL is running
    echo "🔍 Checking PostgreSQL..."
    if command -v psql &> /dev/null; then
        echo "✅ PostgreSQL client found"
    else
        echo "⚠️  PostgreSQL client not found. Please install PostgreSQL or use Docker"
    fi

    # Check if Redis is running
    echo "🔍 Checking Redis..."
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping > /dev/null 2>&1; then
            echo "✅ Redis is running"
        else
            echo "⚠️  Redis is not running. Starting Redis..."
            if command -v brew &> /dev/null; then
                brew services start redis
            else
                echo "❗ Please start Redis manually: redis-server"
            fi
        fi
    else
        echo "⚠️  Redis not found. Please install Redis or use Docker"
    fi
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Update .env with your configuration"
echo "   2. If using Docker:"
echo "      - Database is already created!"
echo "      - Access pgAdmin at http://localhost:5050 (optional)"
echo "   3. If using local PostgreSQL:"
echo "      - Create database: createdb nutrify_db"
echo "   4. Start the server: ./start.sh"
echo ""
