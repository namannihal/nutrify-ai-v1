# 🗄️ Nutrify-AI — Database Schema Guide
### PostgreSQL-First Design with Optional NoSQL for Specific Use Cases

---

## Executive Summary

**Recommendation: PostgreSQL as Primary Database + Redis for Caching**

Based on comprehensive analysis of the frontend data requirements, PRD specifications, and engineering architecture, **PostgreSQL (SQL)** is the optimal choice for Nutrify-AI's primary database due to:

1. **Strong relational integrity** required for user profiles, plans, and progress tracking
2. **Complex queries** needed for analytics, progress analysis, and AI model training
3. **ACID compliance** for critical health data and subscription management
4. **JSON support** (JSONB) for flexible fields without sacrificing structure
5. **Vector extension (pgvector)** for embedding storage, eliminating need for separate vector DB

**NoSQL Use Cases (Supplementary):**
- **Redis:** Caching, session management, real-time features
- **S3/Object Storage:** Media files (photos, documents)
- **Optional MongoDB:** If future features require extreme schema flexibility

---

## 1. Frontend Data Analysis

### Data Collected by Frontend

#### **Onboarding Data** (`Onboarding.tsx`)
```typescript
{
  // Personal Info
  name: string
  age: number
  gender: 'male' | 'female' | 'other'
  height: number (cm)
  weight: number (kg)
  
  // Goals & Activity
  primaryGoal: 'weight_loss' | 'muscle_gain' | 'maintain' | 'endurance' | 'strength'
  secondaryGoals: string[] // ['Better Sleep', 'More Energy', ...]
  activityLevel: 'sedentary' | 'lightly_active' | 'moderately_active' | 'very_active' | 'extremely_active'
  fitnessExperience: 'beginner' | 'intermediate' | 'advanced'
  
  // Dietary Preferences
  dietaryRestrictions: string[] // ['Vegetarian', 'Vegan', 'Keto', ...]
  allergies: string
  mealsPerDay: number
  cookingTime: 'minimal' | 'moderate' | 'extensive'
  
  // Workout Preferences
  workoutDays: string
  workoutDuration: string
  preferredWorkoutTime: string
  equipmentAccess: string[]
  
  // Privacy Consent
  dataConsent: boolean
  marketingConsent: boolean
  healthDisclaimer: boolean
}
```

#### **Nutrition Plan Data** (`NutritionPlan.tsx`)
```typescript
{
  id: string
  user_id: string
  week_start: string
  daily_calories: number
  macros: {
    protein: number
    carbs: number
    fat: number
  }
  adaptation_reason: string
  created_by_ai: boolean
  meals: {
    [day: string]: {
      breakfast: Meal[]
      lunch: Meal[]
      dinner: Meal[]
      snacks: Meal[]
    }
  }
}

Meal {
  id: string
  name: string
  calories: number
  protein: number
  carbs: number
  fat: number
  ingredients: string[]
  prep_time: number
  instructions?: string
}
```

#### **Fitness Plan Data** (`FitnessPlan.tsx`)
```typescript
{
  id: string
  user_id: string
  week_start: string
  difficulty_level: number
  adaptation_reason: string
  created_by_ai: boolean
  workouts: {
    [day: string]: {
      type: 'strength' | 'cardio' | 'flexibility' | 'rest'
      duration: number
      exercises: Exercise[]
    }
  }
}

Exercise {
  id: string
  name: string
  sets: number
  reps: number
  rest_time: number
  instructions: string
  muscle_groups: string[]
  equipment: string[]
}
```

#### **Progress Tracking Data** (`Progress.tsx`)
```typescript
{
  id: string
  user_id: string
  date: string
  weight: number
  body_fat: number
  muscle: number
  mood: number (1-10)
  energy: number (1-10)
  sleep: number (hours)
  water: number (ml)
  adherence: number (0-100%)
  
  // Weekly metrics
  weekly_adherence: number
  strength_improvement: number
  consistency_score: number
}

Achievement {
  id: string
  title: string
  description: string
  earned: boolean
  date?: string
  progress?: number
}
```

