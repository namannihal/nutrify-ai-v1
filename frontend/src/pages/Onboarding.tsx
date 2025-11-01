import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Checkbox } from '@/components/ui/checkbox';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { toast } from '@/components/ui/use-toast';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  User,
  Target,
  Activity,
  Apple,
  Shield,
  Sparkles,
  ChevronRight,
  ChevronLeft,
} from 'lucide-react';
import { apiClient } from '@/services/api';
import { useAuth } from '@/contexts/AuthContext';

interface OnboardingData {
  // Personal Info
  age: string;
  gender: string;
  height: string;
  heightUnit: 'cm' | 'ft';
  heightFeet: string;
  heightInches: string;
  weight: string;
  weightUnit: 'kg' | 'lbs';
  
  // Goals & Preferences
  primaryGoal: string;
  secondaryGoals: string[];
  activityLevel: string;
  fitnessExperience: string;
  
  // Dietary Info
  dietaryRestrictions: string[];
  allergies: string;
  mealsPerDay: string;
  cookingTime: string;
  
  // Lifestyle
  workoutDays: string;
  workoutDuration: string;
  preferredWorkoutTime: string;
  equipmentAccess: string[];
  
  // Privacy & Consent
  dataConsent: boolean;
  marketingConsent: boolean;
  healthDisclaimer: boolean;
}

const initialData: OnboardingData = {
  age: '',
  gender: '',
  height: '',
  heightUnit: 'cm',
  heightFeet: '',
  heightInches: '',
  weight: '',
  weightUnit: 'kg',
  primaryGoal: '',
  secondaryGoals: [],
  activityLevel: '',
  fitnessExperience: '',
  dietaryRestrictions: [],
  allergies: '',
  mealsPerDay: '',
  cookingTime: '',
  workoutDays: '',
  workoutDuration: '',
  preferredWorkoutTime: '',
  equipmentAccess: [],
  dataConsent: false,
  marketingConsent: false,
  healthDisclaimer: false,
};

const steps = [
  { id: 1, title: 'Personal Info', icon: User, description: 'Tell us about yourself' },
  { id: 2, title: 'Goals', icon: Target, description: 'What do you want to achieve?' },
  { id: 3, title: 'Activity', icon: Activity, description: 'Your fitness background' },
  { id: 4, title: 'Nutrition', icon: Apple, description: 'Dietary preferences' },
  { id: 5, title: 'Privacy', icon: Shield, description: 'Data consent & privacy' },
];

