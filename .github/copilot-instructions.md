--- 
applyTo: '/Users/namannihal/Desktop/nutrify-v2/**'
---

# Nutrify-AI Development Guide for AI Agents

## Product Overview
Nutrify-AI is an **agentic AI-powered fitness and nutrition platform** that replaces traditional coaches with autonomous AI agents. The system analyzes user biometrics, generates adaptive weekly plans (nutrition + workouts), and operates in a continuous feedback loop (Analyze → Adapt → Act) using LangChain + LangSmith orchestration.

**Key Differentiator:** No direct AI chat—all personalization happens via background agents that autonomously adapt plans weekly based on progress tracking.

## Architecture Overview

### Tech Stack
- **Backend:** FastAPI + SQLAlchemy 2.0 (async) + Alembic migrations + PostgreSQL + Redis
- **AI Layer:** LangChain agents (NutritionAgent, FitnessAgent, MotivationAgent) + LangSmith tracing + OpenAI GPT-4
- **Frontend (Web):** React + TypeScript + shadcn/ui + TailwindCSS + React Query (PWA-ready)
- **Frontend (Mobile):** Flutter 3.10+ with Riverpod state management + GoRouter + Dio HTTP client
- **Infrastructure:** Docker + Azure Container Apps + Terraform + Supabase (managed Postgres)

### Service Boundaries
```
flutter_app/ (Mobile) ──┐
frontend/ (Web PWA) ────┼→ backend/app/ (FastAPI) → AI agents → PostgreSQL/Redis
                        │                  ↓
                        └────────────> LangSmith tracing
```

## Backend Structure (`backend/app/`)

**Critical folders:**
- `api/routes/` — API endpoints (auth, users, nutrition, fitness, progress, ai)
- `models/` — SQLAlchemy ORM models (user, nutrition, fitness, progress)
- `schemas/` — Pydantic request/response schemas
- `core/` — Config (`config.py`), database (`database.py`), security (`security.py`), Redis (`redis.py`)
- `api/dependencies.py` — FastAPI dependencies (auth, DB sessions)

**Pattern:** All imports are absolute from `app/` (e.g., `from app.models.user import User`). No relative imports.

## Frontend Structure

### Web (`frontend/src/`)
- `pages/` — Routes (Landing, Onboarding, NutritionPlan, FitnessPlan, Progress, AIChat)
- `components/` — shadcn/ui primitives + custom components
- `contexts/` — React Context (AuthContext for JWT)
- `services/` — API client functions (axios/fetch)
- `hooks/` — Custom React hooks

**Pattern:** Uses React Query for server state. Auth state stored in `AuthContext` + `localStorage`.

### Mobile (`flutter_app/lib/`)
- `screens/` — UI screens organized by feature (auth, home, nutrition, fitness, progress, ai, profile)
- `providers/` — Riverpod state management (auth_provider, nutrition_provider, fitness_provider, progress_provider, ai_provider)
- `services/` — API client (`api_service.dart` with singleton pattern)
- `models/` — Data models with JSON serialization (`*.g.dart` generated via `build_runner`)
- `router/` — GoRouter navigation with auth guards and redirect logic
- `theme/` — Material 3 theme matching web brand colors (Blue-600 primary, Emerald-500 secondary)
- `widgets/` — Reusable UI components