#### **AI Chat Data** (`AIChat.tsx`)
```typescript
{
  id: string
  user_id: string
  timestamp: Date
  type: 'user' | 'ai'
  content: string
  category: 'nutrition' | 'fitness' | 'motivation' | 'general'
  explanation?: string
  suggestions?: string[]
}
```

#### **API Service Interfaces** (`api.ts`)
```typescript
User {
  id: string
  email: string
  name: string
  avatar?: string
  subscription_tier: 'free' | 'premium' | 'enterprise'
  created_at: timestamp
}

AIInsight {
  id: string
  user_id: string
  type: 'motivation' | 'nutrition' | 'fitness' | 'progress'
  title: string
  message: string
  explanation: string
  action_items: string[]
  created_at: timestamp
  priority: 'low' | 'medium' | 'high'
}
```

---

## 2. Database Schema Design (PostgreSQL)

### 2.1 Core Tables

#### **users**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255), -- NULL for OAuth-only users
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    subscription_tier VARCHAR(50) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'enterprise')),
    oauth_provider VARCHAR(50), -- 'google', 'apple', NULL
    oauth_id VARCHAR(255),
    email_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT unique_oauth UNIQUE (oauth_provider, oauth_id)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription ON users(subscription_tier);
```

#### **user_profiles**
```sql
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Personal Info
    age INTEGER CHECK (age > 0 AND age < 150),
    gender VARCHAR(50) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    height DECIMAL(5,2), -- cm
    weight DECIMAL(5,2), -- kg
    
    -- Goals & Activity
    primary_goal VARCHAR(50) CHECK (primary_goal IN ('weight_loss', 'muscle_gain', 'maintain', 'endurance', 'strength')),
    secondary_goals TEXT[], -- Array of strings
    activity_level VARCHAR(50) CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active')),
    fitness_experience VARCHAR(50) CHECK (fitness_experience IN ('beginner', 'intermediate', 'advanced')),
    
    -- Dietary Info
    dietary_restrictions TEXT[], -- ['Vegetarian', 'Vegan', 'Keto', ...]
    allergies TEXT,
    meals_per_day INTEGER CHECK (meals_per_day BETWEEN 3 AND 6),
    cooking_time VARCHAR(50) CHECK (cooking_time IN ('minimal', 'moderate', 'extensive')),
    
    -- Workout Preferences
    workout_days_per_week VARCHAR(20), -- '2-3', '4-5', '6-7'
    workout_duration VARCHAR(20), -- '15-30', '30-45', '45-60', '60+'
    preferred_workout_time VARCHAR(50), -- 'morning', 'afternoon', 'evening'
    equipment_access TEXT[], -- ['dumbbells', 'barbell', 'gym', ...]
    
    -- Privacy & Consent
    data_consent BOOLEAN DEFAULT false,
    marketing_consent BOOLEAN DEFAULT false,
    health_disclaimer BOOLEAN DEFAULT false,
    
    -- Metadata
    onboarding_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
```

#### **nutrition_plans**
```sql
CREATE TABLE nutrition_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,
    
    -- Targets
    daily_calories INTEGER NOT NULL,
    protein_grams INTEGER NOT NULL,
    carbs_grams INTEGER NOT NULL,
    fat_grams INTEGER NOT NULL,
    
    -- AI Metadata
    created_by_ai BOOLEAN DEFAULT true,
    adaptation_reason TEXT,
    ai_model_version VARCHAR(50),
    generation_prompt_hash VARCHAR(64), -- For tracking which prompt generated this
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    version INTEGER DEFAULT 1,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_active_plan UNIQUE (user_id, week_start) DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX idx_nutrition_plans_user_id ON nutrition_plans(user_id);
CREATE INDEX idx_nutrition_plans_active ON nutrition_plans(user_id, is_active) WHERE is_active = true;
CREATE INDEX idx_nutrition_plans_week ON nutrition_plans(week_start);
```

#### **meals**
```sql
CREATE TABLE meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES nutrition_plans(id) ON DELETE CASCADE,
    
    -- Meal Info
    day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Monday, 6=Sunday
    meal_type VARCHAR(50) CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    meal_order INTEGER DEFAULT 1, -- For multiple snacks
    
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Nutrition
    calories INTEGER NOT NULL,
    protein_grams DECIMAL(5,2) NOT NULL,
    carbs_grams DECIMAL(5,2) NOT NULL,
    fat_grams DECIMAL(5,2) NOT NULL,
    fiber_grams DECIMAL(5,2),
    
    -- Recipe Details
    ingredients JSONB NOT NULL, -- [{"name": "chicken", "amount": 200, "unit": "g"}, ...]
    instructions TEXT,
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    
    -- Preferences
    cuisine_type VARCHAR(100),
    dietary_tags TEXT[], -- ['high-protein', 'low-carb', 'vegetarian', ...]
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meals_plan_id ON meals(plan_id);
CREATE INDEX idx_meals_plan_day ON meals(plan_id, day_of_week, meal_type);
```

#### **fitness_plans**
```sql
CREATE TABLE fitness_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,
    
    -- Plan Metadata
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 10),
    focus_areas TEXT[], -- ['strength', 'cardio', 'flexibility']
    estimated_calories_burn INTEGER,
    
    -- AI Metadata
    created_by_ai BOOLEAN DEFAULT true,
    adaptation_reason TEXT,
    ai_model_version VARCHAR(50),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    version INTEGER DEFAULT 1,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_active_fitness_plan UNIQUE (user_id, week_start) DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX idx_fitness_plans_user_id ON fitness_plans(user_id);
