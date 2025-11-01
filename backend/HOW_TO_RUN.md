# 🚀 Nutrify-AI - Complete Setup & Run Guide

## Quick Start (Docker - Recommended)

```bash
# 1. Start database services
cd backend
docker compose up -d

# 2. Setup backend
chmod +x setup.sh start.sh
./setup.sh

# 3. Update .env with your keys
nano .env  # Add OPENAI_API_KEY and other settings

# 4. Start backend
./start.sh
```

**That's it! Backend runs at http://localhost:8000** 🎉

---

## ✅ What's Been Created

### Backend Structure
```
backend/
├── docker-compose.yml        # PostgreSQL + Redis + pgAdmin
├── pyproject.toml           # uv dependencies
├── .env.example             # Configuration template
├── setup.sh                 # Automated setup script
├── start.sh                 # Start server script
├── init_db.sh              # Database initialization
├── README.md               # Full documentation
├── QUICKSTART.md           # Quick start guide
├── DOCKER.md               # Docker detailed guide
└── app/
    ├── main.py             # FastAPI application
    ├── core/               # Config, database, security, redis
    ├── models/             # SQLAlchemy models (User, Profile, Plans, Progress)
    ├── schemas/            # Pydantic schemas (validation)
    └── api/
        ├── dependencies.py # Auth dependencies
        └── routes/
            └── auth.py     # ✅ Authentication routes (register, login, Google OAuth)
```

### ✅ Implemented Features

#### 1. **Authentication System**
- Email/password registration & login
- JWT token generation (access + refresh tokens)
- Google OAuth2 integration
- Token refresh endpoint
- Secure password hashing (bcrypt)

#### 2. **Database Models**
- **Users** - Authentication and profile
- **UserProfile** - Detailed user preferences and goals
- **NutritionPlan** & **Meal** - Weekly meal planning
- **FitnessPlan**, **Workout** & **Exercise** - Workout management
- **ProgressEntry** - Daily tracking
- **AIInsight** - AI-generated recommendations
- **ChatMessage** - AI chat history

#### 3. **Infrastructure**
- PostgreSQL with async SQLAlchemy 2.0
- Redis for caching
- Docker Compose for easy setup
- Configuration management (Pydantic Settings)
- CORS middleware
- Health check endpoints
- Structured logging

---

## 🎯 Current Status

### ✅ **Completed**
- [x] Project structure and configuration
- [x] Database schema (matches your Database Schema Guide)
- [x] Authentication endpoints (JWT + OAuth)
- [x] Core utilities (security, database, redis)
- [x] Docker setup with PostgreSQL & Redis
- [x] Setup and start scripts
- [x] Comprehensive documentation

### ⏳ **To Be Implemented** (Next Steps)
- [ ] User profile endpoints (`GET/PUT /api/v1/users/me`)
- [ ] Nutrition plan endpoints (`/api/v1/nutrition/*`)
- [ ] Fitness plan endpoints (`/api/v1/fitness/*`)
- [ ] Progress tracking endpoints (`/api/v1/progress/*`)
- [ ] AI chat endpoints (`/api/v1/ai/chat`)
- [ ] LangChain agents (nutrition, fitness, motivation)
- [ ] Background tasks (Celery)
- [ ] Email notifications
- [ ] Stripe payment integration
- [ ] Wearable integrations

---

## 📖 How to Run with uv

### Using Docker (Recommended)

```bash
cd backend

# 1. Start database services
docker compose up -d

# 2. Check services are running
docker compose ps
# Should show postgres and redis as "healthy"

# 3. Run setup
./setup.sh

# 4. Edit .env with your configuration
cp .env.example .env
nano .env
# Update: OPENAI_API_KEY, SECRET_KEY, etc.

# 5. Start backend
./start.sh
```

### Manual Setup (No Scripts)

```bash
cd backend

# Start Docker services
docker compose up -d

# Create and activate virtual environment
uv venv
source .venv/bin/activate  # macOS/Linux

# Install dependencies
uv pip install -e .

# Create .env file
cp .env.example .env
# Edit .env with your settings

# Start server
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## 🧪 Test the Backend

### 1. Check Health
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

### 2. View API Documentation
Open browser: http://localhost:8000/docs

### 3. Register a User
```bash
curl -X POST "http://localhost:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@nutrify.ai",
    "password": "SecurePass123!",
    "name": "Test User"
  }'
