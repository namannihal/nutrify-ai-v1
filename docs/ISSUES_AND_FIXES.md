# Issues Identified & Fixes

## Issue #1: Initial Profile Creation Takes 2-3 Seconds

**Problem**: First PUT request to create user profile is slow
**Impact**: Poor UX, user waits with no feedback

**Root Cause**: Database writes + profile setup

**Solution**: Add "Creating Your Profile" loading screen

**Files to Update**:
- `flutter_app/lib/screens/auth/onboarding_screen.dart` - Add loading state
- `flutter_app/lib/providers/auth_provider.dart` - Show progress indicators

**Implementation**:
```dart
// Show loading overlay with message
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Creating your profile...'),
      ],
    ),
  ),
);
```

---

## Issue #2: AI Meal Plan Generation Problems

### Problem 2a: Generic/Vague Plans
**Symptom**: Always generates same meals (Oatmeal, Grilled Chicken, Salmon)
**Root Cause**: AI response JSON parsing fails, falling back to `_generate_fallback_meals()`

**Location**: `backend/app/ai/nutrition_agent.py:289-292`

```python
except json.JSONDecodeError as e:
    # Fallback: generate simple plan
    logger.error(f"Failed to parse AI response as JSON: {e}")
    return self._generate_fallback_meals(targets)  # <-- THIS IS EXECUTING
```

### Problem 2b: Takes 20-25 Seconds
**Root Cause**: LangChain + OpenAI API call is slow

**Current Flow**:
1. User clicks "Generate Plan"
2. Backend calls OpenAI API (10-15 seconds)
3. Parses response (fails)
4. Returns fallback plan
5. Total: 20-25 seconds

### Solutions:

#### Fix 1: Improve AI Response Parsing (Immediate Fix)
The AI is likely returning valid JSON but in a format we're not handling correctly.

**Update `backend/app/ai/nutrition_agent.py`**:

```python
async def _parse_meal_response(
    self,
    response: str,
    targets: Dict[str, int]
) -> List[Meal]:
    """Parse AI response into Meal objects"""
    import json
    import logging
    import re

    logger = logging.getLogger(__name__)
    logger.info(f"AI Response length: {len(response)} chars")
    logger.info(f"Full AI Response: {response}")  # Log FULL response

    # Try multiple extraction methods
    json_str = response.strip()

    # Method 1: Extract from markdown code blocks
    if "```json" in json_str:
        json_str = re.search(r'```json\s*(\[.*?\])\s*```', json_str, re.DOTALL)
        if json_str:
            json_str = json_str.group(1)
    elif "```" in json_str:
        json_str = re.search(r'```\s*(\[.*?\])\s*```', json_str, re.DOTALL)
        if json_str:
            json_str = json_str.group(1)

    # Method 2: Find JSON array in text
    if isinstance(json_str, str) and not json_str.startswith('['):
        match = re.search(r'\[.*\]', json_str, re.DOTALL)
        if match:
            json_str = match.group(0)

    try:
        meals_data = json.loads(json_str)
        logger.info(f"Successfully parsed {len(meals_data)} meals from AI response")
    except json.JSONDecodeError as e:
        logger.error(f"JSON Parse Error: {e}")
        logger.error(f"Attempted to parse: {json_str[:500]}")
        # Log to help debug
        logger.error(f"Full response for debugging: {response}")
        return self._generate_fallback_meals(targets)

    # Validate meals_data is a list
    if not isinstance(meals_data, list):
        logger.error(f"Expected list, got {type(meals_data)}")
        return self._generate_fallback_meals(targets)

    meals = []
    for meal_data in meals_data:
        # ... rest of code