CREATE INDEX idx_fitness_plans_active ON fitness_plans(user_id, is_active) WHERE is_active = true;
```

#### **workouts**
```sql
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES fitness_plans(id) ON DELETE CASCADE,
    
    day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6),
    workout_type VARCHAR(50) CHECK (workout_type IN ('strength', 'cardio', 'flexibility', 'hiit', 'rest')),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    duration_minutes INTEGER NOT NULL,
    estimated_calories INTEGER,
    intensity_level INTEGER CHECK (intensity_level BETWEEN 1 AND 10),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workouts_plan_id ON workouts(plan_id);
CREATE INDEX idx_workouts_plan_day ON workouts(plan_id, day_of_week);
```

#### **exercises**
```sql
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    
    exercise_order INTEGER NOT NULL, -- Order in workout
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Exercise Details
    sets INTEGER,
    reps INTEGER, -- For strength exercises
    duration_seconds INTEGER, -- For timed exercises (planks, cardio)
    rest_time_seconds INTEGER,
    
    -- Targets
    muscle_groups TEXT[], -- ['chest', 'triceps', 'shoulders']
    equipment_required TEXT[], -- ['barbell', 'bench', 'dumbbells']
    
    -- Instructions
    instructions TEXT,
    video_url TEXT,
    form_cues TEXT[],
    
    -- Difficulty
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 10),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_exercises_workout_id ON exercises(workout_id);
CREATE INDEX idx_exercises_muscle_groups ON exercises USING GIN(muscle_groups);
```

### 2.2 Tracking & Logging Tables

#### **progress_entries**
```sql
CREATE TABLE progress_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    
    -- Body Metrics
    weight DECIMAL(5,2),
    body_fat_percentage DECIMAL(4,2),
    muscle_mass DECIMAL(5,2),
    
    -- Body Measurements (JSON for flexibility)
    measurements JSONB, -- {"chest": 100, "waist": 80, "biceps": 35, ...}
    
    -- Subjective Metrics
    mood_score INTEGER CHECK (mood_score BETWEEN 1 AND 10),
    energy_score INTEGER CHECK (energy_score BETWEEN 1 AND 10),
    stress_score INTEGER CHECK (stress_score BETWEEN 1 AND 10),
    
    -- Sleep & Hydration
    sleep_hours DECIMAL(3,1),
    sleep_quality INTEGER CHECK (sleep_quality BETWEEN 1 AND 10),
    water_intake_ml INTEGER,
    
    -- Adherence
    adherence_score INTEGER CHECK (adherence_score BETWEEN 0 AND 100),
    
    -- Notes
    notes TEXT,
    photos JSONB, -- [{"url": "s3://...", "type": "front"}, ...]
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_daily_entry UNIQUE (user_id, entry_date)
);

