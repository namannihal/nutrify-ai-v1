# AI Agent Schema Adaptation - Fix Summary

## Problem
Docker container was in restart loop due to model import errors. The AI agents (NutritionAgent, FitnessAgent) were expecting nested model structures (`DailyMeal`, `DailyWorkout`) that didn't exist in the actual database schema.

## Root Cause
**Schema Mismatch:** Agents were designed for nested structure (matching Flutter models) but database uses flat structure with `day_of_week` and type columns.

### Expected (Agent Design)
```python
DailyMeal(
    day="monday",
    breakfast=[Meal, Meal],
    lunch=[Meal],
    dinner=[Meal],
    snacks=[Meal]
)
```

### Actual (Database Schema)
```python
Meal(
    day_of_week=0,  # 0=Monday, 1=Tuesday, etc.
    meal_type="breakfast",
    meal_order=1,
    # ... all meal fields
)
```

## Solution Applied
**Option 1:** Adapted agents to work with existing flat database schema (less disruptive than migrating database)

## Files Fixed

### 1. `backend/app/ai/nutrition_agent.py`
**Changes:**
- ✅ Removed `DailyMeal` from imports
- ✅ Updated `generate_weekly_plan()` to create `NutritionPlan` first, then add 28 individual `Meal` objects
- ✅ Changed `_generate_weekly_meals()` return type from `List[DailyMeal]` to `List[Meal]`
- ✅ Rewrote `_build_nutrition_system_prompt()` to generate 28 flat meals instead of 7 nested days
  - JSON format now: `[{day: 0, meal_type: "breakfast", meal_order: 1, ...}, ...]`
- ✅ Completely rewrote `_parse_meal_response()` to create `Meal` objects from flat JSON array
- ✅ Completely rewrote `_generate_fallback_meals()` to create 28 simple `Meal` objects

**Key Changes:**
```python
# OLD (broken)
DailyMeal(day="monday", breakfast=[...], lunch=[...])

# NEW (working)
Meal(day_of_week=0, meal_type="breakfast", meal_order=1, name="...", calories=500, ...)
```

### 2. `backend/app/ai/fitness_agent.py`
**Changes:**
- ✅ Removed `DailyWorkout` from imports
- ✅ Changed `WorkoutPlan` to `FitnessPlan` (correct model name)
- ✅ Updated `generate_weekly_plan()` to create `FitnessPlan` first, then add `Workout` objects
- ✅ Updated system prompt to generate workouts with `day_of_week` as integer (0-6)
- ✅ Rewrote `_parse_workout_response()` to create `Workout` and `Exercise` objects correctly
- ✅ Rewrote `_generate_fallback_workouts()` to create 7 workouts with proper day_of_week values

### 3. `backend/app/memory/hierarchical_memory.py`
**Changes:**
- ✅ Fixed import: `WorkoutPlan` → `FitnessPlan`
- ✅ Updated all SQL queries to use `FitnessPlan` model
- ✅ Updated comment references

### 4. `backend/app/api/routes/ai.py`
**Changes:**
- ✅ Removed duplicate/orphaned code from old sample implementation
- ✅ Fixed syntax error (unmatched closing brace)

## Database Schema Reference

### NutritionPlan Table
```sql
- id: UUID (PK)
- user_id: UUID (FK to users)
- week_start: DATE
- week_end: DATE
- daily_calories: INTEGER
- protein_grams: INTEGER
- carbs_grams: INTEGER
- fat_grams: INTEGER
- created_by_ai: BOOLEAN (default: true)
- ai_model_version: VARCHAR
```

### Meal Table
```sql
- id: UUID (PK)
- plan_id: UUID (FK to nutrition_plans)
- day_of_week: INTEGER (0=Monday, 6=Sunday)
- meal_type: VARCHAR (breakfast/lunch/dinner/snack)
- meal_order: INTEGER
- name: VARCHAR
- description: TEXT
- calories: INTEGER
- protein_grams: FLOAT
- carbs_grams: FLOAT
- fat_grams: FLOAT
- fiber_grams: FLOAT (nullable)
- ingredients: JSONB
- instructions: TEXT
- prep_time_minutes: INTEGER
- cook_time_minutes: INTEGER
- cuisine_type: VARCHAR
- dietary_tags: ARRAY[TEXT]
```

### FitnessPlan Table
```sql
- id: UUID (PK)
- user_id: UUID (FK to users)
- week_start: DATE
- week_end: DATE
- difficulty_level: INTEGER
- focus_areas: ARRAY[TEXT]
- estimated_calories_burn: INTEGER
- created_by_ai: BOOLEAN (default: true)
- ai_model_version: VARCHAR
```

### Workout Table
```sql
- id: UUID (PK)
- plan_id: UUID (FK to fitness_plans)
- day_of_week: INTEGER (0-6)
- workout_type: VARCHAR (strength/cardio/flexibility/rest/mixed)
- name: VARCHAR
- description: TEXT
- duration_minutes: INTEGER
- estimated_calories: INTEGER
- intensity_level: INTEGER (1-5)
```

### Exercise Table
```sql
- id: UUID (PK)
- workout_id: UUID (FK to workouts)
- name: VARCHAR
- description: TEXT
- sets: INTEGER
- reps: VARCHAR (e.g., "8-10" or "to failure")
- rest_seconds: INTEGER
- muscle_groups: ARRAY[TEXT]
- equipment_needed: VARCHAR (nullable)
- video_url: VARCHAR (nullable)
```

## AI Prompt Changes

