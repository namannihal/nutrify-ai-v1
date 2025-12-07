# AI Agent Execution Flow - Complete Guide

## How to Get Your Diet & Workout Plans

### 🎯 Quick Answer

**To generate your personalized diet and workout plans:**

1. **Open the Flutter app** (on iOS/Android emulator or device)
2. **Complete onboarding** if you haven't already (age, weight, goals, preferences)
3. **Navigate to the Nutrition or Fitness screen**
4. **The app will automatically call the AI agents** when you don't have a current plan
5. **OR manually trigger generation** via API (explained below)

---

## 📱 Current Implementation: Manual Flow

### Nutrition Plan Generation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Flutter App (User)                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. User opens Nutrition screen                                │
│     └─> lib/screens/nutrition/nutrition_plan_screen.dart       │
│                                                                 │
│  2. NutritionProvider.loadCurrentPlan() called                 │
│     └─> lib/providers/nutrition_provider.dart                  │
│         └─> Calls: _apiService.getCurrentNutritionPlan()       │
│                                                                 │
│  3. API Request: GET /api/v1/nutrition/current-plan            │
│     └─> lib/services/api_service.dart                          │
│         └─> Returns: NutritionPlan or 404 if none exists       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP Request
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Backend API (FastAPI)                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  4. GET /api/v1/nutrition/current-plan                         │
│     └─> backend/app/api/routes/nutrition.py                    │
│         └─> Queries database for most recent plan              │
│         └─> Returns plan + 28 meals OR 404 error               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ If 404 (no plan exists)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ User Action Required: Generate New Plan                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Currently: No automatic generation button in UI                │
│                                                                 │
│  Options to trigger generation:                                │
│  ┌────────────────────────────────────────────────────────────┐│
│  │ A) Call API manually (see below)                          ││
│  │ B) Add button to Flutter UI (recommended - see fixes)     ││
│  │ C) Auto-generate on first app launch (see fixes)          ││
│  └────────────────────────────────────────────────────────────┘│
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 How to Trigger AI Agent Execution RIGHT NOW

### Option A: Using cURL (Manual API Call)

```bash
# 1. Login to get auth token
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your_email@example.com",
    "password": "your_password"
  }'

# Response contains: {"access_token": "eyJ...", "token_type": "bearer"}

# 2. Generate nutrition plan using AI agent
curl -X POST http://localhost:8000/api/v1/nutrition/generate \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# This calls NutritionAgent.generate_weekly_plan()
# Creates 28 meals in database (4 per day × 7 days)
# Returns complete plan with all meals

# 3. Generate fitness plan using AI agent
curl -X POST http://localhost:8000/api/v1/fitness/generate \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# This calls FitnessAgent.generate_weekly_plan()
# Creates 7 workouts with exercises in database
# Returns complete plan with all workouts
```

### Option B: Using Flutter (After Adding Button)

After implementing the UI fix below, users can:

```dart
// In Flutter app - anywhere with access to providers
final nutritionProvider = ref.read(nutritionProvider.notifier);
await nutritionProvider.generateNewPlan(); // Calls API endpoint

final fitnessProvider = ref.read(fitnessProvider.notifier);
await fitnessProvider.generateNewPlan(); // Calls API endpoint
```

---

## 🚀 AI Agent Execution Flow (Detailed)