CREATE INDEX idx_progress_entries_user_date ON progress_entries(user_id, entry_date DESC);
CREATE INDEX idx_progress_entries_user_id ON progress_entries(user_id);
```

#### **meal_logs**
```sql
CREATE TABLE meal_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    meal_id UUID REFERENCES meals(id) ON DELETE SET NULL, -- NULL if custom/unplanned meal
    
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    meal_date DATE NOT NULL,
    meal_type VARCHAR(50) CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    
    -- Nutrition (actual consumed)
    calories INTEGER,
    protein_grams DECIMAL(5,2),
    carbs_grams DECIMAL(5,2),
    fat_grams DECIMAL(5,2),
    
    -- Custom meal details
    custom_meal_name VARCHAR(255),
    custom_foods JSONB, -- If not from meal plan
    
    -- Logging method
    log_method VARCHAR(50) CHECK (log_method IN ('manual', 'ocr', 'barcode', 'meal_plan')),
    ocr_image_url TEXT,
    
    -- Feedback
    satisfaction_rating INTEGER CHECK (satisfaction_rating BETWEEN 1 AND 5),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meal_logs_user_date ON meal_logs(user_id, meal_date DESC);
CREATE INDEX idx_meal_logs_user_id ON meal_logs(user_id);
CREATE INDEX idx_meal_logs_meal_id ON meal_logs(meal_id);
```

#### **workout_logs**
```sql
CREATE TABLE workout_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL, -- NULL if custom workout
    
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    workout_date DATE NOT NULL,
    
    -- Workout Summary
    workout_name VARCHAR(255),
    duration_minutes INTEGER NOT NULL,
    calories_burned INTEGER,
    
    -- Performance
    perceived_exertion INTEGER CHECK (perceived_exertion BETWEEN 1 AND 10), -- RPE scale
    mood_after INTEGER CHECK (mood_after BETWEEN 1 AND 10),
    
    -- Status
    completed BOOLEAN DEFAULT true,
    completion_percentage INTEGER CHECK (completion_percentage BETWEEN 0 AND 100),
    
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workout_logs_user_date ON workout_logs(user_id, workout_date DESC);
CREATE INDEX idx_workout_logs_user_id ON workout_logs(user_id);
```

#### **exercise_logs**
```sql
CREATE TABLE exercise_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_log_id UUID NOT NULL REFERENCES workout_logs(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES exercises(id) ON DELETE SET NULL,
    
    exercise_name VARCHAR(255) NOT NULL,
    
    -- Performance Details
    sets_completed INTEGER,
    reps_per_set INTEGER[], -- [12, 10, 8] for pyramid sets
    weight_per_set DECIMAL(6,2)[], -- [100, 110, 120] kg
    duration_seconds INTEGER, -- For timed exercises
    
    -- Feedback
    difficulty_rating INTEGER CHECK (difficulty_rating BETWEEN 1 AND 10),
    form_quality INTEGER CHECK (form_quality BETWEEN 1 AND 10),
    
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_exercise_logs_workout_log_id ON exercise_logs(workout_log_id);
```

### 2.3 AI & Intelligence Tables

#### **ai_insights**
```sql
CREATE TABLE ai_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    insight_type VARCHAR(50) CHECK (insight_type IN ('motivation', 'nutrition', 'fitness', 'progress', 'recommendation')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    explanation TEXT NOT NULL, -- Why this insight was generated
    
    -- Action Items
    action_items JSONB, -- [{"action": "Increase protein", "priority": "high"}, ...]
    
    -- Priority & Status
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high')),
    is_read BOOLEAN DEFAULT false,
    is_dismissed BOOLEAN DEFAULT false,
    
    -- AI Metadata
    ai_model_used VARCHAR(100),
    confidence_score DECIMAL(3,2), -- 0.00 to 1.00
    generated_from_data JSONB, -- References to data sources used
    
    -- Display Control
    display_until TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE,
    dismissed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_ai_insights_user_id ON ai_insights(user_id, created_at DESC);
CREATE INDEX idx_ai_insights_unread ON ai_insights(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_ai_insights_priority ON ai_insights(user_id, priority) WHERE is_dismissed = false;
```

#### **chat_messages**
```sql
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    message_type VARCHAR(20) CHECK (message_type IN ('user', 'ai')),
    content TEXT NOT NULL,
    
    -- AI Response Metadata
    category VARCHAR(50) CHECK (category IN ('nutrition', 'fitness', 'motivation', 'general', 'progress')),
    explanation TEXT, -- Why AI responded this way
    suggestions JSONB, -- ["Try this workout", "Adjust your calories", ...]
    
    -- Context
    context_data JSONB, -- User data used to generate response
    ai_model_used VARCHAR(100),
    
    -- Feedback
    user_rating INTEGER CHECK (user_rating BETWEEN 1 AND 5),
    user_feedback TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id, created_at DESC);
CREATE INDEX idx_chat_messages_type ON chat_messages(user_id, message_type);
```

#### **ai_training_data**
```sql
CREATE TABLE ai_training_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Training Sample
    input_data JSONB NOT NULL, -- User state, preferences, history
    output_data JSONB NOT NULL, -- AI recommendation/plan generated
    outcome_data JSONB, -- User response, adherence, results
    
    -- Quality Metrics
    user_satisfaction INTEGER CHECK (user_satisfaction BETWEEN 1 AND 5),
    adherence_rate DECIMAL(5,2), -- How well user followed the plan
    effectiveness_score DECIMAL(5,2), -- Did it achieve goals?
    
    -- Metadata
    model_version VARCHAR(50),
    training_status VARCHAR(50) DEFAULT 'pending' CHECK (training_status IN ('pending', 'included', 'excluded')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_training_data_user_id ON ai_training_data(user_id);
CREATE INDEX idx_ai_training_data_status ON ai_training_data(training_status);
```

### 2.4 Gamification & Engagement Tables

#### **achievements**
```sql
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Achievement Definition
    achievement_key VARCHAR(100) UNIQUE NOT NULL, -- 'consistency_champion', 'strength_surge'
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    icon_url TEXT,
    
    -- Unlock Criteria
    criteria JSONB NOT NULL, -- {"type": "streak", "days": 7, "metric": "workout"}
    points INTEGER DEFAULT 0,
    
    tier VARCHAR(50) CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_achievements_key ON achievements(achievement_key);
```

#### **user_achievements**
```sql
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    progress_percentage INTEGER DEFAULT 100 CHECK (progress_percentage BETWEEN 0 AND 100),
    is_completed BOOLEAN DEFAULT false,
    
    -- Metadata
    unlock_data JSONB, -- Data snapshot when unlocked
    
    CONSTRAINT unique_user_achievement UNIQUE (user_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id, earned_at DESC);
CREATE INDEX idx_user_achievements_progress ON user_achievements(user_id) WHERE is_completed = false;
```

#### **streaks**
```sql
CREATE TABLE streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    streak_type VARCHAR(50) CHECK (streak_type IN ('workout', 'nutrition', 'logging', 'overall')),
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    
    last_activity_date DATE,
    
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_streak_type UNIQUE (user_id, streak_type)
);

CREATE INDEX idx_streaks_user_id ON streaks(user_id);
```

### 2.5 Subscription & Payments Tables

#### **subscriptions**
```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    tier VARCHAR(50) CHECK (tier IN ('free', 'premium', 'enterprise')),
    status VARCHAR(50) CHECK (status IN ('active', 'canceled', 'past_due', 'trial', 'paused')),
    
    -- Billing
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    
    -- Dates
    trial_ends_at TIMESTAMP WITH TIME ZONE,
    current_period_start TIMESTAMP WITH TIME ZONE,
    current_period_end TIMESTAMP WITH TIME ZONE,
    canceled_at TIMESTAMP WITH TIME ZONE,
    
    -- Features
    features_enabled JSONB, -- ["ai_chat", "advanced_analytics", "wearable_sync", ...]
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_stripe_customer ON subscriptions(stripe_customer_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
```

#### **payment_history**
```sql
CREATE TABLE payment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    
    -- Payment Details
    stripe_payment_intent_id VARCHAR(255),
    amount_cents INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    status VARCHAR(50) CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded')),
    payment_method VARCHAR(50), -- 'card', 'paypal', etc.
    
    -- Dates
    payment_date TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_history_user_id ON payment_history(user_id, created_at DESC);
CREATE INDEX idx_payment_history_subscription ON payment_history(subscription_id);
```

### 2.6 Integration & Sync Tables

#### **wearable_integrations**
```sql
CREATE TABLE wearable_integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    provider VARCHAR(50) CHECK (provider IN ('apple_health', 'fitbit', 'garmin', 'oura', 'whoop')),
    
    -- OAuth Tokens
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Sync Status
    is_active BOOLEAN DEFAULT true,
    last_sync_at TIMESTAMP WITH TIME ZONE,
    sync_frequency VARCHAR(50) DEFAULT 'hourly', -- 'realtime', 'hourly', 'daily'
    
    -- Permissions
    scopes TEXT[], -- ['activity', 'sleep', 'heart_rate', ...]
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_provider UNIQUE (user_id, provider)
);

CREATE INDEX idx_wearable_integrations_user_id ON wearable_integrations(user_id);
CREATE INDEX idx_wearable_integrations_active ON wearable_integrations(is_active) WHERE is_active = true;
```

#### **wearable_data**
```sql
CREATE TABLE wearable_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    integration_id UUID NOT NULL REFERENCES wearable_integrations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    data_type VARCHAR(50) CHECK (data_type IN ('steps', 'calories', 'heart_rate', 'sleep', 'workout', 'hrv')),
    data_date DATE NOT NULL,
    
    -- Data Payload
    value DECIMAL(10,2),
    unit VARCHAR(50),
    raw_data JSONB, -- Full response from provider
    
    synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_wearable_data_entry UNIQUE (integration_id, data_type, data_date)
);

CREATE INDEX idx_wearable_data_user_date ON wearable_data(user_id, data_date DESC);
CREATE INDEX idx_wearable_data_type ON wearable_data(user_id, data_type, data_date DESC);
```

### 2.7 System & Audit Tables

#### **audit_logs**
```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    action VARCHAR(100) NOT NULL, -- 'login', 'profile_update', 'plan_generated', ...
    entity_type VARCHAR(100), -- 'user', 'nutrition_plan', 'workout_log', ...
    entity_id UUID,
    
    -- Details
    changes JSONB, -- Before/after for updates
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action, created_at DESC);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
```

#### **notifications**
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    notification_type VARCHAR(50) CHECK (notification_type IN ('push', 'email', 'in_app')),
    category VARCHAR(50) CHECK (category IN ('reminder', 'insight', 'achievement', 'plan_update', 'social')),
    
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    
    -- Status
    is_read BOOLEAN DEFAULT false,
    is_sent BOOLEAN DEFAULT false,
    
    -- Action
    action_url TEXT,
    action_data JSONB,
    
    -- Scheduling
    scheduled_for TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_for) WHERE is_sent = false;
```