### Nutrition Agent System Prompt (Updated)
```
Generate a 7-day personalized meal plan as a JSON array of 28 meals 
(4 meals per day × 7 days). Each meal must include:

- day: integer 0-6 (0=Monday, 6=Sunday)
- meal_type: "breakfast", "lunch", "dinner", or "snack"
- meal_order: integer (1 for single meal per type, or 1,2,3 for multiple)
- name: string
- description: string
- calories: integer
- protein_grams: float
- carbs_grams: float
- fat_grams: float
- fiber_grams: float (optional)
- ingredients: object {ingredient_name: quantity_with_unit}
- instructions: string
- prep_time_minutes: integer
- cook_time_minutes: integer
- cuisine_type: string (optional)
- dietary_tags: array of strings
```

### Fitness Agent System Prompt (Updated)
```
Generate 7 workouts (one per day). Each workout must include:

- day_of_week: integer 0-6 (0=Monday, 6=Sunday)
- name: string
- workout_type: string (strength/cardio/flexibility/rest/mixed)
- duration_minutes: integer
- description: string
- estimated_calories: integer (optional)
- intensity_level: integer 1-5 (optional)
- exercises: array of exercise objects

Each exercise must include:
- name: string
- description: string
- sets: integer
- reps: string (e.g., "8-10")
- rest_seconds: integer
- muscle_groups: array of strings
- equipment_needed: string or null
```

## Verification Steps

### 1. Check Docker Container
```bash
cd backend
docker compose logs backend --tail=30
# Should see: "INFO: Uvicorn running on http://0.0.0.0:8000"
```

### 2. Test Health Endpoint
```bash
curl http://localhost:8000/health
# Should return: {"status": "healthy", "app": "Nutrify-AI", ...}
```

### 3. Test API Endpoints
```bash
# Login to get token
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password"}'

# Generate nutrition plan (requires auth token)
curl -X POST http://localhost:8000/api/v1/nutrition/generate \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

### 4. Verify Database
```sql
-- Check created nutrition plans
SELECT id, user_id, week_start, daily_calories, created_by_ai 
FROM nutrition_plans 
WHERE created_by_ai = true 
ORDER BY created_at DESC 
LIMIT 1;

-- Check created meals (should be 28 meals)
SELECT day_of_week, meal_type, name, calories 
FROM meals 
WHERE plan_id = '<plan_id>' 
ORDER BY day_of_week, meal_order;
```

## Result
✅ **Docker container now starts successfully**  
✅ **FastAPI server running on port 8000**  
✅ **All imports resolved**  
✅ **AI agents ready to generate plans**  
✅ **Database schema matches agent output**

## Next Steps

1. **Test AI Generation from Flutter:**
   - Open Flutter app
   - Navigate to dashboard
   - Click "Generate your personalized meal plan"
   - Should create 28 meals in database
   - Should display in nutrition plan screen

2. **Test Workout Generation:**
   - Click "Get your personalized workout plan"
   - Should create 7 workouts with exercises
   - Should display in fitness plan screen

3. **Monitor Costs:**
   - Check OpenAI usage at https://platform.openai.com/usage
   - Each plan generation: ~5k context + ~2k output = ~$0.03
   - Check LangSmith traces at https://smith.langchain.com/

4. **Test Memory System:**
   - Generate plans for multiple weeks
   - Verify AI adapts based on progress entries
   - Check context token usage (should be ~6-10k vs ~15k+ without memory)

## Configuration Required

### Environment Variables (.env)
```bash
# OpenAI
OPENAI_API_KEY=sk-...

# LangChain/LangSmith (optional - for tracing)
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=lsv2_...
LANGCHAIN_PROJECT=nutrify-ai

# AI Settings
AI_MODEL=gpt-4-turbo-preview
AI_TEMPERATURE=0.7
```

## Import Reference
```python
# Correct imports for AI agents
from app.models.nutrition import NutritionPlan, Meal
from app.models.fitness import FitnessPlan, Workout, Exercise
from app.models.progress import ProgressEntry, AIInsight, ChatMessage
from app.models.user import User, UserProfile
```

## Troubleshooting

### If container still crashes:
```bash
# Clear all containers and rebuild
docker compose down -v
docker compose build --no-cache
docker compose up -d

# Check logs
docker compose logs backend --follow
```

### If AI generation fails:
1. Check OpenAI API key is valid
2. Check database connection (verify DATABASE_URL)
3. Check logs for specific error: `docker compose logs backend | grep ERROR`
4. Verify user has completed onboarding (profile exists)

### If plans don't display in Flutter:
1. Check API returns 200: `curl -X GET http://localhost:8000/api/v1/nutrition/current-plan -H "Authorization: Bearer <token>"`
2. Verify plan_id exists in database
3. Check Flutter console for API errors
4. Verify date filtering logic in API (should return current week's plan)

## Files Modified
- ✅ `backend/app/ai/nutrition_agent.py` (~400 lines)
- ✅ `backend/app/ai/fitness_agent.py` (~300 lines)
- ✅ `backend/app/memory/hierarchical_memory.py` (import fix)
- ✅ `backend/app/api/routes/ai.py` (syntax fix)

## No Changes Needed
- ✅ Database schema (existing schema is correct)
- ✅ API routes (already correctly integrated)
- ✅ Flutter app (already expects API format)
- ✅ Alembic migrations (schema was always correct)

---

**Status:** ✅ **RESOLVED** - Container running, agents operational, ready for end-to-end testing
**Date:** December 7, 2024
**Resolution Time:** ~45 minutes (schema adaptation + fixes)
