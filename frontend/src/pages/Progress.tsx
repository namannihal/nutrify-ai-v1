import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  TrendingUp,
  TrendingDown,
  Target,
  Calendar,
  Award,
  Zap,
  Heart,
  Moon,
  Droplets,
  Scale,
  Camera,
  Plus,
  BarChart3,
  LineChart,
  Activity,
  LucideIcon,
  Loader2,
} from 'lucide-react';
import { useProgressHistory, useLogProgress, useAIInsights } from '@/hooks/useApi';

interface StatCardProps {
  title: string;
  value: number;
  change: number;
  trend: 'up' | 'down';
  icon: LucideIcon;
  unit?: string;
}

export default function Progress() {
  const [selectedPeriod, setSelectedPeriod] = useState('30');
  const [activeTab, setActiveTab] = useState('overview');
  
  const { data: progressHistory, isLoading: progressLoading } = useProgressHistory(parseInt(selectedPeriod));
  const { data: aiInsights, isLoading: insightsLoading } = useAIInsights(5);
  const logProgress = useLogProgress();

  // Calculate progress stats from actual data
  const progressStats = React.useMemo(() => {
    if (!progressHistory || progressHistory.length === 0) {
      return {
        weight: { current: 0, change: 0, goal: 0, trend: 'down' as const },
        bodyFat: { current: 0, change: 0, trend: 'down' as const },
        muscle: { current: 0, change: 0, trend: 'up' as const },
        strength: { current: 0, change: 0, trend: 'up' as const },
      };
    }

    const latestEntry = progressHistory[0];
    const oldestEntry = progressHistory[progressHistory.length - 1];
    
    const weightChange = (latestEntry.weight || 0) - (oldestEntry.weight || 0);
    const bodyFatChange = (latestEntry.body_fat || 0) - (oldestEntry.body_fat || 0);
    
    return {
      weight: {
        current: latestEntry.weight || 0,
        change: weightChange,
        goal: 0, // TODO: Get from user profile goals
        trend: (weightChange < 0 ? 'down' : 'up') as 'up' | 'down',
      },
      bodyFat: {
        current: latestEntry.body_fat || 0,
        change: bodyFatChange,
        trend: (bodyFatChange < 0 ? 'down' : 'up') as 'up' | 'down',
      },
      muscle: {
        current: 0, // TODO: Calculate from body composition
        change: 0,
        trend: 'up' as const,
      },
      strength: {
        current: Math.round((progressHistory.reduce((sum, p) => sum + p.adherence_score, 0) / progressHistory.length) || 0),
        change: 0, // TODO: Calculate from workout logs
        trend: 'up' as const,
      },
    };
  }, [progressHistory]);

  // Calculate weekly metrics from progress history
  const weeklyMetrics = React.useMemo(() => {
    if (!progressHistory || progressHistory.length === 0) return [];
    
    const weeks = Math.min(4, Math.ceil(progressHistory.length / 7));
    const metrics = [];
    
    for (let i = 0; i < weeks; i++) {
      const weekData = progressHistory.slice(i * 7, (i + 1) * 7);
      if (weekData.length === 0) continue;
      
      metrics.push({
        week: `Week ${weeks - i}`,
        adherence: Math.round(weekData.reduce((sum, p) => sum + p.adherence_score, 0) / weekData.length),
        weight: Number((weekData.reduce((sum, p) => sum + (p.weight || 0), 0) / weekData.length).toFixed(1)),
        energy: Number((weekData.reduce((sum, p) => sum + p.energy, 0) / weekData.length).toFixed(1)),
        mood: Number((weekData.reduce((sum, p) => sum + p.mood, 0) / weekData.length).toFixed(1)),
      });
    }
    
    return metrics.reverse();
  }, [progressHistory]);

  // Calculate achievements based on actual progress
  const achievements = React.useMemo(() => {
    if (!progressHistory || progressHistory.length === 0) return [];
    
    const achievementList = [];
    
    // Check for consistency (7 days with adherence > 80%)
    const recentWeek = progressHistory.slice(0, 7);
    const consistentDays = recentWeek.filter(p => p.adherence_score >= 80).length;
    achievementList.push({
      id: '1',
      title: 'Consistency Champion',
      description: '7 days straight of hitting your goals',
      icon: Award,
      earned: consistentDays >= 7,
      date: consistentDays >= 7 ? recentWeek[0]?.date : undefined,
      progress: Math.round((consistentDays / 7) * 100),
    });
    
    // Check for hydration (14 days with water >= 2000ml)
    const recentTwoWeeks = progressHistory.slice(0, 14);
    const hydrationDays = recentTwoWeeks.filter(p => p.water_intake >= 2000).length;
    achievementList.push({
      id: '3',
      title: 'Hydration Hero',
      description: 'Perfect water intake for 14 days',
      icon: Droplets,
      earned: hydrationDays >= 14,
      date: hydrationDays >= 14 ? recentTwoWeeks[0]?.date : undefined,
      progress: Math.round((hydrationDays / 14) * 100),
    });
    
    // Check for sleep (30 days with >= 7 hours)
    const recentMonth = progressHistory.slice(0, 30);
    const sleepDays = recentMonth.filter(p => p.sleep_hours >= 7).length;
    achievementList.push({
      id: '4',
      title: 'Sleep Master',
      description: 'Optimal sleep for 30 days',
      icon: Moon,
      earned: sleepDays >= 30,
      date: sleepDays >= 30 ? recentMonth[0]?.date : undefined,
      progress: Math.round((sleepDays / 30) * 100),
    });
    
    return achievementList;
  }, [progressHistory]);

  // Use actual progress history as recent entries
  const recentEntries = React.useMemo(() => {
    if (!progressHistory) return [];
    return progressHistory.slice(0, 10).map(entry => ({
      date: entry.date,
      weight: entry.weight || 0,
      mood: entry.mood,
      energy: entry.energy,
      sleep: entry.sleep_hours,
      water: entry.water_intake,
      adherence: entry.adherence_score,
    }));
  }, [progressHistory]);

  const handleLogProgress = async (data: any) => {
    await logProgress.mutateAsync({
      date: new Date().toISOString(),
      ...data,
    });
  };

  const StatCard = ({ 
    title, 
    value, 
    change, 
    trend, 
    icon: Icon, 
    unit = '' 
  }: StatCardProps) => (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">
          {value}{unit}
        </div>
        <div className={`flex items-center text-xs ${
          trend === 'up' ? 'text-green-600' : 'text-red-600'
        }`}>
          {trend === 'up' ? (
            <TrendingUp className="h-3 w-3 mr-1" />
          ) : (
            <TrendingDown className="h-3 w-3 mr-1" />
          )}
          {Math.abs(change)}{unit} from last month
        </div>
      </CardContent>
    </Card>
  );

  if (progressLoading || insightsLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin mx-auto mb-4 text-blue-600" />
          <p className="text-muted-foreground">Loading your progress data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Progress Tracking</h1>
          <p className="text-muted-foreground">
            Monitor your journey and celebrate your achievements
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={selectedPeriod} onValueChange={setSelectedPeriod}>
            <SelectTrigger className="w-32">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7">7 days</SelectItem>
              <SelectItem value="30">30 days</SelectItem>
              <SelectItem value="90">90 days</SelectItem>
              <SelectItem value="365">1 year</SelectItem>
            </SelectContent>
          </Select>
          <Dialog>
            <DialogTrigger asChild>
              <Button>
                <Plus className="h-4 w-4 mr-2" />
                Log Progress
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Log Your Progress</DialogTitle>
                <DialogDescription>
                  Record your measurements and how you're feeling today.
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="weight">Weight (kg)</Label>
                    <Input id="weight" type="number" step="0.1" placeholder="74.2" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="body-fat">Body Fat (%)</Label>
                    <Input id="body-fat" type="number" step="0.1" placeholder="15.2" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="mood">Mood (1-10)</Label>
                    <Input id="mood" type="number" min="1" max="10" placeholder="8" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="energy">Energy (1-10)</Label>
                    <Input id="energy" type="number" min="1" max="10" placeholder="8" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="sleep">Sleep (hours)</Label>
                    <Input id="sleep" type="number" step="0.5" placeholder="7.5" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="water">Water (ml)</Label>
                    <Input id="water" type="number" placeholder="2400" />
                  </div>
                </div>
                <Button onClick={handleLogProgress} className="w-full">
                  Log Progress
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="body">Body Metrics</TabsTrigger>
          <TabsTrigger value="performance">Performance</TabsTrigger>
          <TabsTrigger value="achievements">Achievements</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          {/* Key Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <StatCard
              title="Weight"
              value={progressStats.weight.current}
              change={progressStats.weight.change}
              trend={progressStats.weight.trend}
              icon={Scale}
              unit="kg"
            />
            <StatCard
              title="Body Fat"
              value={progressStats.bodyFat.current}
              change={progressStats.bodyFat.change}
              trend={progressStats.bodyFat.trend}
              icon={Target}
              unit="%"
            />
            <StatCard
              title="Muscle Mass"
              value={progressStats.muscle.current}
              change={progressStats.muscle.change}
              trend={progressStats.muscle.trend}
              icon={Zap}
              unit="kg"
            />
            <StatCard
              title="Strength Score"
              value={progressStats.strength.current}
              change={progressStats.strength.change}
              trend={progressStats.strength.trend}
              icon={TrendingUp}
            />
          </div>

          {/* Weekly Trends */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <LineChart className="h-5 w-5" />
                Weekly Trends
              </CardTitle>
              <CardDescription>Your progress over the last 4 weeks</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {weeklyMetrics.map((week, index) => (
                  <div key={week.week} className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
                    <div className="font-medium">{week.week}</div>
                    <div className="grid grid-cols-4 gap-4 text-sm">
                      <div className="text-center">
                        <div className="font-semibold">{week.adherence}%</div>
                        <div className="text-muted-foreground">Adherence</div>
                      </div>
                      <div className="text-center">
                        <div className="font-semibold">{week.weight}kg</div>
                        <div className="text-muted-foreground">Weight</div>
                      </div>
                      <div className="text-center">
                        <div className="font-semibold">{week.energy}/10</div>
                        <div className="text-muted-foreground">Energy</div>
                      </div>
                      <div className="text-center">
                        <div className="font-semibold">{week.mood}/10</div>
                        <div className="text-muted-foreground">Mood</div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Recent Entries */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calendar className="h-5 w-5" />
                Recent Entries
              </CardTitle>
              <CardDescription>Your latest progress logs</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {recentEntries.length > 0 ? (
                  recentEntries.map((entry, index) => (
                    <div key={entry.date} className="flex items-center justify-between p-3 rounded-lg border">
                      <div className="font-medium">{new Date(entry.date).toLocaleDateString()}</div>
                      <div className="flex items-center gap-6 text-sm">
                        {entry.weight > 0 && (
                          <div className="flex items-center gap-1">
                            <Scale className="h-3 w-3" />
                            {entry.weight}kg
                          </div>
                        )}
                        <div className="flex items-center gap-1">
                          <Heart className="h-3 w-3" />
                          {entry.mood}/10
                        </div>
                        <div className="flex items-center gap-1">
                          <Zap className="h-3 w-3" />
                          {entry.energy}/10
                        </div>
                        <div className="flex items-center gap-1">
                          <Moon className="h-3 w-3" />
                          {entry.sleep}h
                        </div>
                        <div className="flex items-center gap-1">
                          <Activity className="h-3 w-3" />
                          {entry.adherence}%
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    No progress entries yet. Click "Log Progress" to get started!
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="body" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Body Composition Tracking</CardTitle>
              <CardDescription>Monitor changes in your body composition over time</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-12">
                <Camera className="h-16 w-16 mx-auto text-muted-foreground mb-4" />
                <h3 className="text-lg font-semibold mb-2">Body Composition Analysis</h3>
                <p className="text-muted-foreground mb-4">
                  Take progress photos and get AI-powered body composition analysis
                </p>
                <Button variant="outline">
                  <Camera className="h-4 w-4 mr-2" />
                  Take Progress Photo
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="performance" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Performance Metrics</CardTitle>
              <CardDescription>Track your fitness performance improvements</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-12">
                <BarChart3 className="h-16 w-16 mx-auto text-muted-foreground mb-4" />
                <h3 className="text-lg font-semibold mb-2">Performance Analytics</h3>
                <p className="text-muted-foreground mb-4">
                  Detailed charts and analytics for your workout performance
                </p>
                <Button variant="outline">
                  <BarChart3 className="h-4 w-4 mr-2" />
                  View Detailed Analytics
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="achievements" className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {achievements.map((achievement) => (
              <Card key={achievement.id} className={achievement.earned ? 'border-yellow-200 bg-yellow-50' : ''}>
                <CardContent className="p-4">
                  <div className="flex items-start gap-3">
                    <div className={`p-2 rounded-lg ${
                      achievement.earned ? 'bg-yellow-100' : 'bg-muted'
                    }`}>
                      <achievement.icon className={`h-5 w-5 ${
                        achievement.earned ? 'text-yellow-600' : 'text-muted-foreground'
                      }`} />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h4 className="font-semibold">{achievement.title}</h4>
                        {achievement.earned && (
                          <Badge variant="secondary" className="text-xs">
                            Earned
                          </Badge>
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground mb-2">
                        {achievement.description}
                      </p>
                      {achievement.earned ? (
                        <p className="text-xs text-muted-foreground">
                          Earned on {achievement.date}
                        </p>
                      ) : (
                        <div className="space-y-1">
                          <div className="flex justify-between text-xs">
                            <span>Progress</span>
                            <span>{achievement.progress}%</span>
                          </div>
                          <div className="w-full bg-muted rounded-full h-1.5">
                            <div 
                              className="bg-primary h-1.5 rounded-full transition-all duration-300"
                              style={{ width: `${achievement.progress}%` }}
                            />
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}