---

## 3. Vector Storage for AI Embeddings

### Option 1: PostgreSQL + pgvector Extension (Recommended)

```sql
-- Enable pgvector extension
CREATE EXTENSION vector;

CREATE TABLE user_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    embedding_type VARCHAR(50) CHECK (embedding_type IN ('profile', 'preferences', 'behavior', 'goals')),
    embedding vector(1536), -- OpenAI ada-002 embedding dimension
    
    -- Metadata
    source_data JSONB, -- Original data used to create embedding
    model_version VARCHAR(50),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_embeddings_user_id ON user_embeddings(user_id);
CREATE INDEX idx_user_embeddings_vector ON user_embeddings USING ivfflat (embedding vector_cosine_ops);
```

### Option 2: FAISS (As per Engineering Guide)

If using FAISS separately, store only references in PostgreSQL:

```sql
CREATE TABLE faiss_index_references (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    index_key VARCHAR(255) NOT NULL, -- Key in FAISS index
    embedding_type VARCHAR(50),
    
    -- Metadata
    dimension INTEGER,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

## 4. Redis Schema (Caching & Real-Time)

### Key Patterns

```
# Session Management
session:{session_id} → {user_id, expires_at, ...}

# User Cache
user:{user_id}:profile → JSON of user profile
user:{user_id}:current_plan:nutrition → Current nutrition plan (7-day TTL)
user:{user_id}:current_plan:fitness → Current fitness plan (7-day TTL)

