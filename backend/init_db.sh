#!/bin/bash

# Database initialization script

set -e

echo "🗄️  Initializing Nutrify-AI Database..."

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ .env file not found"
    exit 1
fi

# Extract database name from DATABASE_URL
DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')

echo "📦 Database name: $DB_NAME"

# Check if using Docker
if docker compose ps postgres &> /dev/null; then
    echo "🐳 Using Docker PostgreSQL"
    echo "✅ Database is created by Docker automatically"
else
    echo "💻 Using local PostgreSQL"
    
    # Check if database exists
    if psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        echo "✅ Database '$DB_NAME' already exists"
    else
        echo "🆕 Creating database '$DB_NAME'..."
        createdb $DB_NAME
        echo "✅ Database created successfully"
    fi
fi

# Run database migrations (if using Alembic)
if [ -d "migrations" ]; then
    echo "🔄 Running database migrations..."
    alembic upgrade head
    echo "✅ Migrations completed"
else
    echo "⚠️  No migrations directory found. Tables will be created on first run."
fi

echo "✨ Database initialization complete!"