export default function Onboarding() {
  const navigate = useNavigate();
  const auth = useAuth();
  const [currentStep, setCurrentStep] = useState(1);
  const [data, setData] = useState<OnboardingData>(initialData);
  const [isLoading, setIsLoading] = useState(false);

  const updateData = (field: keyof OnboardingData, value: string | boolean) => {
    setData(prev => ({ ...prev, [field]: value }));
  };

  const updateArrayField = (field: keyof OnboardingData, value: string, checked: boolean) => {
    setData(prev => ({
      ...prev,
      [field]: checked
        ? [...(prev[field] as string[]), value]
        : (prev[field] as string[]).filter(item => item !== value)
    }));
  };

  const nextStep = () => {
    if (currentStep < steps.length) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSubmit = async () => {
    setIsLoading(true);
    
    try {
      // Convert height to cm if in ft/in
      let heightInCm = parseFloat(data.height);
      if (data.heightUnit === 'ft') {
        const feet = parseFloat(data.heightFeet) || 0;
        const inches = parseFloat(data.heightInches) || 0;
        heightInCm = (feet * 30.48) + (inches * 2.54);
      }
      
      // Convert weight to kg if in lbs
      let weightInKg = parseFloat(data.weight);
      if (data.weightUnit === 'lbs') {
        weightInKg = weightInKg * 0.453592;
      }
      
      // Prepare profile data for backend
      const profileData: any = {
        age: parseInt(data.age),
        gender: data.gender,
        height: heightInCm,
        weight: weightInKg,
        primary_goal: data.primaryGoal,
        secondary_goals: data.secondaryGoals,
        activity_level: data.activityLevel,
        fitness_experience: data.fitnessExperience,
        dietary_restrictions: data.dietaryRestrictions,
        allergies: data.allergies,
        meals_per_day: parseInt(data.mealsPerDay),
        cooking_time: data.cookingTime,
        workout_days_per_week: data.workoutDays,
        workout_duration: data.workoutDuration,
        preferred_workout_time: data.preferredWorkoutTime,
        equipment_access: data.equipmentAccess,
        data_consent: data.dataConsent,
        marketing_consent: data.marketingConsent,
        health_disclaimer: data.healthDisclaimer,
        onboarding_completed: true,
      };
      
      // Send profile to backend
      await apiClient.updateUserProfile(profileData);

      // Refresh auth context so app knows onboarding is completed server-side
      try {
        await auth.refreshUser();
      } catch (e) {
        // swallow - if refresh fails we'll still navigate and app will try again later
        console.warn('Could not refresh auth context:', e);
      }
      
      toast({
        title: 'Welcome to Nutrify-AI!',
        description: 'Your personalized AI coach is being prepared...',
      });
      
  // Store onboarding completion locally for immediate UX fallback
  localStorage.setItem('onboarding_completed', 'true');
      
      navigate('/dashboard');
    } catch (error) {
      console.error('Onboarding error:', error);
      toast({
        title: 'Setup Error',
        description: 'There was an issue setting up your profile. Please try again.',
        variant: 'destructive',
      });
    } finally {
      setIsLoading(false);
    }
  };

  const renderStepContent = () => {
    switch (currentStep) {
      case 1: {
        return (
          <div className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="age">Age</Label>
              <Input
                id="age"
                type="number"
                value={data.age}
                onChange={(e) => updateData('age', e.target.value)}
                placeholder="Your age"
                className="h-12"
              />
            </div>
            
            <div className="space-y-3">
              <Label>Gender</Label>
              <Select value={data.gender} onValueChange={(value) => updateData('gender', value)}>
                <SelectTrigger className="h-12">
                  <SelectValue placeholder="Select your gender" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="male">Male</SelectItem>
                  <SelectItem value="female">Female</SelectItem>
                  <SelectItem value="other">Other</SelectItem>
                  <SelectItem value="prefer-not-to-say">Prefer not to say</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-3">
                <Label>Height</Label>
                <div className="flex gap-2">
                  <Select value={data.heightUnit} onValueChange={(value: 'cm' | 'ft') => updateData('heightUnit', value)}>
                    <SelectTrigger className="w-20 h-12">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="cm">cm</SelectItem>
                      <SelectItem value="ft">ft</SelectItem>
                    </SelectContent>
                  </Select>
                  
                  {data.heightUnit === 'cm' ? (
                    <Input
                      type="number"
                      value={data.height}
                      onChange={(e) => updateData('height', e.target.value)}
                      placeholder="170"
                      className="flex-1 h-12"
                    />
                  ) : (
                    <div className="flex gap-2 flex-1">
                      <Input
                        type="number"
                        value={data.heightFeet}
                        onChange={(e) => updateData('heightFeet', e.target.value)}
                        placeholder="5"
                        className="flex-1 h-12"
                      />
                      <span className="flex items-center text-sm text-muted-foreground">ft</span>
                      <Input
                        type="number"
                        value={data.heightInches}
                        onChange={(e) => updateData('heightInches', e.target.value)}
                        placeholder="8"
                        className="flex-1 h-12"
                      />
                      <span className="flex items-center text-sm text-muted-foreground">in</span>
                    </div>
                  )}
                </div>
              </div>
              
              <div className="space-y-3">
                <Label>Weight</Label>
                <div className="flex gap-2">
                  <Select value={data.weightUnit} onValueChange={(value: 'kg' | 'lbs') => updateData('weightUnit', value)}>
                    <SelectTrigger className="w-20 h-12">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="kg">kg</SelectItem>
                      <SelectItem value="lbs">lbs</SelectItem>
                    </SelectContent>
                  </Select>
                  <Input
                    type="number"
                    value={data.weight}
                    onChange={(e) => updateData('weight', e.target.value)}
                    placeholder={data.weightUnit === 'kg' ? '70' : '154'}
                    className="flex-1 h-12"
                  />
                </div>
              </div>
            </div>
          </div>
        );
      }

      case 2: {
        return (
          <div className="space-y-6">
            <div className="space-y-4">
              <Label className="text-base font-medium">What's your primary goal?</Label>
              <div className="grid gap-3">
                {[
                  { value: 'weight_loss', label: 'Lose Weight', desc: 'Reduce body fat and reach your target weight', emoji: '🎯' },
                  { value: 'muscle_gain', label: 'Build Muscle', desc: 'Increase muscle mass and strength', emoji: '💪' },
                  { value: 'maintain', label: 'Maintain Health', desc: 'Stay fit and maintain current weight', emoji: '⚖️' },
                  { value: 'endurance', label: 'Improve Endurance', desc: 'Enhance cardiovascular fitness', emoji: '🏃' },
                  { value: 'strength', label: 'Get Stronger', desc: 'Increase overall strength and power', emoji: '🏋️' },
                ].map((goal) => (
                  <Card 
                    key={goal.value} 
                    className={`cursor-pointer transition-all duration-200 hover:shadow-md ${
                      data.primaryGoal === goal.value ? 'ring-2 ring-blue-500 bg-blue-50' : 'hover:bg-gray-50'
                    }`}
                    onClick={() => updateData('primaryGoal', goal.value)}
                  >
                    <CardContent className="p-4">
                      <div className="flex items-start gap-3">
                        <span className="text-2xl">{goal.emoji}</span>
                        <div className="flex-1">
                          <h3 className="font-medium text-base">{goal.label}</h3>
                          <p className="text-sm text-muted-foreground mt-1">{goal.desc}</p>
                        </div>
                        <div className={`w-5 h-5 rounded-full border-2 ${
                          data.primaryGoal === goal.value 
                            ? 'bg-blue-500 border-blue-500' 
                            : 'border-gray-300'
                        }`}>
                          {data.primaryGoal === goal.value && (
                            <div className="w-full h-full flex items-center justify-center">
                              <div className="w-2 h-2 bg-white rounded-full"></div>
                            </div>
                          )}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>

            <div className="space-y-4">
              <Label className="text-base font-medium">Secondary goals (optional)</Label>
              <div className="grid grid-cols-2 gap-3">
                {[
                  { value: 'Better Sleep', emoji: '😴' },
                  { value: 'More Energy', emoji: '⚡' },
                  { value: 'Stress Relief', emoji: '🧘' },
                  { value: 'Flexibility', emoji: '🤸' },
                  { value: 'Better Posture', emoji: '🧍' },
                  { value: 'Confidence', emoji: '✨' },
                ].map((goal) => (
                  <div key={goal.value} className="flex items-center space-x-3 p-3 rounded-lg border hover:bg-gray-50">
                    <Checkbox
                      id={goal.value}
                      checked={data.secondaryGoals.includes(goal.value)}
                      onCheckedChange={(checked) => updateArrayField('secondaryGoals', goal.value, checked as boolean)}
                    />
                    <span className="text-lg">{goal.emoji}</span>
                    <Label htmlFor={goal.value} className="text-sm font-medium cursor-pointer">{goal.value}</Label>
                  </div>
                ))}
              </div>
            </div>
          </div>
        );
      }

      case 3: {
        return (
          <div className="space-y-6">
            <div className="space-y-4">
              <Label className="text-base font-medium">How active are you currently?</Label>
              <div className="grid gap-3">
                {[
                  { value: 'sedentary', label: 'Sedentary', desc: 'Little to no exercise', emoji: '🛋️' },
                  { value: 'lightly_active', label: 'Lightly Active', desc: 'Light exercise 1-3 days/week', emoji: '🚶' },
                  { value: 'moderately_active', label: 'Moderately Active', desc: 'Moderate exercise 3-5 days/week', emoji: '🏃' },
                  { value: 'very_active', label: 'Very Active', desc: 'Heavy exercise 6-7 days/week', emoji: '🏋️' },
                  { value: 'extremely_active', label: 'Extremely Active', desc: 'Very heavy exercise, physical job', emoji: '💪' },
                ].map((level) => (
                  <Card 
                    key={level.value} 
                    className={`cursor-pointer transition-all duration-200 hover:shadow-md ${
                      data.activityLevel === level.value ? 'ring-2 ring-blue-500 bg-blue-50' : 'hover:bg-gray-50'
                    }`}
                    onClick={() => updateData('activityLevel', level.value)}
                  >
                    <CardContent className="p-4">
                      <div className="flex items-start gap-3">
                        <span className="text-2xl">{level.emoji}</span>
                        <div className="flex-1">
                          <h3 className="font-medium text-base">{level.label}</h3>
                          <p className="text-sm text-muted-foreground mt-1">{level.desc}</p>
                        </div>
                        <div className={`w-5 h-5 rounded-full border-2 ${
                          data.activityLevel === level.value 
                            ? 'bg-blue-500 border-blue-500' 
                            : 'border-gray-300'
                        }`}>
                          {data.activityLevel === level.value && (
                            <div className="w-full h-full flex items-center justify-center">
                              <div className="w-2 h-2 bg-white rounded-full"></div>
                            </div>
                          )}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>

            <div className="space-y-3">
              <Label>Fitness Experience</Label>
              <Select value={data.fitnessExperience} onValueChange={(value) => updateData('fitnessExperience', value)}>
                <SelectTrigger className="h-12">
                  <SelectValue placeholder="Select your experience level" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="beginner">🌱 Beginner (0-1 years)</SelectItem>
                  <SelectItem value="intermediate">🌿 Intermediate (1-3 years)</SelectItem>
                  <SelectItem value="advanced">🌳 Advanced (3+ years)</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Workout Days per Week</Label>
                <Select value={data.workoutDays} onValueChange={(value) => updateData('workoutDays', value)}>
                  <SelectTrigger className="h-12">
                    <SelectValue placeholder="Select days" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="2-3">2-3 days</SelectItem>
                    <SelectItem value="4-5">4-5 days</SelectItem>
                    <SelectItem value="6-7">6-7 days</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Preferred Workout Duration</Label>
                <Select value={data.workoutDuration} onValueChange={(value) => updateData('workoutDuration', value)}>
                  <SelectTrigger className="h-12">
                    <SelectValue placeholder="Select duration" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="15-30">15-30 minutes</SelectItem>
                    <SelectItem value="30-45">30-45 minutes</SelectItem>
                    <SelectItem value="45-60">45-60 minutes</SelectItem>
                    <SelectItem value="60+">60+ minutes</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>
        );
      }

      case 4: {
        return (
          <div className="space-y-6">
            <div className="space-y-4">
              <Label className="text-base font-medium">Dietary Restrictions</Label>
              <div className="grid grid-cols-2 gap-3">
                {[
                  { value: 'Vegetarian', emoji: '🥬' },
                  { value: 'Vegan', emoji: '🌱' },
                  { value: 'Keto', emoji: '🥑' },
                  { value: 'Paleo', emoji: '🥩' },
                  { value: 'Gluten-Free', emoji: '🌾' },
                  { value: 'Dairy-Free', emoji: '🥛' },
                  { value: 'Low-Carb', emoji: '🥗' },
                  { value: 'Mediterranean', emoji: '🫒' },
                ].map((diet) => (
                  <div key={diet.value} className="flex items-center space-x-3 p-3 rounded-lg border hover:bg-gray-50">
                    <Checkbox
                      id={diet.value}
                      checked={data.dietaryRestrictions.includes(diet.value)}
                      onCheckedChange={(checked) => updateArrayField('dietaryRestrictions', diet.value, checked as boolean)}
                    />
                    <span className="text-lg">{diet.emoji}</span>
                    <Label htmlFor={diet.value} className="text-sm font-medium cursor-pointer">{diet.value}</Label>
                  </div>
                ))}
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="allergies">Food Allergies (optional)</Label>
              <Textarea
                id="allergies"
                value={data.allergies}
                onChange={(e) => updateData('allergies', e.target.value)}
                placeholder="List any food allergies or intolerances..."
                rows={3}
                className="resize-none"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Meals per Day</Label>
                <Select value={data.mealsPerDay} onValueChange={(value) => updateData('mealsPerDay', value)}>
                  <SelectTrigger className="h-12">
                    <SelectValue placeholder="Select meals" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="3">🍽️ 3 meals</SelectItem>
                    <SelectItem value="4">🍽️ 4 meals</SelectItem>
                    <SelectItem value="5">🍽️ 5 meals</SelectItem>
                    <SelectItem value="6">🍽️ 6 meals</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Cooking Time Available</Label>
                <Select value={data.cookingTime} onValueChange={(value) => updateData('cookingTime', value)}>
                  <SelectTrigger className="h-12">
                    <SelectValue placeholder="Select time" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="minimal">⚡ Minimal (10-15 min)</SelectItem>
                    <SelectItem value="moderate">⏰ Moderate (30-45 min)</SelectItem>
                    <SelectItem value="extensive">👨‍🍳 Extensive (60+ min)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>
        );
      }

      case 5: {
        return (
          <div className="space-y-6">
            <div className="text-center space-y-3">
              <div className="w-16 h-16 mx-auto bg-gradient-to-br from-blue-100 to-indigo-100 rounded-full flex items-center justify-center">
                <Sparkles className="h-8 w-8 text-blue-600" />
              </div>
              <h3 className="text-xl font-semibold">Privacy & Data Consent</h3>
              <p className="text-muted-foreground">
                Your privacy is our priority. Please review and accept our terms.
              </p>
            </div>

            <div className="space-y-4">
              <Card className={`cursor-pointer transition-all duration-200 ${
                data.dataConsent ? 'ring-2 ring-blue-500 bg-blue-50' : 'hover:bg-gray-50'
              }`}>
                <CardContent className="p-4">
                  <div className="flex items-start space-x-3">
                    <Checkbox
                      id="dataConsent"
                      checked={data.dataConsent}
                      onCheckedChange={(checked) => updateData('dataConsent', checked as boolean)}
                    />
                    <div className="space-y-1">
                      <Label htmlFor="dataConsent" className="font-medium cursor-pointer">
                        Data Processing Consent (Required)
                      </Label>
                      <p className="text-sm text-muted-foreground">
                        I consent to Nutrify-AI processing my health and fitness data to provide personalized recommendations. 
                        All data is encrypted and never shared with third parties.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card className={`cursor-pointer transition-all duration-200 ${
                data.healthDisclaimer ? 'ring-2 ring-blue-500 bg-blue-50' : 'hover:bg-gray-50'
              }`}>
                <CardContent className="p-4">
                  <div className="flex items-start space-x-3">
                    <Checkbox
                      id="healthDisclaimer"
                      checked={data.healthDisclaimer}
                      onCheckedChange={(checked) => updateData('healthDisclaimer', checked as boolean)}
                    />
                    <div className="space-y-1">
                      <Label htmlFor="healthDisclaimer" className="font-medium cursor-pointer">
                        Health Disclaimer (Required)
                      </Label>
                      <p className="text-sm text-muted-foreground">
                        I understand that Nutrify-AI provides general wellness guidance and is not a substitute for 
                        professional medical advice. I will consult healthcare providers for medical concerns.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card className={`cursor-pointer transition-all duration-200 ${
                data.marketingConsent ? 'ring-2 ring-blue-500 bg-blue-50' : 'hover:bg-gray-50'
              }`}>
                <CardContent className="p-4">
                  <div className="flex items-start space-x-3">
                    <Checkbox
                      id="marketingConsent"
                      checked={data.marketingConsent}
                      onCheckedChange={(checked) => updateData('marketingConsent', checked as boolean)}
                    />
                    <div className="space-y-1">
                      <Label htmlFor="marketingConsent" className="font-medium cursor-pointer">
                        Marketing Communications (Optional)
                      </Label>
                      <p className="text-sm text-muted-foreground">
                        I'd like to receive tips, updates, and special offers from Nutrify-AI via email.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            <Card className="bg-gradient-to-r from-blue-50 to-indigo-50 border-blue-200">
              <CardContent className="p-4">
                <h4 className="font-medium text-blue-900 mb-3 flex items-center gap-2">
                  🔒 Your Data is Safe
                </h4>
                <ul className="text-sm text-blue-800 space-y-2">
                  <li className="flex items-center gap-2">
                    <div className="w-1.5 h-1.5 bg-blue-600 rounded-full"></div>
                    End-to-end encryption for all sensitive data
                  </li>
                  <li className="flex items-center gap-2">
                    <div className="w-1.5 h-1.5 bg-blue-600 rounded-full"></div>
                    On-device AI processing when possible
                  </li>
                  <li className="flex items-center gap-2">
                    <div className="w-1.5 h-1.5 bg-blue-600 rounded-full"></div>
                    GDPR and HIPAA compliant
                  </li>
                  <li className="flex items-center gap-2">
                    <div className="w-1.5 h-1.5 bg-blue-600 rounded-full"></div>
                    Delete your data anytime
                  </li>
                </ul>
              </CardContent>
            </Card>
          </div>
        );
      }

      default:
        return null;
    }
  };

  const canProceed = () => {
    switch (currentStep) {
      case 1: {
        const hasHeight = data.heightUnit === 'cm' 
          ? data.height 
          : data.heightFeet && data.heightInches;
        return data.age && data.gender && hasHeight && data.weight;
      }
      case 2:
        return data.primaryGoal;
      case 3:
        return data.activityLevel && data.fitnessExperience;
      case 4:
        return data.mealsPerDay && data.cookingTime;
      case 5:
        return data.dataConsent && data.healthDisclaimer;
      default:
        return false;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 flex items-center justify-center p-4">
      <div className="w-full max-w-3xl">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-2 mb-4">
            <div className="h-12 w-12 rounded-xl bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center shadow-lg">
              <span className="text-white font-bold text-lg">N</span>
            </div>
            <span className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
              Nutrify-AI
            </span>
          </div>
          <h1 className="text-4xl font-bold text-gray-900 mb-3">Welcome to Your AI Health Journey</h1>
          <p className="text-lg text-gray-600">Let's personalize your experience in just a few steps</p>
        </div>

        {/* Progress */}
        <div className="mb-10">
          <div className="flex items-center justify-between mb-6">
            {steps.map((step, index) => (
              <div key={step.id} className="flex items-center">
                <div className={`flex items-center justify-center w-12 h-12 rounded-full border-2 transition-all duration-300 ${
                  currentStep >= step.id 
                    ? 'bg-blue-600 border-blue-600 text-white shadow-lg' 
                    : 'border-gray-300 text-gray-400 bg-white'
                }`}>
                  <step.icon className="h-6 w-6" />
                </div>
                {index < steps.length - 1 && (
                  <div className={`w-full h-1 mx-4 rounded-full transition-all duration-300 ${
                    currentStep > step.id ? 'bg-blue-600' : 'bg-gray-200'
                  }`} />
                )}
              </div>
            ))}
          </div>
          <Progress value={(currentStep / steps.length) * 100} className="h-3 rounded-full" />
          <div className="flex justify-between mt-3">
            <span className="text-sm font-medium text-gray-600">
              Step {currentStep} of {steps.length}
            </span>
            <span className="text-sm font-medium text-gray-600">
              {Math.round((currentStep / steps.length) * 100)}% Complete
            </span>
          </div>
        </div>

        {/* Content */}
        <Card className="shadow-xl border-0">
          <CardHeader className="pb-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-100 to-indigo-100 flex items-center justify-center">
                {React.createElement(steps[currentStep - 1].icon, { className: "h-5 w-5 text-blue-600" })}
              </div>
              <div>
                <CardTitle className="text-xl">{steps[currentStep - 1].title}</CardTitle>
                <CardDescription className="text-base">{steps[currentStep - 1].description}</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-0">
            {renderStepContent()}
          </CardContent>
        </Card>

        {/* Navigation */}
        <div className="flex justify-between mt-8">
          <Button
            variant="outline"
            size="lg"
            onClick={prevStep}
            disabled={currentStep === 1}
            className="px-6"
          >
            <ChevronLeft className="h-4 w-4 mr-2" />
            Previous
          </Button>
          
          {currentStep < steps.length ? (
            <Button
              size="lg"
              onClick={nextStep}
              disabled={!canProceed()}
              className="px-6 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700"
            >
              Next
              <ChevronRight className="h-4 w-4 ml-2" />
            </Button>
          ) : (
            <Button
              size="lg"
              onClick={handleSubmit}
              disabled={!canProceed() || isLoading}
              className="px-6 bg-gradient-to-r from-green-600 to-blue-600 hover:from-green-700 hover:to-blue-700"
            >
              {isLoading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                  Setting up your AI coach...
                </>
              ) : (
                <>
                  Complete Setup
                  <Sparkles className="h-4 w-4 ml-2" />
                </>
              )}
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}