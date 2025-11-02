import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
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
  Dumbbell,
  Play,
  Pause,
  RotateCcw,
  Timer,
  Target,
  TrendingUp,
  RefreshCw,
  Sparkles,
  CheckCircle,
  Clock,
  Zap,
  Award,
  Calendar,
  Loader2,
} from 'lucide-react';
import { useWorkoutPlan, useGenerateWorkoutPlan } from '@/hooks/useApi';

interface Exercise {
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

export default function FitnessPlan() {
  const [selectedDay, setSelectedDay] = useState('monday');
  const [activeWorkout, setActiveWorkout] = useState<string | null>(null);
  const [workoutTimer, setWorkoutTimer] = useState(0);
  const [isTimerRunning, setIsTimerRunning] = useState(false);
  
  const { data: workoutPlan, isLoading, error } = useWorkoutPlan();
  const generatePlan = useGenerateWorkoutPlan();
  
  // Treat null data (404) as "no plan yet"
  const hasNoPlan = !workoutPlan && !isLoading;

  const weeklyPlan = workoutPlan;

  // TODO: Calculate progress from actual workout data
  const weeklyProgress = weeklyPlan?.workouts ? {
    workouts_completed: 0, // TODO: Track completed workouts
    total_planned: weeklyPlan.workouts.length,
    total_duration: weeklyPlan.workouts.reduce((total, w) => total + (w.duration || 0), 0),
    strength_improvement: 0, // TODO: Calculate based on performance metrics
    consistency_score: 0, // TODO: Calculate based on completion rate
  } : null;

  const days = [
    { key: 'monday', label: 'Mon', type: 'Upper Body' },
    { key: 'tuesday', label: 'Tue', type: 'Cardio' },
    { key: 'wednesday', label: 'Wed', type: 'Lower Body' },
    { key: 'thursday', label: 'Thu', type: 'Rest' },
    { key: 'friday', label: 'Fri', type: 'Full Body' },
    { key: 'saturday', label: 'Sat', type: 'Cardio' },
    { key: 'sunday', label: 'Sun', type: 'Rest' },
  ];

  const handleRegeneratePlan = async () => {
    await generatePlan.mutateAsync();
  };

  const handleStartWorkout = (workoutId: string) => {
    setActiveWorkout(workoutId);
    setIsTimerRunning(true);
    toast({
      title: 'Workout Started!',
      description: 'Good luck with your training session. Stay focused!',
    });
  };

  const handleCompleteExercise = (exerciseId: string) => {
    toast({
      title: 'Exercise Completed!',
      description: 'Great job! Move on to the next exercise when ready.',
    });
  };

  const ExerciseCard = ({ exercise, workoutType }: { exercise: Exercise; workoutType: string }) => (
    <Card className="hover:shadow-md transition-shadow">
      <CardContent className="p-4">
        <div className="flex items-start justify-between mb-3">
          <div className="flex-1">
            <h4 className="font-semibold">{exercise.name}</h4>
            <div className="flex items-center gap-4 text-sm text-muted-foreground mt-1">
              <span>{exercise.sets} sets × {exercise.reps} reps</span>
              <span className="flex items-center gap-1">
                <Timer className="h-3 w-3" />
                {exercise.rest_time}s rest
              </span>
            </div>
          </div>
          <Button
            size="sm"
            onClick={() => handleCompleteExercise(exercise.id)}
            className="shrink-0"
          >
            <CheckCircle className="h-3 w-3 mr-1" />
            Done
          </Button>
        </div>

        <div className="space-y-2 mb-3">
          <div className="text-xs font-medium text-muted-foreground">TARGET MUSCLES</div>
          <div className="flex flex-wrap gap-1">
            {exercise.muscle_groups.map((muscle: string) => (
              <Badge key={muscle} variant="secondary" className="text-xs">
                {muscle}
              </Badge>
            ))}
          </div>
        </div>

        <div className="space-y-2 mb-3">
          <div className="text-xs font-medium text-muted-foreground">EQUIPMENT</div>
          <div className="flex flex-wrap gap-1">
            {exercise.equipment.map((item: string) => (
              <Badge key={item} variant="outline" className="text-xs">
                {item}
              </Badge>
            ))}
          </div>
        </div>

        <div className="text-xs text-muted-foreground">
          <strong>Form:</strong> {exercise.instructions}
        </div>
      </CardContent>
    </Card>
  );

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin mx-auto mb-4 text-green-600" />
          <p className="text-muted-foreground">Loading your workout plan...</p>
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
            <CardTitle className="text-center">No Workout Plan Yet</CardTitle>
            <CardDescription className="text-center">
              Generate your first AI-powered workout plan tailored to your fitness level
            </CardDescription>
          </CardHeader>
          <CardContent className="text-center">
            <Button onClick={handleRegeneratePlan} disabled={generatePlan.isPending}>
              <Sparkles className="h-4 w-4 mr-2" />
              {generatePlan.isPending ? 'Generating...' : 'Generate Workout Plan'}
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
          <h1 className="text-3xl font-bold tracking-tight">Fitness Plan</h1>
          <p className="text-muted-foreground">
            AI-optimized workouts adapted to your progress and goals
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="secondary" className="gap-1">
            <Sparkles className="h-3 w-3" />
            AI Optimized
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
        <Card className="border-green-200 bg-green-50">
          <CardContent className="p-4">
            <div className="flex items-start gap-3">
              <TrendingUp className="h-5 w-5 text-green-600 mt-0.5" />
              <div>
                <h4 className="font-medium text-green-900">Plan Adapted</h4>
                <p className="text-sm text-green-800 mt-1">{weeklyPlan.adaptation_reason}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Weekly Progress */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Workouts</CardTitle>
            <Dumbbell className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {weeklyProgress.workouts_completed}/{weeklyProgress.total_planned}
            </div>
            <Progress 
              value={(weeklyProgress.workouts_completed / weeklyProgress.total_planned) * 100} 
              className="mt-2"
            />
            <p className="text-xs text-muted-foreground mt-2">
              {weeklyProgress.total_planned - weeklyProgress.workouts_completed} remaining this week
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Training Time</CardTitle>
            <Clock className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{Math.floor(weeklyProgress.total_duration / 60)}h {weeklyProgress.total_duration % 60}m</div>
            <p className="text-xs text-muted-foreground mt-2">
              This week's total
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Strength Gain</CardTitle>
            <TrendingUp className="h-4 w-4 text-purple-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-purple-600">+{weeklyProgress.strength_improvement}%</div>
            <p className="text-xs text-muted-foreground mt-2">
              Compared to last month
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Consistency</CardTitle>
            <Award className="h-4 w-4 text-yellow-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-600">{weeklyProgress.consistency_score}%</div>
            <Progress value={weeklyProgress.consistency_score} className="mt-2" />
            <p className="text-xs text-muted-foreground mt-2">
              Excellent consistency!
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Weekly Schedule */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Weekly Schedule
          </CardTitle>
          <CardDescription>
            Your personalized workout plan • Difficulty Level {weeklyPlan.difficulty_level}/10
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={selectedDay} onValueChange={setSelectedDay}>
            <TabsList className="grid w-full grid-cols-7">
              {days.map((day) => (
                <TabsTrigger key={day.key} value={day.key} className="text-xs flex flex-col gap-1">
                  <span>{day.label}</span>
                  <span className="text-xs text-muted-foreground">{day.type}</span>
                </TabsTrigger>
              ))}
            </TabsList>

            <TabsContent value={selectedDay} className="mt-6">
              {weeklyPlan?.workouts?.find(workout => workout.day?.toLowerCase() === selectedDay) ? (
                <div className="space-y-6">
                  {/* Workout Header */}
                  <div className="flex items-center justify-between p-4 bg-muted/50 rounded-lg">
                    <div>
                      <h3 className="text-lg font-semibold capitalize">
                        {weeklyPlan.workouts.find(w => w.day?.toLowerCase() === selectedDay)?.type} Training
                      </h3>
                      <p className="text-sm text-muted-foreground">
                        Estimated duration: {weeklyPlan.workouts.find(w => w.day?.toLowerCase() === selectedDay)?.duration} minutes
                      </p>
                    </div>
                    <Button
                      onClick={() => handleStartWorkout(selectedDay)}
                      disabled={activeWorkout === selectedDay}
                    >
                      {activeWorkout === selectedDay ? (
                        <>
                          <Pause className="h-4 w-4 mr-2" />
                          In Progress
                        </>
                      ) : (
                        <>
                          <Play className="h-4 w-4 mr-2" />
                          Start Workout
                        </>
                      )}
                    </Button>
                  </div>

                  {/* Exercise List */}
                  <div className="space-y-4">
                    <h4 className="font-semibold">
                      Exercises ({weeklyPlan.workouts.find(w => w.day?.toLowerCase() === selectedDay)?.exercises?.length || 0})
                    </h4>
                    <div className="grid gap-4">
                      {weeklyPlan.workouts.find(w => w.day?.toLowerCase() === selectedDay)?.exercises?.map((exercise, index) => (
                        <div key={exercise.id} className="flex items-start gap-4">
                          <div className="flex items-center justify-center w-8 h-8 rounded-full bg-primary text-primary-foreground text-sm font-medium">
                            {index + 1}
                          </div>
                          <div className="flex-1">
                            <ExerciseCard 
                              exercise={exercise} 
                              workoutType={weeklyPlan.workouts.find(w => w.day?.toLowerCase() === selectedDay)?.type || 'strength'} 
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                <div className="text-center py-12">
                  <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-muted flex items-center justify-center">
                    <RotateCcw className="h-8 w-8 text-muted-foreground" />
                  </div>
                  <h3 className="text-lg font-semibold mb-2">Rest Day</h3>
                  <p className="text-muted-foreground mb-4">
                    Take time to recover and let your muscles rebuild stronger.
                  </p>
                  <div className="space-y-2">
                    <p className="text-sm text-muted-foreground">Suggested activities:</p>
                    <div className="flex flex-wrap justify-center gap-2">
                      <Badge variant="outline">Light stretching</Badge>
                      <Badge variant="outline">Walking</Badge>
                      <Badge variant="outline">Meditation</Badge>
                      <Badge variant="outline">Foam rolling</Badge>
                    </div>
                  </div>
                </div>
              )}
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Workout Tools</CardTitle>
            <CardDescription>Enhance your training experience</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button className="w-full" variant="outline">
              <Timer className="h-4 w-4 mr-2" />
              Rest Timer
            </Button>
            <Button className="w-full" variant="outline">
              <Target className="h-4 w-4 mr-2" />
              Form Guide
            </Button>
            <Button className="w-full" variant="outline">
              <Zap className="h-4 w-4 mr-2" />
              Quick Log
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">AI Coaching</CardTitle>
            <CardDescription>Get personalized guidance</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button className="w-full" variant="outline">
              <Sparkles className="h-4 w-4 mr-2" />
              Ask AI Coach
            </Button>
            <Button className="w-full" variant="outline">
              <TrendingUp className="h-4 w-4 mr-2" />
              Progress Analysis
            </Button>
            <Button className="w-full" variant="outline">
              <RefreshCw className="h-4 w-4 mr-2" />
              Adapt Difficulty
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}