```

#### Fix 2: Use Structured Output (Better Fix)
Update to use OpenAI's new structured output feature:

```python
# In _generate_weekly_meals method
response = await self.llm.ainvoke(
    [SystemMessage(content=system_prompt), HumanMessage(content=user_prompt)],
    response_format={"type": "json_object"}  # Force JSON response
)
```

#### Fix 3: Add Streaming & Progress (UX Fix)
Show progress to user while AI generates:

**Backend**: Add Server-Sent Events (SSE)
```python
from fastapi.responses import StreamingResponse

@router.post("/generate-stream")
async def generate_nutrition_plan_stream(...):
    async def event_generator():
        yield "data: {\"status\": \"analyzing_profile\"}\n\n"
        # ... calculate targets
        yield "data: {\"status\": \"generating_meals\"}\n\n"
        # ... call AI
        yield "data: {\"status\": \"complete\", \"plan_id\": \"...\"}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")
```

#### Fix 4: Cache & Optimize
- Cache similar meal plans for same user profiles
- Use faster model (gpt-4o-mini instead of gpt-4o for meal planning)
- Pre-generate plans in background

---

## Issue #3: No Option to Log Meals Post-Generation

**Problem**: After generating meal plan, user can't log individual meals
**Impact**: Can't track what they actually ate vs what was planned

**Solution**: Add "Log This Meal" button on each meal card

**Files to Create/Update**:
1. `flutter_app/lib/screens/nutrition/meal_detail_screen.dart` - New screen for meal details
2. `flutter_app/lib/screens/nutrition/nutrition_plan_screen.dart` - Add tap to view/log meal

**Implementation**:

```dart
// In meal card widget
GestureDetector(
  onTap: () => _showMealOptions(context, meal),
  child: MealCard(meal: meal),
)

void _showMealOptions(BuildContext context, Meal meal) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.check_circle),
          title: Text('Log as Eaten'),
          onTap: () => _logMeal(meal),
        ),
        ListTile(
          leading: Icon(Icons.edit),
          title: Text('Modify & Log'),
          onTap: () => _modifyAndLog(meal),
        ),
        ListTile(
          leading: Icon(Icons.swap_horiz),
          title: Text('Suggest Alternative'),
          onTap: () => _suggestAlternative(meal),
        ),
      ],
    ),
  );
}
```

---

## Issue #4: Progress Entry Button Does Nothing

**Problem**: "Add Progress Entry" or similar button not working
**Location**: Progress screen

**Solution**: Implement progress entry creation

**Files to Update**:
- `flutter_app/lib/screens/progress/progress_screen.dart`
- `flutter_app/lib/screens/progress/add_progress_screen.dart` (create new)

**Implementation**:

```dart
// Create add_progress_screen.dart
class AddProgressScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AddProgressScreen> createState() => _AddProgressScreenState();
}