### When POST /api/v1/nutrition/generate is Called

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. API Endpoint Receives Request                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  File: backend/app/api/routes/nutrition.py                     │
│  Function: generate_nutrition_plan()                           │
│                                                                 │
│  async def generate_nutrition_plan(                            │
│      current_user: User = Depends(get_current_user),           │
│      db: AsyncSession = Depends(get_db)                        │
│  ):                                                             │
│      # Initialize AI agent                                     │
│      agent = NutritionAgent(db)                                │
│                                                                 │
│      # Generate plan using AI ← THIS IS WHERE AI IS CALLED     │
│      plan = await agent.generate_weekly_plan(current_user)     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. NutritionAgent.generate_weekly_plan() Executes              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  File: backend/app/ai/nutrition_agent.py                       │
│                                                                 │
│  Step 1: Retrieve user context (memory system)                │
│    └─> HierarchicalMemory.get_user_context()                  │
│        ├─> Gets user profile (age, goals, preferences)         │
│        ├─> Gets recent nutrition plans (last 4 weeks)          │
│        ├─> Gets progress entries (weight, measurements)        │
│        └─> Returns ~6-10k tokens (vs 15k+ without memory)      │
│                                                                 │
│  Step 2: Calculate macro targets                              │
│    └─> _calculate_macro_targets()                             │
│        ├─> BMR calculation (age, weight, height, sex)          │
│        ├─> Activity level multiplier                           │
│        ├─> Goal adjustment (lose/gain/maintain)                │
│        └─> Returns: calories, protein, carbs, fat              │
│                                                                 │
│  Step 3: Generate meals using OpenAI GPT-4                    │
│    └─> _generate_weekly_meals()                               │
│        ├─> Builds system prompt (expert nutritionist)          │
│        ├─> Builds user prompt with context                     │
│        ├─> Calls: ChatOpenAI.ainvoke() ← OPENAI API CALL      │
│        │   Model: gpt-4-turbo-preview                          │
│        │   Temperature: 0.7                                    │
│        │   Context: ~5k tokens                                 │
│        │   Expected output: ~2k tokens (28 meals JSON)         │
│        │   Cost: ~$0.03 per generation                         │
│        └─> Returns: AI-generated JSON array of 28 meals        │
│                                                                 │
│  Step 4: Parse AI response                                    │
│    └─> _parse_meal_response()                                 │
│        ├─> Extracts JSON from response                         │
│        ├─> Creates Meal objects for each meal                  │
│        └─> Returns: List[Meal] (28 meal objects)               │
│                                                                 │
│  Step 5: Save to database                                     │
│    └─> Creates NutritionPlan in database                       │
│    └─> Adds 28 Meal objects linked to plan                     │
│    └─> Commits transaction                                     │
│                                                                 │
│  Step 6: Update memory                                        │
│    └─> Stores episode in memory system                         │
│        └─> "nutrition_plan_generated" event                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Return Plan to Flutter App                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Response JSON:                                                │
│  {                                                             │
│    "id": "uuid",                                               │
│    "user_id": "uuid",                                          │
│    "week_start": "2024-12-09",                                 │
│    "week_end": "2024-12-15",                                   │
│    "daily_calories": 2319,                                     │
│    "protein_grams": 180,                                       │
│    "carbs_grams": 250,                                         │
│    "fat_grams": 70,                                            │
│    "meals": [                                                  │
│      {                                                         │
│        "day": 0, // Monday                                     │
│        "breakfast": [{...meal data...}],                       │
│        "lunch": [{...meal data...}],                           │
│        "dinner": [{...meal data...}],                          │
│        "snacks": [{...meal data...}]                           │
│      },                                                        │
│      // ... 6 more days                                        │
│    ]                                                           │
│  }                                                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Fitness Agent Flow (Similar Process)

```
POST /api/v1/fitness/generate
  └─> FitnessAgent.generate_weekly_plan()
      ├─> Gets user context (fitness level, goals, equipment)
      ├─> Calls OpenAI GPT-4 to generate 7 workouts
      ├─> Parses response into Workout + Exercise objects
      ├─> Saves to database
      └─> Returns FitnessPlan with 7 days of workouts
```

---

## ⚠️ Current Issue: Missing UI Trigger

### Problem

The Flutter app **does not automatically generate a plan** when none exists. Users see:

```
"No nutrition plan found. Please generate one first."
```

But there's **no button in the UI** to trigger generation!

### Solution: Add Generate Button to Flutter

Update the nutrition and fitness screens to show a "Generate Plan" button when no plan exists.

---

## 🔨 Recommended Fix: Add Generate Plan Button

### 1. Update Nutrition Plan Screen

**File:** `flutter_app/lib/screens/nutrition/nutrition_plan_screen.dart`

Add this after the empty state message:

```dart
// Around line 180, replace the empty message with:

if (nutritionState.currentPlan == null) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Nutrition Plan Found',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Generate your personalized meal plan powered by AI',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Generate plan using AI
              final nutritionNotifier = ref.read(nutritionProvider.notifier);
              final success = await nutritionNotifier.generateNewPlan();
              
              // Close loading
              if (context.mounted) {
                Navigator.of(context).pop();
              }

              // Show result
              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI meal plan generated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(nutritionState.error ?? 'Failed to generate plan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate AI Meal Plan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 2. Update Fitness Plan Screen (Similar Pattern)

**File:** `flutter_app/lib/screens/fitness/fitness_plan_screen.dart`

Add the same pattern:

```dart
if (fitnessState.currentPlan == null) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ... same empty state design ...
        ElevatedButton.icon(
          onPressed: () async {
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            // Generate plan using AI
            final fitnessNotifier = ref.read(fitnessProvider.notifier);
            final success = await fitnessNotifier.generateNewPlan();
            
            // Close loading and show result
            // ... same pattern as nutrition ...
          },
          icon: const Icon(Icons.fitness_center),
          label: const Text('Generate AI Workout Plan'),
        ),
      ],
    ),
  );
}
```

### 3. Update Fitness Provider (Add generateNewPlan method)

**File:** `flutter_app/lib/providers/fitness_provider.dart`

```dart
Future<bool> generateNewPlan() async {
  try {
    state = state.copyWith(isLoading: true, error: null);
    final plan = await _apiService.generateFitnessPlan();
    state = state.copyWith(currentPlan: plan, isLoading: false);
    return true;
  } catch (e) {
    state = state.copyWith(
      error: e.toString(),
      isLoading: false,
    );
    return false;
  }
}
```

### 4. Add generateFitnessPlan to API Service

**File:** `flutter_app/lib/services/api_service.dart`

```dart
Future<FitnessPlan> generateFitnessPlan() async {
  final response = await _makeRequest<Map<String, dynamic>>(
    'POST',
    '/fitness/generate',
  );
  return FitnessPlan.fromJson(response);
}
```

---

## 🎯 Alternative: Auto-Generate on First Launch

Add this to the onboarding completion flow:

**File:** `flutter_app/lib/screens/onboarding/onboarding_screen.dart`

After completing onboarding:

```dart
// After successful profile creation
final nutritionNotifier = ref.read(nutritionProvider.notifier);
final fitnessNotifier = ref.read(fitnessProvider.notifier);

