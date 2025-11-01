import React from 'react';
import { Link } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { useAuth } from '@/contexts/AuthContext';
import { 
  useAIInsights, 
  useNutritionPlan, 
  useWorkoutPlan, 
  useProgressHistory,
  useGenerateNutritionPlan,
  useGenerateWorkoutPlan
} from '@/hooks/useApi';
import {
  Apple,
  Dumbbell,
  TrendingUp,
  Target,
  Flame,
  Droplets,
  Moon,
  Zap,
  ChevronRight,
  Sparkles,
  Trophy,
  Calendar,
} from 'lucide-react';

export default function Dashboard() {
  const { user } = useAuth();
  const { data: insights, isLoading: insightsLoading } = useAIInsights();
  const { data: nutritionPlan, isLoading: nutritionLoading } = useNutritionPlan();
  const { data: workoutPlan, isLoading: workoutLoading } = useWorkoutPlan();
  const { data: progressHistory, isLoading: progressLoading } = useProgressHistory(7);
  const generateNutrition = useGenerateNutritionPlan();
  const generateWorkout = useGenerateWorkoutPlan();
  
  // Get time-based greeting
  const getGreeting = () => {

    return 'Hello! ';
  };

  // Calculate today's stats from latest progress entry and nutrition plan
  const latestProgress = progressHistory?.[0];
  const calorieTarget = nutritionPlan?.daily_calories || 2200;
  const proteinTarget = nutritionPlan?.macros?.protein || 120;
  
  const todayStats = {
    calories: { 
      consumed: 0, // TODO: Track calories consumed in meals
      target: calorieTarget 
    },
    protein: { 
      consumed: 0, // TODO: Calculate from logged meals
      target: proteinTarget 
    },
    water: { 
      consumed: latestProgress?.water_intake || 0, 
      target: 2500 
    },
    steps: { 
      taken: 0, // Not tracked yet
      target: 10000 
    },
    workouts: { 
      completed: workoutPlan ? 1 : 0, 
      planned: workoutPlan ? workoutPlan.workouts?.length || 0 : 0 
    },
    sleep: { 
      hours: latestProgress?.sleep_hours || 0, 
      target: 8 
    },
  };

  // Calculate weekly progress from progress history
  const weeklyProgress = React.useMemo(() => {
    if (!progressHistory || progressHistory.length === 0) {
      return { adherence: 0, weightChange: 0, strengthGain: 0 };
    }
    
    const validEntries = progressHistory.filter(p => p.adherence_score !== undefined);
    const avgAdherence = validEntries.length > 0 
      ? validEntries.reduce((sum, p) => sum + p.adherence_score, 0) / validEntries.length 
      : 0;
    
    const weightsWithValue = progressHistory.filter(p => p.weight !== undefined && p.weight > 0);
    const weightChange = weightsWithValue.length >= 2
      ? (weightsWithValue[0].weight || 0) - (weightsWithValue[weightsWithValue.length - 1].weight || 0)
      : 0;
    
    return {
      adherence: Math.round(avgAdherence),
      weightChange: Number(weightChange.toFixed(1)),
      strengthGain: 0, // TODO: Calculate from workout logs
    };
  }, [progressHistory]);

  // Get today's upcoming workouts and meals
  const upcomingPlans = React.useMemo(() => {
    const plans: any[] = [];
    
    // Add today's workout if available
    if (workoutPlan && workoutPlan.workouts) {
      const today = new Date().toLocaleDateString('en-US', { weekday: 'long' });
      const todayWorkout = workoutPlan.workouts.find(w => w.day === today);
      if (todayWorkout) {
        plans.push({
          type: 'workout',
          title: `${todayWorkout.type} workout`,
          time: 'Scheduled',
          duration: `${todayWorkout.duration} min`,
          icon: Dumbbell,
        });
      }
    }
    
    // Add today's meals if available
    if (nutritionPlan && nutritionPlan.meals) {
      const today = new Date().toLocaleDateString('en-US', { weekday: 'long' });
      const todayMeal = nutritionPlan.meals.find(m => m.day === today);
      if (todayMeal) {
        // Add breakfast
        if (todayMeal.breakfast && todayMeal.breakfast.length > 0) {
          const breakfastCalories = todayMeal.breakfast.reduce((sum, m) => sum + m.calories, 0);
          plans.push({
            type: 'meal',
            title: 'Breakfast',
            time: 'Morning',
            calories: breakfastCalories,
            icon: Apple,
          });
        }
        // Add lunch
        if (todayMeal.lunch && todayMeal.lunch.length > 0) {
          const lunchCalories = todayMeal.lunch.reduce((sum, m) => sum + m.calories, 0);
          plans.push({
            type: 'meal',
            title: 'Lunch',
            time: 'Afternoon',
            calories: lunchCalories,
            icon: Apple,
          });
        }
      }
    }
    
    return plans;
  }, [workoutPlan, nutritionPlan]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">
            {getGreeting()}, {user?.name || 'there'}!
          </h1>
          <p className="text-muted-foreground">
            Ready to crush your goals today? Your AI coach has some insights for you.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="secondary" className="gap-1">
            <Sparkles className="h-3 w-3" />
            AI Active
          </Badge>
        </div>
      </div>

      {/* AI Insights */}
      <Card className="border-blue-200 bg-gradient-to-r from-blue-50 to-indigo-50">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-blue-600" />
            AI Coach Insights
          </CardTitle>
          <CardDescription>
            Your personalized recommendations based on recent activity
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {insightsLoading ? (
            <div className="text-center py-4 text-muted-foreground">Loading insights...</div>
          ) : insights && insights.length > 0 ? (
            insights.slice(0, 3).map((insight) => (
              <div
                key={insight.id}
                className="flex items-start gap-3 p-3 rounded-lg bg-white/60 border border-blue-100"
              >
                <div className={`w-2 h-2 rounded-full mt-2 ${
                  insight.priority === 'high' ? 'bg-green-500' : 'bg-yellow-500'
                }`} />
                <div className="flex-1">
                  <h4 className="font-medium text-sm">{insight.title}</h4>
                  <p className="text-sm text-muted-foreground">{insight.message}</p>
                </div>
              </div>
            ))
          ) : (
            <div className="text-center py-4 text-muted-foreground">
              No insights yet. Complete your profile and log some activities!
            </div>
          )}
          <Link to="/chat">
            <Button variant="outline" className="w-full mt-3">
              Chat with AI Coach
              <ChevronRight className="h-4 w-4 ml-2" />
            </Button>
          </Link>
        </CardContent>
      </Card>

      {/* Today's Overview */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Calories</CardTitle>
            <Flame className="h-4 w-4 text-orange-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {todayStats.calories.consumed}
              <span className="text-sm font-normal text-muted-foreground">
                /{todayStats.calories.target}
              </span>
            </div>
            <Progress 
              value={(todayStats.calories.consumed / todayStats.calories.target) * 100} 
              className="mt-2"
            />
            <p className="text-xs text-muted-foreground mt-2">
              {todayStats.calories.target - todayStats.calories.consumed} remaining
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Protein</CardTitle>
            <Target className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {todayStats.protein.consumed}g
              <span className="text-sm font-normal text-muted-foreground">
                /{todayStats.protein.target}g
              </span>
            </div>
            <Progress 
              value={(todayStats.protein.consumed / todayStats.protein.target) * 100} 
              className="mt-2"
            />
            <p className="text-xs text-muted-foreground mt-2">
              {Math.round(((todayStats.protein.consumed / todayStats.protein.target) * 100))}% of goal
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Hydration</CardTitle>
            <Droplets className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {(todayStats.water.consumed / 1000).toFixed(1)}L
              <span className="text-sm font-normal text-muted-foreground">
                /{(todayStats.water.target / 1000).toFixed(1)}L
              </span>
            </div>
            <Progress 
              value={(todayStats.water.consumed / todayStats.water.target) * 100} 
              className="mt-2"
            />
            <p className="text-xs text-muted-foreground mt-2">
              {((todayStats.water.target - todayStats.water.consumed) / 1000).toFixed(1)}L to go
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Activity</CardTitle>
            <Zap className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {(todayStats.steps.taken / 1000).toFixed(1)}k
              <span className="text-sm font-normal text-muted-foreground">
                /{(todayStats.steps.target / 1000).toFixed(0)}k
              </span>
            </div>
            <Progress 
              value={(todayStats.steps.taken / todayStats.steps.target) * 100} 
              className="mt-2"
            />
            <p className="text-xs text-muted-foreground mt-2">
              {todayStats.steps.target - todayStats.steps.taken} steps remaining
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Weekly Progress & Upcoming Plans */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Weekly Progress */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Trophy className="h-5 w-5 text-yellow-600" />
              Weekly Progress
            </CardTitle>
            <CardDescription>Your achievements this week</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Plan Adherence</span>
              <span className="text-sm font-bold text-green-600">{weeklyProgress.adherence}%</span>
            </div>
            <Progress value={weeklyProgress.adherence} className="h-2" />
            
            <div className="grid grid-cols-2 gap-4 pt-2">
              <div className="text-center">
                <div className="text-lg font-bold text-green-600">
                  {weeklyProgress.weightChange > 0 ? '+' : ''}{weeklyProgress.weightChange}kg
                </div>
                <div className="text-xs text-muted-foreground">Weight Change</div>
              </div>
              <div className="text-center">
                <div className="text-lg font-bold text-blue-600">+{weeklyProgress.strengthGain}%</div>
                <div className="text-xs text-muted-foreground">Strength Gain</div>
              </div>
            </div>

            <Link to="/progress">
              <Button variant="outline" className="w-full mt-4">
                View Detailed Progress
                <TrendingUp className="h-4 w-4 ml-2" />
              </Button>
            </Link>
          </CardContent>
        </Card>

        {/* Upcoming Plans */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5 text-purple-600" />
              Today's Schedule
            </CardTitle>
            <CardDescription>Your personalized plan for today</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {nutritionLoading || workoutLoading ? (
              <div className="text-center py-4 text-muted-foreground">Loading schedule...</div>
            ) : upcomingPlans.length > 0 ? (
              upcomingPlans.map((plan, index) => (
                <div key={index} className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                  <div className="p-2 rounded-lg bg-background">
                    <plan.icon className="h-4 w-4" />
                  </div>
                  <div className="flex-1">
                    <h4 className="font-medium text-sm">{plan.title}</h4>
                    <p className="text-xs text-muted-foreground">
                      {plan.time}
                      {plan.duration && ` • ${plan.duration}`}
                      {plan.calories && ` • ${plan.calories} cal`}
                    </p>
                  </div>
                </div>
              ))
            ) : (
              <div className="space-y-3">
                <div className="text-center py-4 text-muted-foreground">
                  No plans for today. Generate your personalized plans to get started!
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <Button 
                    variant="outline" 
                    size="sm" 
                    className="w-full"
                    onClick={() => generateNutrition.mutate()}
                    disabled={generateNutrition.isPending || !user}
                  >
                    <Apple className="h-4 w-4 mr-2" />
                    {generateNutrition.isPending ? 'Generating...' : 'Nutrition'}
                  </Button>
                  <Button 
                    variant="outline" 
                    size="sm" 
                    className="w-full"
                    onClick={() => generateWorkout.mutate()}
                    disabled={generateWorkout.isPending || !user}
                  >
                    <Dumbbell className="h-4 w-4 mr-2" />
                    {generateWorkout.isPending ? 'Generating...' : 'Workout'}
                  </Button>
                </div>
              </div>
            )}
            
            <div className="grid grid-cols-2 gap-2 pt-2">
              <Link to="/nutrition">
                <Button variant="outline" size="sm" className="w-full">
                  <Apple className="h-4 w-4 mr-2" />
                  View Meals
                </Button>
              </Link>
              <Link to="/fitness">
                <Button variant="outline" size="sm" className="w-full">
                  <Dumbbell className="h-4 w-4 mr-2" />
                  View Workouts
                </Button>
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
          <CardDescription>Log your activities and get instant AI feedback</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <Button variant="outline" className="h-auto p-4 flex flex-col gap-2">
              <Apple className="h-6 w-6" />
              <span className="text-sm">Log Meal</span>
            </Button>
            <Button variant="outline" className="h-auto p-4 flex flex-col gap-2">
              <Dumbbell className="h-6 w-6" />
              <span className="text-sm">Log Workout</span>
            </Button>
            <Button variant="outline" className="h-auto p-4 flex flex-col gap-2">
              <Droplets className="h-6 w-6" />
              <span className="text-sm">Log Water</span>
            </Button>
            <Button variant="outline" className="h-auto p-4 flex flex-col gap-2">
              <Moon className="h-6 w-6" />
              <span className="text-sm">Log Sleep</span>
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}