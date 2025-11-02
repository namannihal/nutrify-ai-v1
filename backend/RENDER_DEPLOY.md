# Nutrify AI Backend - Render Deployment

## Environment Variables Required:

- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string  
- `JWT_SECRET_KEY`: Random secret key for JWT tokens
- `OPENAI_API_KEY`: Your OpenAI API key
- `ENVIRONMENT`: production

## Build Command:
```bash
pip install -e .
```

## Start Command:
```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

## Database Setup:
The app will automatically run migrations on startup via Alembic.