// Generate both plans automatically
await Future.wait([
  nutritionNotifier.generateNewPlan(),
  fitnessNotifier.generateNewPlan(),
]);

// Then navigate to dashboard
context.go('/dashboard');
```

---

## 📊 Database Verification

### Check if Plans Were Generated

```sql
-- Check nutrition plans
SELECT 
  id, 
  user_id, 
  week_start, 
  daily_calories, 
  created_by_ai,
  created_at
FROM nutrition_plans
WHERE created_by_ai = true
ORDER BY created_at DESC
LIMIT 5;

-- Check meals (should be 28 per plan)
SELECT 
  COUNT(*) as meal_count,
  day_of_week,
  meal_type
FROM meals
WHERE plan_id = '<your_plan_id>'
GROUP BY day_of_week, meal_type
ORDER BY day_of_week, meal_type;

-- Check fitness plans
SELECT 
  id,
  user_id,
  week_start,
  difficulty_level,
  created_by_ai,
  created_at
FROM fitness_plans
WHERE created_by_ai = true
ORDER BY created_at DESC
LIMIT 5;

-- Check workouts (should be 7 per plan)
SELECT 
  id,
  day_of_week,
  name,
  workout_type,
  duration_minutes
FROM workouts
WHERE plan_id = '<your_plan_id>'
ORDER BY day_of_week;
```

---

## 🔍 Monitoring & Debugging

### Check Agent Execution Logs

```bash
# Watch backend logs in real-time
docker compose logs backend --follow

# Filter for AI-related logs
docker compose logs backend | grep -i "agent\|openai\|generating"
```

### Check OpenAI API Usage

Visit: https://platform.openai.com/usage

**Expected costs per generation:**
- Nutrition plan: ~5k input + ~2k output = **~$0.03**
- Fitness plan: ~4k input + ~1.5k output = **~$0.02**
- Total per user: **~$0.05** for both plans

### Check LangSmith Traces (if enabled)

Visit: https://smith.langchain.com/

Shows:
- Full conversation flow
- Token counts
- Latency metrics
- Error traces
- Cost per request

---

## 📝 Summary

### Current State

✅ **Backend AI agents are fully functional**
- NutritionAgent generates 28 meals via OpenAI GPT-4
- FitnessAgent generates 7 workouts via OpenAI GPT-4
- Memory system optimizes context to reduce costs
- All code adapted to work with existing database schema

❌ **Flutter UI missing trigger button**
- No automatic generation on first launch
- No "Generate Plan" button when plan is missing
- Users must manually call API via cURL

### To Get Your Diet & Workout Plans NOW

**Quick Test (Manual):**
```bash
# 1. Get auth token
TOKEN=$(curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}' \
  | jq -r '.access_token')

# 2. Generate nutrition plan
curl -X POST http://localhost:8000/api/v1/nutrition/generate \
  -H "Authorization: Bearer $TOKEN"

# 3. Generate fitness plan
curl -X POST http://localhost:8000/api/v1/fitness/generate \
  -H "Authorization: Bearer $TOKEN"

# 4. Open Flutter app - plans will now display!
```

**Permanent Fix (Recommended):**
1. Add "Generate Plan" buttons to nutrition and fitness screens
2. OR auto-generate on onboarding completion
3. Implement the code changes above

### Next Action Items

1. ✅ **Test manual API call** - Verify agents work end-to-end
2. 🔲 **Add UI buttons** - Let users trigger from Flutter app
3. 🔲 **Test full flow** - Onboarding → Auto-generate → Display
4. 🔲 **Monitor costs** - Track OpenAI usage and optimize prompts
5. 🔲 **Add weekly regeneration** - Auto-generate new plans each week

---

**File Location:** `/Users/namannihal/Desktop/nutrify-v2/docs/AI_AGENT_EXECUTION_FLOW.md`