# Real-Time Tracking
user:{user_id}:today:meals → JSON array of meals logged today
user:{user_id}:today:workout → Current workout session state
user:{user_id}:streak:{type} → Current streak count

# Rate Limiting
rate_limit:{user_id}:api → Request count (1-hour TTL)
rate_limit:{user_id}:ai_chat → AI chat requests (1-hour TTL)

# Leaderboards (Optional)
leaderboard:global:consistency → Sorted set of user consistency scores
leaderboard:global:streaks → Sorted set of user streaks

# Pub/Sub Channels
notifications:{user_id} → Real-time notifications
ai_processing:{user_id} → AI job status updates
```

---

## 5. Migration Strategy

### Phase 1: Core Tables (MVP)
```
1. users
2. user_profiles
3. nutrition_plans + meals
4. fitness_plans + workouts + exercises
5. progress_entries
6. chat_messages
```

### Phase 2: Logging & Tracking
```
7. meal_logs
8. workout_logs + exercise_logs
9. ai_insights
10. notifications
```

### Phase 3: Gamification & Monetization
```
11. achievements + user_achievements
12. streaks
13. subscriptions + payment_history
```

### Phase 4: Integrations
```
14. wearable_integrations + wearable_data
15. audit_logs
```

---

## 6. SQL vs NoSQL Decision Matrix

| Criterion | PostgreSQL (SQL) | MongoDB (NoSQL) | Winner |
|-----------|------------------|-----------------|--------|
| **Data Relationships** | Strong (users → plans → meals) | Weak (requires manual joins) | ✅ **PostgreSQL** |
| **Query Complexity** | Excellent (JOINs, aggregations) | Limited | ✅ **PostgreSQL** |
| **Schema Evolution** | Requires migrations | Very flexible | MongoDB |
| **ACID Compliance** | Full support | Limited | ✅ **PostgreSQL** |
| **Analytics Queries** | Excellent | Requires aggregation pipelines | ✅ **PostgreSQL** |
| **JSON Support** | JSONB (best of both worlds) | Native | Tie |
| **Vector Search** | pgvector extension | Requires Atlas Search | ✅ **PostgreSQL** |
| **Scalability** | Vertical + read replicas | Horizontal sharding | MongoDB |
| **Developer Familiarity** | High | Medium | PostgreSQL |
| **Cost** | Lower (self-hosted) | Higher (managed Atlas) | PostgreSQL |

**Verdict: PostgreSQL wins 7/10 criteria**

---

## 7. Performance Optimization

### Indexing Strategy

```sql
-- Composite indexes for common queries
CREATE INDEX idx_meal_logs_user_date_type ON meal_logs(user_id, meal_date, meal_type);
CREATE INDEX idx_progress_entries_user_date_desc ON progress_entries(user_id, entry_date DESC);

