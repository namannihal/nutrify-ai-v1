// API service layer for Nutrify-AI backend integration
import { toast } from '@/components/ui/use-toast';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

// Types for API responses
export interface User {
  id: string;
  email: string;
  name: string;
  avatar?: string;
  subscription_tier: 'free' | 'premium' | 'enterprise';
  created_at: string;
}

export interface UserProfile {
  id: string;
  user_id: string;
  age?: number;
  gender?: 'male' | 'female' | 'other';
  height?: number; // cm
  weight?: number; // kg
  activity_level?: 'sedentary' | 'lightly_active' | 'moderately_active' | 'very_active' | 'extremely_active';
  goals?: string[];
  dietary_restrictions?: string[];
  fitness_experience?: 'beginner' | 'intermediate' | 'advanced';
  onboarding_completed?: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface NutritionPlan {
  id: string;
  user_id: string;
  week_start: string;
  daily_calories: number;
  macros: {
    protein: number;
    carbs: number;
    fat: number;
  };
  meals: DailyMeal[];
  created_by_ai: boolean;
  adaptation_reason?: string;
}

export interface DailyMeal {
  day: string;
  breakfast: Meal[];
  lunch: Meal[];
  dinner: Meal[];
  snacks: Meal[];
}

export interface Meal {
  id: string;
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  ingredients: string[];
  instructions?: string;
  prep_time?: number;
}

export interface WorkoutPlan {
  id: string;
  user_id: string;
  week_start: string;
  workouts: DailyWorkout[];
  difficulty_level: number;
  created_by_ai: boolean;
  adaptation_reason?: string;
}

export interface DailyWorkout {
  day: string;
  type: 'strength' | 'cardio' | 'flexibility' | 'rest';
  duration: number;
  exercises: Exercise[];
}

export interface Exercise {
  id: string;
  name: string;
  sets?: number;
  reps?: number;
  duration?: number;
  rest_time?: number;
  instructions: string;
  muscle_groups: string[];
  equipment: string[];
}

export interface ProgressEntry {
  id: string;
  user_id: string;
  date: string;
  weight?: number;
  body_fat?: number;
  measurements?: Record<string, number>;
  mood: number; // 1-10
  energy: number; // 1-10
  sleep_hours: number;
  water_intake: number; // ml
  adherence_score: number; // 0-100
}

export interface AIInsight {
  id: string;
  user_id: string;
  type: 'motivation' | 'nutrition' | 'fitness' | 'progress';
  title: string;
  message: string;
  explanation: string;
  action_items: string[];
  created_at: string;
  priority: 'low' | 'medium' | 'high';
}

// API client class
class APIClient {
  private token: string | null = null;

  constructor() {
    this.token = localStorage.getItem('auth_token');
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${API_BASE_URL}${endpoint}`;
    const config: RequestInit = {
      headers: {
        'Content-Type': 'application/json',
        ...(this.token && { Authorization: `Bearer ${this.token}` }),
        ...options.headers,
      },
      ...options,
    };

    try {
      const response = await fetch(url, config);
      
      if (!response.ok) {
        if (response.status === 401) {
          this.logout();
          throw new Error('Authentication required');
        }
        
        // Handle 404 gracefully - treat as "no data" rather than error
        if (response.status === 404) {
          throw new Error('NOT_FOUND');
        }
        
        throw new Error(`API Error: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      // Don't show toast for 404s - they're expected when no data exists yet
      if (error instanceof Error && error.message === 'NOT_FOUND') {
        throw error;
      }
      
      // Only log non-404 errors
      console.error('API request failed:', error);
      
      // Only show toast for actual connection/server errors
      if (error instanceof TypeError || (error instanceof Error && error.message.includes('fetch'))) {
        toast({
          title: 'Connection Error',
          description: 'Unable to connect to server.',
          variant: 'destructive',
        });
      }
      
      throw error;
    }
  }

  // Authentication methods
  async login(email: string, password: string): Promise<{ user: User; token: string }> {
    const response = await this.request<{ user: User; token: string }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    
    this.token = response.token;
    localStorage.setItem('auth_token', response.token);
    return response;
  }