```

### 4. Login
```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@nutrify.ai",
    "password": "SecurePass123!"
  }'
```

You'll receive access and refresh tokens!

---

## 🐳 Docker Commands

```bash
# Start all services
docker compose up -d

# Start with pgAdmin (database UI)
docker compose --profile dev up -d

# View logs
docker compose logs -f postgres
docker compose logs -f redis

# Stop services
docker compose down

# Stop and remove data (⚠️ careful!)
docker compose down -v

# Access PostgreSQL
docker compose exec postgres psql -U nutrify_user -d nutrify_db

# Access Redis CLI
docker compose exec redis redis-cli

# Access pgAdmin
# http://localhost:5050 (email: admin@nutrify.ai, password: admin)
```

---

## 🔧 Environment Configuration

Key settings in `.env`:

```bash
# Database (Docker defaults)
DATABASE_URL=postgresql+asyncpg://nutrify_user:nutrify_password@localhost:5432/nutrify_db

# Redis
REDIS_URL=redis://localhost:6379/0

# Security (GENERATE A NEW SECRET!)
SECRET_KEY=$(openssl rand -hex 32)

# AI Features (REQUIRED for AI functionality)
OPENAI_API_KEY=sk-your-openai-api-key
LANGCHAIN_API_KEY=your-langsmith-api-key  # Optional, for tracing

# Google OAuth (Optional)
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-secret

# CORS (Frontend URL)
CORS_ORIGINS=http://localhost:5173,http://localhost:3000
```

---

## 📊 Available Endpoints

### Authentication (`/api/v1/auth`)
- ✅ `POST /register` - Register new user
- ✅ `POST /login` - Login with email/password
- ✅ `POST /google` - Login with Google OAuth
- ✅ `POST /refresh` - Refresh access token
- ✅ `POST /logout` - Logout

### Health & Docs
- ✅ `GET /health` - Health check
- ✅ `GET /docs` - Interactive API documentation
- ✅ `GET /redoc` - Alternative API docs

### To Be Implemented
- `GET /api/v1/users/me` - Get current user
- `PUT /api/v1/users/me/profile` - Update profile
- `GET /api/v1/nutrition/plans/current` - Get nutrition plan
- `POST /api/v1/nutrition/plans/generate` - Generate AI plan
- `GET /api/v1/fitness/plans/current` - Get fitness plan
- `POST /api/v1/ai/chat` - Chat with AI coach
- And more...

---

## 🛠️ Development Workflow

### Install Dev Dependencies
```bash
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

### Database Migrations
```bash
# Install Alembic
uv pip install alembic

# Create migration
alembic revision --autogenerate -m "Add new table"

# Apply migrations
alembic upgrade head
```

---

## 🔗 Connect Frontend

Update your frontend `.env`:

```env
VITE_API_URL=http://localhost:8000/api/v1
```

Frontend can now call:
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/google`

---

## 📚 Documentation Files

- **README.md** - Complete documentation
- **QUICKSTART.md** - Quick start guide
- **DOCKER.md** - Docker detailed guide
- **docs/Nutrify-AI_Database_Schema_Guide.md** - Database schema
- **docs/Nutrify-AI_Engineering_Guide.md** - Engineering architecture
- **docs/Nutrify-AI_PRD.md** - Product requirements

---

## 🎉 You're All Set!

Your FastAPI backend is now running with:
- ✅ PostgreSQL database (Docker)
- ✅ Redis cache (Docker)
- ✅ JWT authentication
- ✅ Google OAuth support
- ✅ Database models ready
- ✅ uv package manager
- ✅ Auto-reload on code changes

**Next Steps:**
1. Implement user profile endpoints
2. Add nutrition and fitness plan endpoints
3. Integrate LangChain agents for AI features
4. Connect with your frontend

**API is live at:** http://localhost:8000 🚀
**Docs available at:** http://localhost:8000/docs 📚

---

Need help? Check the documentation files or the error logs!
