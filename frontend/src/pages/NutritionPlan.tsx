import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { toast } from '@/components/ui/use-toast';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import {
  Apple,
  Plus,
  Clock,
  Users,
  Zap,
  Target,
  Camera,
  RefreshCw,
  ChefHat,
  Sparkles,
  CheckCircle,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { useNutritionPlan, useGenerateNutritionPlan } from '@/hooks/useApi';

interface Meal {
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

export default function NutritionPlan() {
  const [selectedDay, setSelectedDay] = useState('monday');
  const { data: nutritionPlan, isLoading, error } = useNutritionPlan();
  const generatePlan = useGenerateNutritionPlan();
  
  // Treat null data (404) as "no plan yet"
  const hasNoPlan = !nutritionPlan && !isLoading;

  const weeklyPlan = nutritionPlan;

  // TODO: Calculate today's progress from logged meals
  const todayProgress = weeklyPlan ? {
    calories: { consumed: 0, target: weeklyPlan.daily_calories },
    protein: { consumed: 0, target: weeklyPlan.macros.protein },
    carbs: { consumed: 0, target: weeklyPlan.macros.carbs },
    fat: { consumed: 0, target: weeklyPlan.macros.fat },
  } : null;

  const days = [
    { key: 'monday', label: 'Mon' },
    { key: 'tuesday', label: 'Tue' },
    { key: 'wednesday', label: 'Wed' },
    { key: 'thursday', label: 'Thu' },
    { key: 'friday', label: 'Fri' },
    { key: 'saturday', label: 'Sat' },
    { key: 'sunday', label: 'Sun' },
  ];

  const handleRegeneratePlan = async () => {
    await generatePlan.mutateAsync();
  };

  const handleLogMeal = (mealType: string, meal: Meal) => {
    toast({
      title: 'Meal Logged!',
      description: `${meal.name} has been added to your ${mealType} log.`,
    });
  };

  const MealCard = ({ meal, mealType }: { meal: Meal; mealType: string }) => (
    <Card className="hover:shadow-md transition-shadow">
      <CardContent className="p-4">
        <div className="flex items-start justify-between mb-3">
          <div>
            <h4 className="font-semibold">{meal.name}</h4>
            <div className="flex items-center gap-2 text-sm text-muted-foreground mt-1">
              <Clock className="h-3 w-3" />
              {meal.prep_time} min
            </div>
          </div>
          <Button
            size="sm"
            onClick={() => handleLogMeal(mealType, meal)}
            className="shrink-0"
          >
            <Plus className="h-3 w-3 mr-1" />
            Log
          </Button>
        </div>

        <div className="grid grid-cols-4 gap-2 mb-3">
          <div className="text-center">
            <div className="text-sm font-semibold">{meal.calories}</div>
            <div className="text-xs text-muted-foreground">cal</div>
          </div>
          <div className="text-center">
            <div className="text-sm font-semibold text-blue-600">{meal.protein}g</div>
            <div className="text-xs text-muted-foreground">protein</div>
          </div>
          <div className="text-center">
            <div className="text-sm font-semibold text-green-600">{meal.carbs}g</div>
            <div className="text-xs text-muted-foreground">carbs</div>
          </div>
          <div className="text-center">
            <div className="text-sm font-semibold text-orange-600">{meal.fat}g</div>
            <div className="text-xs text-muted-foreground">fat</div>
          </div>
        </div>

        <div className="text-xs text-muted-foreground">
          <strong>Ingredients:</strong> {meal.ingredients.join(', ')}
        </div>
      </CardContent>
    </Card>
  );

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin mx-auto mb-4 text-blue-600" />
          <p className="text-muted-foreground">Loading your nutrition plan...</p>
        </div>
      </div>
    );
  }

  // Show empty state if no plan exists or there's an error
  if (hasNoPlan || error) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Card className="w-full max-w-md">
          <CardHeader>
            <CardTitle className="text-center">No Nutrition Plan Yet</CardTitle>
            <CardDescription className="text-center">
              Generate your first AI-powered nutrition plan tailored to your goals
            </CardDescription>
          </CardHeader>
          <CardContent className="text-center">
            <Button onClick={handleRegeneratePlan} disabled={generatePlan.isPending}>
              <Sparkles className="h-4 w-4 mr-2" />
              {generatePlan.isPending ? 'Generating...' : 'Generate Nutrition Plan'}
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Nutrition Plan</h1>
          <p className="text-muted-foreground">
            AI-generated meal plan tailored to your goals and preferences
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="secondary" className="gap-1">
            <Sparkles className="h-3 w-3" />
            AI Generated
          </Badge>
          <Button
            variant="outline"
            onClick={handleRegeneratePlan}
            disabled={generatePlan.isPending || isLoading}
          >
            <RefreshCw className={`h-4 w-4 mr-2 ${generatePlan.isPending ? 'animate-spin' : ''}`} />
            {generatePlan.isPending ? 'Regenerating...' : 'Regenerate Plan'}
          </Button>
        </div>
      </div>

      {/* AI Adaptation Notice */}
      {weeklyPlan.adaptation_reason && (
        <Card className="border-blue-200 bg-blue-50">
          <CardContent className="p-4">
            <div className="flex items-start gap-3">
              <Sparkles className="h-5 w-5 text-blue-600 mt-0.5" />
              <div>
                <h4 className="font-medium text-blue-900">Plan Adapted</h4>
                <p className="text-sm text-blue-800 mt-1">{weeklyPlan.adaptation_reason}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Today's Progress */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Target className="h-5 w-5" />
            Today's Progress
          </CardTitle>
          <CardDescription>Track your daily macro and calorie intake</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Calories</span>
                <span>{todayProgress.calories.consumed}/{todayProgress.calories.target}</span>
              </div>
              <Progress value={(todayProgress.calories.consumed / todayProgress.calories.target) * 100} />
            </div>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Protein</span>
                <span className="text-blue-600">{todayProgress.protein.consumed}g/{todayProgress.protein.target}g</span>
              </div>
              <Progress value={(todayProgress.protein.consumed / todayProgress.protein.target) * 100} />
            </div>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Carbs</span>
                <span className="text-green-600">{todayProgress.carbs.consumed}g/{todayProgress.carbs.target}g</span>
              </div>
              <Progress value={(todayProgress.carbs.consumed / todayProgress.carbs.target) * 100} />
            </div>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Fat</span>
                <span className="text-orange-600">{todayProgress.fat.consumed}g/{todayProgress.fat.target}g</span>
              </div>
              <Progress value={(todayProgress.fat.consumed / todayProgress.fat.target) * 100} />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Weekly Plan */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <ChefHat className="h-5 w-5" />
            Weekly Meal Plan
          </CardTitle>
          <CardDescription>
            Your personalized meals for the week • {weeklyPlan.daily_calories} calories/day
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={selectedDay} onValueChange={setSelectedDay}>
            <TabsList className="grid w-full grid-cols-7">
              {days.map((day) => (
                <TabsTrigger key={day.key} value={day.key} className="text-xs">
                  {day.label}
                </TabsTrigger>
              ))}
            </TabsList>

            <TabsContent value={selectedDay} className="mt-6">
              <div className="space-y-6">
                {/* Breakfast */}
                <div>
                  <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-yellow-500"></div>
                    Breakfast
                  </h3>
                  <div className="grid gap-3">
                    {weeklyPlan?.meals?.find(meal => meal.day?.toLowerCase() === selectedDay)?.breakfast?.map((meal) => (
                      <MealCard key={meal.id} meal={meal} mealType="breakfast" />
                    )) || (
                      <div className="text-center py-8 text-gray-500">
                        No breakfast meals planned for {selectedDay}
                      </div>
                    )}
                  </div>
                </div>

                {/* Lunch */}
                <div>
                  <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-green-500"></div>
                    Lunch
                  </h3>
                  <div className="grid gap-3">
                    {weeklyPlan?.meals?.find(meal => meal.day?.toLowerCase() === selectedDay)?.lunch?.map((meal) => (
                      <MealCard key={meal.id} meal={meal} mealType="lunch" />
                    )) || (
                      <div className="text-center py-8 text-gray-500">
                        No lunch meals planned for {selectedDay}
                      </div>
                    )}
                  </div>
                </div>

                {/* Dinner */}
                <div>
                  <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-blue-500"></div>
                    Dinner
                  </h3>
                  <div className="grid gap-3">
                    {weeklyPlan?.meals?.find(meal => meal.day?.toLowerCase() === selectedDay)?.dinner?.map((meal) => (
                      <MealCard key={meal.id} meal={meal} mealType="dinner" />
                    )) || (
                      <div className="text-center py-8 text-gray-500">
                        No dinner meals planned for {selectedDay}
                      </div>
                    )}
                  </div>
                </div>

                {/* Snacks */}
                <div>
                  <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-purple-500"></div>
                    Snacks
                  </h3>
                  <div className="grid gap-3">
                    {weeklyPlan?.meals?.find(meal => meal.day?.toLowerCase() === selectedDay)?.snacks?.map((meal) => (
                      <MealCard key={meal.id} meal={meal} mealType="snack" />
                    )) || (
                      <div className="text-center py-8 text-gray-500">
                        No snacks planned for {selectedDay}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Quick Log</CardTitle>
            <CardDescription>Log meals quickly with AI assistance</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <Dialog>
              <DialogTrigger asChild>
                <Button className="w-full" variant="outline">
                  <Camera className="h-4 w-4 mr-2" />
                  Scan Food with Camera
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Food Recognition</DialogTitle>
                  <DialogDescription>
                    Take a photo of your meal and our AI will identify the food and estimate nutrition.
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="border-2 border-dashed border-muted-foreground/25 rounded-lg p-8 text-center">
                    <Camera className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                    <p className="text-sm text-muted-foreground">Camera feature coming soon!</p>
                    <p className="text-xs text-muted-foreground mt-1">
                      This will use OCR and AI to automatically log your meals
                    </p>
                  </div>
                </div>
              </DialogContent>
            </Dialog>

            <Dialog>
              <DialogTrigger asChild>
                <Button className="w-full" variant="outline">
                  <Plus className="h-4 w-4 mr-2" />
                  Manual Food Entry
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Log Food Manually</DialogTitle>
                  <DialogDescription>
                    Enter food details and our AI will calculate nutrition information.
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="food-name">Food Name</Label>
                    <Input id="food-name" placeholder="e.g., Grilled chicken breast" />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="quantity">Quantity</Label>
                      <Input id="quantity" type="number" placeholder="1" />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="unit">Unit</Label>
                      <Input id="unit" placeholder="piece, cup, oz" />
                    </div>
                  </div>
                  <Button className="w-full">
                    <Sparkles className="h-4 w-4 mr-2" />
                    Analyze with AI
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Meal Prep Assistant</CardTitle>
            <CardDescription>Get AI help with meal preparation</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button className="w-full" variant="outline">
              <Users className="h-4 w-4 mr-2" />
              Generate Shopping List
            </Button>
            <Button className="w-full" variant="outline">
              <Clock className="h-4 w-4 mr-2" />
              Meal Prep Schedule
            </Button>
            <Button className="w-full" variant="outline">
              <Zap className="h-4 w-4 mr-2" />
              Suggest Substitutions
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}