  async register(userData: {
    email: string;
    password: string;
    name: string;
  }): Promise<{ user: User; token: string }> {
    const response = await this.request<{ user: User; token: string }>('/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
    
    this.token = response.token;
    localStorage.setItem('auth_token', response.token);
    return response;
  }

  logout(): void {
    this.token = null;
    localStorage.removeItem('auth_token');
  }

  // User profile methods
  async getUserProfile(): Promise<UserProfile> {
    return this.request<UserProfile>('/users/me');
  }

  async getCurrentUser(): Promise<User> {
    return this.request<User>('/users/me/basic');
  }

  async updateUserProfile(profile: Partial<UserProfile>): Promise<UserProfile> {
    return this.request<UserProfile>('/users/me', {
      method: 'PUT',
      body: JSON.stringify(profile),
    });
  }

  // Nutrition methods
  async getCurrentNutritionPlan(): Promise<NutritionPlan> {
    return this.request<NutritionPlan>('/nutrition/current-plan');
  }

  async generateNutritionPlan(): Promise<NutritionPlan> {
    return this.request<NutritionPlan>('/nutrition/generate', {
      method: 'POST',
    });
  }

  async logMeal(mealData: {
    meal_type: 'breakfast' | 'lunch' | 'dinner' | 'snack';
    foods: Array<{ name: string; quantity: number; unit: string }>;
    date: string;
  }): Promise<void> {
    return this.request<void>('/nutrition/log-meal', {
      method: 'POST',
      body: JSON.stringify(mealData),
    });
  }

  // Fitness methods
  async getCurrentWorkoutPlan(): Promise<WorkoutPlan> {
    return this.request<WorkoutPlan>('/fitness/current-plan');
  }

  async generateWorkoutPlan(): Promise<WorkoutPlan> {
    return this.request<WorkoutPlan>('/fitness/generate', {
      method: 'POST',
    });
  }

  async logWorkout(workoutData: {
    workout_id: string;
    exercises_completed: Array<{
      exercise_id: string;
      sets_completed: number;
      reps_completed: number[];
      weight_used?: number[];
    }>;
    duration: number;
    date: string;
  }): Promise<void> {
    return this.request<void>('/fitness/log-workout', {
      method: 'POST',
      body: JSON.stringify(workoutData),
    });
  }

  // Progress tracking methods
  async getProgressHistory(days: number = 30): Promise<ProgressEntry[]> {
    return this.request<ProgressEntry[]>(`/progress?days=${days}`);
  }

  async logProgress(progressData: Partial<ProgressEntry>): Promise<ProgressEntry> {
    return this.request<ProgressEntry>('/progress', {
      method: 'POST',
      body: JSON.stringify(progressData),
    });
  }

  // AI insights methods
  async getAIInsights(limit: number = 10): Promise<AIInsight[]> {
    return this.request<AIInsight[]>(`/ai/insights?limit=${limit}`);
  }

  async requestAIAnalysis(): Promise<AIInsight[]> {
    return this.request<AIInsight[]>('/ai/analyze', {
      method: 'POST',
    });
  }

  async chatWithAI(message: string): Promise<{ response: string; explanation?: string }> {
    return this.request<{ response: string; explanation?: string }>('/ai/chat', {
      method: 'POST',
      body: JSON.stringify({ message }),
    });
  }

  // Subscription methods - TODO: Backend implementation needed
  async getSubscriptionStatus(): Promise<{
    tier: 'free' | 'premium' | 'enterprise';
    expires_at?: string;
    features: string[];
  }> {
    // TODO: Implement subscription endpoints in backend
    // return this.request<{
    //   tier: 'free' | 'premium' | 'enterprise';
    //   expires_at?: string;
    //   features: string[];
    // }>('/subscription/status');
    
    // Temporary mock response
    return Promise.resolve({
      tier: 'free',
      features: ['Basic nutrition plans', 'Basic workout plans', 'Progress tracking']
    });
  }

  async createSubscription(tier: 'premium' | 'enterprise'): Promise<{ checkout_url: string }> {
    // TODO: Implement subscription endpoints in backend
    // return this.request<{ checkout_url: string }>('/subscription/create', {
    //   method: 'POST',
    //   body: JSON.stringify({ tier }),
    // });
    
    // Temporary mock response
    return Promise.resolve({ checkout_url: '/subscription/checkout' });
  }
}

// Create singleton instance
export const apiClient = new APIClient();

// Mock data for offline development
export const mockData = {
  user: {
    id: '1',
    email: 'demo@nutrify.ai',
    name: 'Demo User',
    subscription_tier: 'premium' as const,
    created_at: '2024-01-01T00:00:00Z',
  },
  
  profile: {
    id: '1',
    user_id: '1',
    age: 28,
    gender: 'male' as const,
    height: 175,
    weight: 75,
    activity_level: 'moderately_active' as const,
    goals: ['weight_loss', 'muscle_gain', 'improve_fitness'],
    dietary_restrictions: ['vegetarian'],
    fitness_experience: 'intermediate' as const,
    updated_at: '2024-01-01T00:00:00Z',
  },

  insights: [
    {
      id: '1',
      user_id: '1',
      type: 'progress' as const,
      title: 'Great Progress This Week!',
      message: 'Your consistency improved by 15% this week. You\'ve logged 6 out of 7 planned workouts.',
      explanation: 'Based on your workout adherence and progressive overload data, your strength gains are accelerating.',
      action_items: ['Continue current routine', 'Consider adding 5% more weight to compound exercises'],
      created_at: '2024-01-01T00:00:00Z',
      priority: 'high' as const,
    },
    {
      id: '2',
      user_id: '1',
      type: 'nutrition' as const,
      title: 'Protein Intake Optimization',
      message: 'Your protein intake has been 20g below target for 3 days. Let\'s adjust your meal plan.',
      explanation: 'Adequate protein is crucial for muscle recovery and growth, especially given your current training volume.',
      action_items: ['Add a protein shake post-workout', 'Include more lean protein in lunch'],
      created_at: '2024-01-01T00:00:00Z',
      priority: 'medium' as const,
    },
  ],
};