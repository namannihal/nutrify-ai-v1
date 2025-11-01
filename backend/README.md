# 🚀 Nutrify-AI Backend

FastAPI backend for Nutrify-AI - An agentic AI-powered fitness and nutrition platform with LangChain agents.

## 🎯 Features

- **FastAPI** with async/await support
- **PostgreSQL** database with SQLAlchemy 2.0
- **Redis** for caching and sessions
- **JWT Authentication** with OAuth2 (Google)
- **LangChain Agents** for AI-powered recommendations
- **LangSmith** for AI observability
- **Pydantic V2** for data validation
- **uv** for fast package management

## 📋 Prerequisites

- **Docker & Docker Compose** (recommended) OR
- **PostgreSQL 14+** and **Redis 6+** (local installation)
- **Python 3.11+**
- **[uv package manager](https://github.com/astral-sh/uv)**

## 🛠️ Installation

### Option 1: Using Docker (Recommended)

#### 1. Start Database Services

```bash
cd backend

# Start PostgreSQL and Redis
docker compose up -d

# Verify services
docker compose ps
```

#### 2. Install uv

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or with pip
pip install uv
```

#### 3. Setup Backend

```bash
# Make scripts executable
chmod +x setup.sh start.sh

# Run setup (creates venv and installs dependencies)
./setup.sh
```

#### 4. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env  # or use your favorite editor
```

**Required configurations:**
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `SECRET_KEY`: Generate a secure random key
- `OPENAI_API_KEY`: Your OpenAI API key (for AI features)
- `GOOGLE_CLIENT_ID` & `GOOGLE_CLIENT_SECRET`: For Google OAuth (optional)

#### 5. Start Server

```bash
./start.sh
```

The API will be available at http://localhost:8000

---

### Option 2: Using Local PostgreSQL & Redis

#### 1. Install Dependencies

```bash
# macOS with Homebrew
brew install postgresql@15 redis

# Ubuntu/Debian
sudo apt-get install postgresql-15 redis-server

# Start services
brew services start postgresql@15  # macOS
brew services start redis
```

#### 2. Setup Database

```bash
# Create database
createdb nutrify_db

# Or with psql
psql -U postgres -c "CREATE DATABASE nutrify_db;"
```

#### 3. Install uv and Setup Backend

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Run setup
chmod +x setup.sh start.sh
./setup.sh
```

#### 4. Configure Environment

Update `.env` to match your local setup.

#### 5. Start Server

```bash
./start.sh
```

## 🚀 Running the Application

### Development Mode

```bash
# With uv (recommended)
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or with Python
python -m app.main

# Or with uvicorn directly
uvicorn app.main:app --reload
```

The API will be available at:
- API: http://localhost:8000
- Interactive docs: http://localhost:8000/docs
- Alternative docs: http://localhost:8000/redoc

### Production Mode

```bash
# Set environment to production in .env
ENVIRONMENT=production
DEBUG=False

# Run with multiple workers
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## 📁 Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application entry point
│   ├── core/                   # Core functionality
│   │   ├── config.py          # Settings and configuration
│   │   ├── database.py        # Database session management
│   │   ├── security.py        # Auth utilities
│   │   └── redis.py           # Redis client
│   ├── models/                 # SQLAlchemy models
│   │   ├── user.py            # User & Profile models
│   │   ├── nutrition.py       # Nutrition plans & meals
│   │   ├── fitness.py         # Fitness plans & workouts
│   │   └── progress.py        # Progress tracking
│   ├── schemas/                # Pydantic schemas
│   │   ├── auth.py
│   │   ├── user.py
│   │   ├── nutrition.py
│   │   ├── fitness.py
│   │   └── progress.py
│   ├── api/                    # API routes
│   │   ├── dependencies.py    # Route dependencies
│   │   └── routes/
│   │       ├── auth.py        # Authentication endpoints
│   │       ├── users.py       # User management
│   │       ├── nutrition.py   # Nutrition endpoints
│   │       ├── fitness.py     # Fitness endpoints
│   │       └── ai.py          # AI chat & insights
│   ├── agents/                 # LangChain agents
│   │   ├── orchestrator.py   # Main AI orchestrator
│   │   ├── nutrition.py       # Nutrition agent
│   │   ├── fitness.py         # Fitness agent
│   │   └── motivation.py      # Motivation agent
│   └── services/               # Business logic
│       ├── user_service.py
│       ├── plan_service.py
│       └── ai_service.py
├── tests/                      # Test files
├── pyproject.toml             # Project dependencies (uv)
├── .env.example               # Environment template
├── .gitignore
└── README.md
```

## 🔑 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login with email/password
- `POST /api/v1/auth/google` - Login with Google OAuth
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout

### Users (TODO - to be implemented)
- `GET /api/v1/users/me` - Get current user
- `PUT /api/v1/users/me` - Update user
- `GET /api/v1/users/me/profile` - Get user profile
- `PUT /api/v1/users/me/profile` - Update profile

### Nutrition (TODO - to be implemented)
- `GET /api/v1/nutrition/plans` - List nutrition plans
- `GET /api/v1/nutrition/plans/current` - Get active plan
- `POST /api/v1/nutrition/plans/generate` - Generate new plan
- `POST /api/v1/nutrition/logs` - Log meal

### Fitness (TODO - to be implemented)
- `GET /api/v1/fitness/plans` - List fitness plans
- `GET /api/v1/fitness/plans/current` - Get active plan
- `POST /api/v1/fitness/plans/generate` - Generate new plan
- `POST /api/v1/fitness/logs` - Log workout

### Progress (TODO - to be implemented)
- `GET /api/v1/progress` - Get progress history
- `POST /api/v1/progress` - Log progress entry
- `GET /api/v1/progress/stats` - Get statistics

### AI (TODO - to be implemented)
- `POST /api/v1/ai/chat` - Chat with AI coach
- `GET /api/v1/ai/insights` - Get AI insights
- `POST /api/v1/ai/analyze` - Request AI analysis

## 🧪 Testing

```bash
# Install dev dependencies
uv pip install -e ".[dev]"

# Run tests
pytest

# With coverage
pytest --cov=app tests/

# Run specific test file
pytest tests/test_auth.py
```

## 🐳 Docker Deployment

```dockerfile
# Dockerfile (to be created)
FROM python:3.11-slim

WORKDIR /app

# Install uv
RUN pip install uv

# Copy project files
COPY pyproject.toml .
COPY app/ ./app/

# Install dependencies
RUN uv pip install --system -e .

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```bash
# Build and run
docker build -t nutrify-backend .
docker run -p 8000:8000 --env-file .env nutrify-backend
```

## 📊 Database Migrations

Using Alembic for database migrations:

```bash
# Install Alembic
uv pip install alembic

# Initialize (already done)
# alembic init migrations

# Create migration
alembic revision --autogenerate -m "Description of changes"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

## 🔧 Development Tools

```bash
# Format code with black
black app/

# Lint with ruff
ruff check app/

# Type checking with mypy
mypy app/

# Run pre-commit hooks
pre-commit install
pre-commit run --all-files
```

## 🌐 Environment Variables

See `.env.example` for all configuration options.

### Critical Settings

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | ✅ |
| `REDIS_URL` | Redis connection string | ✅ |
| `SECRET_KEY` | JWT secret key | ✅ |
| `OPENAI_API_KEY` | OpenAI API key for AI features | ✅ |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | Optional |
| `LANGCHAIN_API_KEY` | LangSmith API key for tracing | Optional |

## 📈 Performance Optimization

- **Connection Pooling**: PostgreSQL pool size configured in settings
- **Redis Caching**: Frequently accessed data cached with TTL
- **Async I/O**: All database operations are asynchronous
- **GZip Compression**: Automatic response compression
- **Database Indexing**: Optimized indexes on frequently queried fields

## 🔒 Security Features

- **JWT Authentication**: Secure token-based auth
- **Password Hashing**: Bcrypt for password security
- **OAuth2 Support**: Google authentication
- **CORS Configuration**: Configurable origins
- **SQL Injection Protection**: SQLAlchemy parameterized queries
- **Rate Limiting**: (TODO - implement with Redis)

## 🐛 Debugging

```bash
# Run with debug logging
LOG_LEVEL=DEBUG uvicorn app.main:app --reload

# Python debugger
import pdb; pdb.set_trace()

# Or use breakpoint()
breakpoint()
```

## 📝 Next Steps

### Immediate TODOs:
1. ✅ Basic project structure and configuration
2. ✅ Authentication endpoints
3. ⏳ User and profile endpoints
4. ⏳ Nutrition plan endpoints
5. ⏳ Fitness plan endpoints
6. ⏳ Progress tracking endpoints
7. ⏳ AI agent implementation (LangChain)
8. ⏳ Background tasks (Celery)
9. ⏳ Email notifications
10. ⏳ Payment integration (Stripe)

### Advanced Features:
- [ ] Wearable device integrations
- [ ] Real-time notifications via WebSockets
- [ ] Advanced analytics and reporting
- [ ] Multi-language support
- [ ] Admin dashboard endpoints

## 🤝 Contributing

1. Create a feature branch
2. Make changes
3. Run tests and linters
4. Submit pull request

## 📄 License

Proprietary - Nutrify-AI

## 🆘 Support

For issues and questions:
- GitHub Issues: [repository]/issues
- Email: support@nutrify.ai

---

**Built with ❤️ using FastAPI, LangChain, and uv**
