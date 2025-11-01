# Quick Start Guide - Nutrify-AI Backend

## 🚀 Quick Start (5 minutes)

### Prerequisites

- Docker & Docker Compose (recommended)
- OR PostgreSQL 14+ and Redis 6+ installed locally
- Python 3.11+
- uv package manager

### 1. Start Database (Docker - Recommended)

```bash
cd backend

# Start PostgreSQL and Redis with Docker
docker compose up -d

# Verify services are running
docker compose ps
```

### 2. Setup Backend

```bash
# Make scripts executable
chmod +x setup.sh start.sh init_db.sh

# Run setup (installs dependencies)
./setup.sh
```

### 3. Configure Environment

Edit `.env` file with your settings:

```bash
# Database (Docker default credentials)
DATABASE_URL=postgresql+asyncpg://nutrify_user:nutrify_password@localhost:5432/nutrify_db
REDIS_URL=redis://localhost:6379/0

# Security - Generate a secure key
SECRET_KEY=$(openssl rand -hex 32)

# AI - Required for AI features
OPENAI_API_KEY=sk-your-openai-api-key

# Optional: Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

**Note:** If using Docker, database is already created! No need to run `createdb`.

### 4. Start Server

```bash
./start.sh
```

The API will be available at:
- **API:** http://localhost:8000
- **Docs:** http://localhost:8000/docs
- **Health:** http://localhost:8000/health

---

## 🧪 Test the API

### 1. Register a User

```bash
curl -X POST "http://localhost:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@nutrify.ai",
    "password": "SecurePass123!",
    "name": "Test User"
  }'
```

### 2. Login

```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@nutrify.ai",
    "password": "SecurePass123!"
  }'
```

You'll receive:
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

### 3. Access Protected Routes (Coming Soon)

```bash
# Use the access_token from login
curl -X GET "http://localhost:8000/api/v1/users/me" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 🛠️ Development Workflow

### Install Dependencies

```bash
# Production dependencies
uv pip install -e .

# Development dependencies
uv pip install -e ".[dev]"
```

### Run Tests

```bash
pytest
pytest --cov=app tests/
```

### Format Code

```bash
black app/
ruff check app/ --fix
```

### Database Migrations (with Alembic)

```bash
# Install Alembic
uv pip install alembic

# Create migration
alembic revision --autogenerate -m "Add new table"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

---

## 🐳 Docker Quick Start

```bash
# Build image
docker build -t nutrify-backend .

# Run container
docker run -d \
  -p 8000:8000 \
  --env-file .env \
  --name nutrify-api \
  nutrify-backend

# View logs
docker logs -f nutrify-api
```

---

## 🔧 Troubleshooting

### Port Already in Use

```bash
# Find process using port 8000
lsof -ti:8000 | xargs kill -9

# Or use different port
uvicorn app.main:app --port 8001
```

### Database Connection Error

```bash
# Check PostgreSQL is running
pg_isready

# Check connection
psql -U postgres -c "SELECT version();"

# Restart PostgreSQL
brew services restart postgresql  # macOS
sudo systemctl restart postgresql  # Linux
```

### Redis Connection Error

```bash
# Check Redis is running
redis-cli ping

# Start Redis
brew services start redis  # macOS
sudo systemctl start redis  # Linux
redis-server  # Manual start
```

### Import Errors

```bash
# Reinstall dependencies
uv pip install -e . --force-reinstall

# Clear Python cache
find . -type d -name __pycache__ -exec rm -r {} +
find . -type f -name "*.pyc" -delete
```

---

## 📊 Monitoring

### View Logs

```bash
# Application logs (if using structlog)
tail -f logs/app.log

# Uvicorn logs
# Output in terminal by default
```

### Check Health

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "app": "Nutrify-AI",
  "version": "0.1.0",
  "environment": "development"
}
```

---

## 🔐 Security Checklist

- [x] Change `SECRET_KEY` in production
- [x] Use strong passwords for database
- [x] Enable HTTPS in production
- [ ] Set up firewall rules
- [ ] Enable rate limiting
- [ ] Configure CORS properly
- [ ] Use environment-specific configs
- [ ] Enable logging and monitoring

---

## 📦 Project Status

✅ **Completed:**
- Basic project structure
- Configuration management
- Database models (User, Profile, Plans, Progress)
- Authentication (JWT, OAuth2, Google)
- Core utilities (Security, Redis, Database)
- API documentation

⏳ **In Progress:**
- Additional API routes (Users, Nutrition, Fitness, Progress)
- LangChain AI agents
- Background tasks
- Email notifications

🔜 **Coming Soon:**
- Wearable integrations
- Payment processing (Stripe)
- Advanced analytics
- WebSocket support
- Admin dashboard

---

## 📚 Additional Resources

- **Full Documentation:** See [README.md](README.md)
- **Database Schema:** See [docs/Nutrify-AI_Database_Schema_Guide.md](../docs/Nutrify-AI_Database_Schema_Guide.md)
- **Engineering Guide:** See [docs/Nutrify-AI_Engineering_Guide.md](../docs/Nutrify-AI_Engineering_Guide.md)
- **PRD:** See [docs/Nutrify-AI_PRD.md](../docs/Nutrify-AI_PRD.md)

- **FastAPI Docs:** https://fastapi.tiangolo.com/
- **SQLAlchemy:** https://docs.sqlalchemy.org/
- **LangChain:** https://python.langchain.com/
- **uv Package Manager:** https://github.com/astral-sh/uv

---

**Happy Coding! 🚀**