**Patterns:**
- **State:** Riverpod with `StateNotifier` for complex state (e.g., `AuthNotifier` in `auth_provider.dart`)
- **Navigation:** GoRouter with redirect guards checking `isLoggedIn` && `hasCompletedOnboarding`
- **API:** Singleton `ApiService` with JWT token management via `flutter_secure_storage`
- **Models:** JSON serialization with `json_annotation` + `build_runner` (run `flutter pub run build_runner build`)
- **API Base URL:** Uses `10.0.2.2:8000` for Android emulator (host machine's localhost)

## Developer Workflows

### Running the Backend
```bash
cd backend

# Start services (PostgreSQL + Redis)
docker compose up -d

# Run FastAPI dev server
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
# OR (if venv activated): uvicorn app.main:app --reload
```

**Note:** Always run from `backend/` directory. Uses `uv` for package management.

### Running the Flutter App
```bash
cd flutter_app

# Get dependencies
flutter pub get

# Generate JSON serialization code (after model changes)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on emulator/device
flutter run

# Hot reload in terminal: press 'r'
# Hot restart: press 'R'
# Quit: press 'q'
```

**iOS Simulator:** Open via Xcode or `open -a Simulator`  
**Android Emulator:** Launch via Android Studio or `emulator -avd <name>`  
**Chrome (web):** `flutter run -d chrome` (for quick UI testing only)

### Running the Web Frontend
```bash
cd frontend

# Install dependencies
pnpm install

# Start dev server
pnpm dev  # Runs on http://localhost:5173

# Build for production
pnpm build
```

### Database Migrations
```bash
cd backend

# Create new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

**Pattern:** All models inherit from `app.core.database.Base`. Use UUID primary keys (`uuid4()`). Timestamps use `func.now()`.

### Environment Configuration
- **Location:** `backend/.env` (git-ignored)
- **Required keys:** `DATABASE_URL`, `REDIS_URL`, `SECRET_KEY`, `OPENAI_API_KEY`, `LANGCHAIN_API_KEY`
- **Config class:** `app.core.config.Settings` (Pydantic BaseSettings)

## Critical Patterns

### Authentication Flow
1. JWT tokens via `app.core.security` (encode/decode with HS256)
2. OAuth2 (Google) via `app.api.routes.auth`
3. Protected routes use `Depends(get_current_user)` from `app.api.dependencies`
4. Password hashing with `passlib[bcrypt]`

Example protected endpoint:
```python
from app.api.dependencies import get_current_user
from app.models.user import User

@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
```

### Async Database Sessions
```python
from app.core.database import get_db
from sqlalchemy.ext.asyncio import AsyncSession

@router.get("/users/{user_id}")
async def get_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
```

**Always use `await`** for DB queries. Session is auto-committed/rolled back.

### AI Agent Integration
- Agents defined in `app.api.routes.ai.py` (endpoints for insights, chat)
- Context management: Retrieve user profile + recent progress → pass to LangChain
- Cost optimization: Use hierarchical memory (working, episodic, semantic) per `docs/Nutrify-Ai_agent-implementation-guide`
- Observability: All agent calls traced via LangSmith (`LANGCHAIN_TRACING_V2=true`)

### Data Models
- **User:** `models/user.py` (auth + profile)
- **Nutrition:** `models/nutrition.py` (meal plans, meals, macros)
- **Fitness:** `models/fitness.py` (workout plans, exercises, sets)
- **Progress:** `models/progress.py` (daily logs, AI insights, chat messages)

All use PostgreSQL `JSONB` for flexible fields (e.g., `macros`, `meal_breakdown`).

## Deployment

### Docker Build
```bash
# Backend
cd backend
docker build -t nutrify-backend .

# Frontend  
cd frontend
docker build -t nutrify-frontend .
```

### Azure Deployment (Terraform)
```bash
cd infastructure
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply
```

Deploys to **Azure Container Apps** with managed Supabase PostgreSQL.

## Testing & Debugging

### Logs
- Backend uses `structlog` (JSON logs)
- Check `docker compose logs -f` for local dev
- LangSmith dashboard for AI agent traces: https://smith.langchain.com/

### API Docs
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Conventions

### Naming
- **Files/folders:** `snake_case` (e.g., `user_service.py`, `nutrition_plan/`)
- **Classes:** `PascalCase` (e.g., `UserService`, `NutritionPlan`)
- **Functions/vars:** `snake_case` (e.g., `get_user_by_email`, `access_token`)

### Code Style
- **Backend:** Follow FastAPI best practices (async first, dependency injection, Pydantic schemas)
- **Frontend:** TypeScript strict mode, shadcn/ui components, functional components with hooks
- **Imports:** Always use absolute paths from `app/` or `@/` (frontend alias)

## Important Documentation
- **PRD:** `docs/Nutrify-AI_PRD.md` (product requirements)
- **Engineering:** `docs/Nutrify-AI_Engineering_Guide.md` (architecture deep-dive)
- **Database:** `docs/Nutrify-AI_Database_Schema_Guide.md` (schema design rationale)
- **AI Agents:** `docs/Nutrify-Ai_agent-implementation-guide` (context management, cost optimization)
- **Data Strategy:** `docs/Nutrify-AI_AgentConsiderations.md` (comprehensive user data collection plan)

## Common Gotchas
- **Always `cd backend/` before running backend commands** (alembic, uvicorn)
- **Database URL for Supabase:** Requires `ssl=require` in connect_args (see `app.core.database`)
- **Redis:** Required for session management—ensure it's running via `docker compose`
- **Migrations:** Run `alembic upgrade head` after pulling new changes to sync schema
- **Frontend env:** Vite requires `VITE_` prefix for env vars (e.g., `VITE_API_URL`)
- **uv package manager:** Use `uv run` for CLI commands or activate venv first (`. .venv/bin/activate`)
- **Flutter models:** After editing models with `@JsonSerializable`, run `flutter pub run build_runner build --delete-conflicting-outputs`
- **Android emulator API:** Use `10.0.2.2:8000` instead of `localhost:8000` (configured in `api_service.dart`)
- **Flutter hot reload:** Press `r` in terminal for hot reload, `R` for hot restart (faster than stopping/restarting)
