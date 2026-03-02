from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any

# --- User Profile ---
class UserProfile(BaseModel):
    age: int = 25
    weight: float = 70.0  # kg
    height: float = 170.0 # cm
    gender: str = "male"
    activity_level: str = "moderate" # sedentary, light, moderate, active, very_active
    primary_goal: str = "maintain" # weight_loss, muscle_gain, maintain
    dietary_restrictions: List[str] = []
    fitness_experience: str = "intermediate" # beginner, intermediate, expert
    equipment: List[str] = ["body only"]
    days_per_week: int = 3
    time_per_workout: int = 60 # minutes

# --- Nutrition Schemas ---
class Meal(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    calories: int
    protein_grams: float
    carbs_grams: float
    fat_grams: float
    ingredients: Dict[str, str] = {} # item: quantity
    instructions: Optional[str] = None
    prep_time_minutes: int = 15
    cook_time_minutes: int = 15

class DailyMeal(BaseModel):
    day: str # Monday, Tuesday, etc.
    breakfast: List[Meal]
    lunch: List[Meal]
    dinner: List[Meal]
    snacks: List[Meal]

class NutritionPlan(BaseModel):
    id: str
    user_id: str
    week_start: str
    daily_calories: int
    macros: Dict[str, float] # protein, carbs, fat (percentages or grams? usually percentages or grams)
    meals: List[DailyMeal]
    created_by_ai: bool = True
    adaptation_reason: Optional[str] = None

# --- Fitness Schemas ---

class WorkoutExercise(BaseModel):
    exercise_id: str
    name: str # Should match library name
    sets: int
    reps: Optional[str] = None # "10-12"
    weight_kg: Optional[float] = None
    duration_seconds: Optional[int] = None
    rest_seconds: int = 60
    notes: Optional[str] = None

class Workout(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    exercises: List[WorkoutExercise]
    estimated_duration_minutes: int
    difficulty: str # beginner, intermediate, advanced
    target_muscle_groups: List[str]

class DailyWorkout(BaseModel):
    day: str # Monday, Tuesday, etc.
    workouts: List[Workout] # Usually one per day
    is_rest_day: bool = False

class WorkoutPlan(BaseModel):
    id: str
    user_id: str
    week_start: str
    goal: str
    workouts: List[DailyWorkout]
    created_by_ai: bool = True
    adaptation_reason: Optional[str] = None