class _AddProgressScreenState extends ConsumerState<AddProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  double? _weight;
  double? _bodyFat;
  String? _notes;

  Future<void> _saveProgress() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final entry = ProgressEntry(
      entryDate: DateTime.now().toIso8601String(),
      weight: _weight,
      bodyFatPercentage: _bodyFat,
      notes: _notes,
    );

    await ref.read(apiServiceProvider).logProgress(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log Progress')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
              onSaved: (value) => _weight = double.tryParse(value ?? ''),
            ),
            // ... more fields
            ElevatedButton(
              onPressed: _saveProgress,
              child: Text('Save Progress'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Issue #5: AI Coach Not User-Specific

**Problem**: AI Coach lacks context of user's entries, goals, and history
**Impact**: Generic responses, not personalized

**Root Cause**: AI chat endpoint doesn't load user context from memory system

**Solution**: Integrate Hierarchical Memory System

**Files to Update**:
- `backend/app/ai/ai_coach.py` - Enhance with memory retrieval
- `backend/app/api/routes/ai.py` - Load user context before AI call

**Current Implementation** (likely too simple):
```python
@router.post("/chat")
async def chat_with_ai(message: str, user: User = Depends(get_current_user)):
    # Just sends message to AI without context
    response = await ai_service.chat(message)
    return response
```

**Enhanced Implementation**:

```python
# backend/app/ai/ai_coach.py
class AICoach:
    """Context-aware AI coach with memory"""

    async def chat(self, user_id: UUID, message: str, db: AsyncSession):
        # 1. Retrieve user context
        memory = HierarchicalMemory(db)
        context = await memory.get_user_context(
            user_id=user_id,
            context_type="coaching"
        )

        # 2. Get recent progress entries
        recent_progress = await db.execute(
            select(ProgressEntry)
            .where(ProgressEntry.user_id == user_id)
            .order_by(ProgressEntry.entry_date.desc())
            .limit(7)
        )
        progress_data = recent_progress.scalars().all()

        # 3. Get current goals
        user = await db.get(User, user_id)
        profile = user.profile

        # 4. Build context-aware prompt
        system_prompt = f"""You are a personalized AI fitness coach for {user.name}.

USER PROFILE:
- Primary Goal: {profile.primary_goal if profile else 'general health'}
- Activity Level: {profile.activity_level if profile else 'moderate'}
- Experience: {profile.fitness_experience if profile else 'beginner'}

RECENT PROGRESS (last 7 days):
{self._format_progress(progress_data)}

HISTORICAL CONTEXT:
{context.get('coaching_history', 'No previous coaching sessions')}

SUCCESSFUL PATTERNS:
{context.get('successful_patterns', 'Still learning user preferences')}

Based on this context, provide personalized, actionable advice."""

        # 5. Call AI with full context
        response = await self.llm.ainvoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=message)
        ])

        # 6. Store interaction in memory
        await memory.store_episode(
            user_id=user_id,
            episode_type="coaching_interaction",
            content={
                "user_message": message,
                "ai_response": response.content,
                "timestamp": datetime.utcnow().isoformat()
            }
        )

        return response.content

    def _format_progress(self, progress_entries):
        if not progress_entries:
            return "No recent progress logged"

        formatted = []
        for entry in progress_entries:
            formatted.append(
                f"- {entry.entry_date}: Weight {entry.weight}kg, "
                f"Mood {entry.mood_score}/10, Energy {entry.energy_score}/10"
            )
        return "\n".join(formatted)
```

**Updated API Route**:
```python
# backend/app/api/routes/ai.py
@router.post("/chat")
async def chat_with_ai(
    message: ChatMessage,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Chat with personalized AI coach"""
    coach = AICoach()
    response = await coach.chat(
        user_id=current_user.id,
        message=message.message,
        db=db
    )

    return ChatResponse(
        response=response,
        explanation="Response personalized based on your profile and progress"
    )
```

---

## Priority Order for Fixes

1. **HIGH**: Fix Issue #2 (AI Meal Plans) - Improves JSON parsing
2. **HIGH**: Fix Issue #5 (AI Coach Context) - Core personalization feature
3. **MEDIUM**: Fix Issue #4 (Progress Entry) - Essential functionality
4. **MEDIUM**: Fix Issue #3 (Log Meals) - User workflow completion
5. **LOW**: Fix Issue #1 (Loading Screen) - UX polish

---

## Quick Wins

### Immediate (< 1 hour):
1. Add detailed logging to see why JSON parsing fails
2. Implement progress entry form
3. Add loading spinner with message

### Short-term (1-3 hours):
1. Fix AI meal plan JSON parsing
2. Add user context to AI coach
3. Add meal logging buttons

### Long-term (3+ hours):
1. Implement streaming responses
2. Add meal caching/optimization
3. Build comprehensive meal logging flow

---

## Testing After Fixes

1. **AI Meal Plans**: Check backend logs to see actual AI response
2. **AI Coach**: Ask about "my progress" and verify it references your actual data
3. **Progress Entry**: Create new entry and verify it appears immediately
4. **Meal Logging**: Generate plan → tap meal → log it → verify in progress