-- Partial indexes for active records
CREATE INDEX idx_active_nutrition_plans ON nutrition_plans(user_id) WHERE is_active = true;
CREATE INDEX idx_active_fitness_plans ON fitness_plans(user_id) WHERE is_active = true;

-- GIN indexes for array/JSONB columns
CREATE INDEX idx_user_profiles_restrictions ON user_profiles USING GIN(dietary_restrictions);
CREATE INDEX idx_exercises_muscle_groups ON exercises USING GIN(muscle_groups);
CREATE INDEX idx_meals_ingredients ON meals USING GIN(ingredients);
```

### Partitioning Strategy

For large-scale deployments:

```sql
-- Partition progress_entries by month
CREATE TABLE progress_entries (
    ...
) PARTITION BY RANGE (entry_date);

CREATE TABLE progress_entries_2024_01 PARTITION OF progress_entries
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE progress_entries_2024_02 PARTITION OF progress_entries
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
-- etc.
```

### Query Optimization

```sql
-- Use CTEs for complex queries
WITH user_stats AS (
    SELECT 
        user_id,
        AVG(adherence_score) as avg_adherence,
        COUNT(*) as total_entries
    FROM progress_entries
    WHERE entry_date > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id
)
SELECT u.name, us.avg_adherence, us.total_entries
FROM users u
JOIN user_stats us ON u.id = us.user_id
WHERE us.avg_adherence > 80;
```

---

## 8. Backup & Recovery

### Backup Strategy

```bash
# Daily full backups
pg_dump -Fc nutrify_db > nutrify_backup_$(date +%Y%m%d).dump

# Continuous WAL archiving for PITR
archive_command = 'cp %p /backup/wal_archive/%f'

# Retention: 30 days daily, 12 months monthly
```

### Disaster Recovery

```sql
-- Point-in-time recovery
pg_restore -d nutrify_db -C nutrify_backup_20240101.dump

-- Test restores monthly
-- RTO: < 1 hour
-- RPO: < 15 minutes (via WAL)
```

---

## 9. Security Measures

### Row-Level Security (RLS)

```sql
-- Enable RLS on sensitive tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_profile_policy ON user_profiles
    USING (user_id = current_setting('app.current_user_id')::uuid);

-- Admin override
CREATE POLICY admin_full_access ON user_profiles
    USING (current_setting('app.user_role') = 'admin');
```

### Encryption

```sql
-- Encrypt sensitive columns
CREATE EXTENSION pgcrypto;

-- Store encrypted OAuth tokens
INSERT INTO wearable_integrations (access_token) 
VALUES (pgp_sym_encrypt('token_value', 'encryption_key'));

-- Retrieve
SELECT pgp_sym_decrypt(access_token, 'encryption_key') 
FROM wearable_integrations;
```

---

## 10. Monitoring & Observability

### Key Metrics to Track

```sql
-- Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Slow queries
SELECT 
    mean_exec_time,
    calls,
    query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

### Alerts

- Connection pool exhaustion (> 80%)
- Slow query threshold (> 1s)
- Replication lag (> 5s)
- Disk usage (> 75%)
- Failed backup jobs

---

## 11. Scaling Roadmap

### Phase 1: Single Instance (0-10K users)
- One PostgreSQL instance
- Redis for caching
- Vertical scaling

### Phase 2: Read Replicas (10K-100K users)
- Primary + 2 read replicas
- Connection pooling (PgBouncer)
- Redis Cluster

### Phase 3: Sharding (100K+ users)
- Shard by user_id (Citus extension)
- Multi-region deployment
- CDN for static assets

---

## 12. Cost Estimation

| Component | Configuration | Monthly Cost |
|-----------|---------------|--------------|
| **PostgreSQL (AWS RDS)** | db.t3.medium (2 vCPU, 4GB RAM) | $60 |
| **Redis (ElastiCache)** | cache.t3.micro | $15 |
| **Storage (S3)** | 100GB (photos, assets) | $2.30 |
| **Backups (S3)** | 50GB | $1.15 |
| **Total** | | **~$80/month** |

**For 10K users:** ~$0.008/user/month

---

## 13. Conclusion & Recommendation

### ✅ **PRIMARY DATABASE: PostgreSQL**

**Reasons:**
1. **Relational Integrity:** Complex relationships between users, plans, logs
2. **Query Power:** Advanced analytics, aggregations, JOINs
3. **JSONB Support:** Flexibility where needed (ingredients, metadata)
4. **pgvector:** Built-in vector search for AI embeddings
5. **ACID Compliance:** Critical for health data and payments
6. **Mature Ecosystem:** Better tooling, monitoring, backups
7. **Cost-Effective:** Lower infrastructure costs at scale

### ⚡ **SUPPLEMENTARY: Redis**
- Session management
- Caching current plans
- Real-time features (active workouts, today's meals)
- Rate limiting
- Pub/sub for notifications

### 📦 **OPTIONAL: S3/Object Storage**
- User photos (progress tracking)
- OCR images (food logging)
- Meal/exercise videos
- PDF exports (meal plans)

### ❌ **NOT RECOMMENDED: MongoDB**
While MongoDB is excellent for certain use cases, Nutrify-AI's requirements (strong relationships, complex queries, analytics) make PostgreSQL the superior choice.

---

## 14. Next Steps

1. **Set up PostgreSQL instance** (local dev + staging)
2. **Create migration files** using Alembic (Python) or similar
3. **Implement core tables** (Phase 1: users, profiles, plans)
4. **Set up Redis** for caching layer
5. **Configure backups** and monitoring
6. **Implement RLS policies** for security
7. **Load test** with realistic data volumes
8. **Document API** endpoints mapping to schema

---

**Document Version:** 1.0  
**Last Updated:** November 1, 2025  
**Author:** Database Architecture Team  
**Status:** Ready for Implementation
