import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, NutritionPlan, WorkoutPlan, ProgressEntry, AIInsight, UserProfile } from '@/services/api';
import { toast } from '@/components/ui/use-toast';

// User Profile hooks
export const useUserProfile = () => {
  return useQuery({
    queryKey: ['userProfile'],
    queryFn: () => apiClient.getUserProfile(),
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
};

export const useUpdateUserProfile = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (profile: Partial<UserProfile>) => apiClient.updateUserProfile(profile),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['userProfile'] });
      toast({
        title: 'Profile Updated',
        description: 'Your profile has been updated successfully',
      });
    },
    onError: () => {
      toast({
        title: 'Update Failed',
        description: 'Failed to update your profile. Please try again.',
        variant: 'destructive',
      });
    },
  });
};

// Nutrition hooks
export const useNutritionPlan = () => {
  return useQuery({
    queryKey: ['nutritionPlan'],
    queryFn: async () => {
      try {
        return await apiClient.getCurrentNutritionPlan();
      } catch (error) {
        // Return null for 404 - no plan exists yet
        if (error instanceof Error && error.message === 'NOT_FOUND') {
          return null;
        }
        throw error;
      }
    },
    staleTime: 1000 * 60 * 10, // 10 minutes
    retry: false, // Don't retry 404s
  });
};

export const useGenerateNutritionPlan = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: () => apiClient.generateNutritionPlan(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['nutritionPlan'] });
      toast({
        title: 'Nutrition Plan Generated',
        description: 'Your personalized nutrition plan is ready!',
      });
    },
    onError: () => {
      toast({
        title: 'Generation Failed',
        description: 'Failed to generate nutrition plan. Please try again.',
        variant: 'destructive',
      });
    },
  });
};

// Fitness hooks
export const useWorkoutPlan = () => {
  return useQuery({
    queryKey: ['workoutPlan'],
    queryFn: async () => {
      try {
        return await apiClient.getCurrentWorkoutPlan();
      } catch (error) {
        // Return null for 404 - no plan exists yet
        if (error instanceof Error && error.message === 'NOT_FOUND') {
          return null;
        }
        throw error;
      }
    },
    staleTime: 1000 * 60 * 10, // 10 minutes
    retry: false, // Don't retry 404s
  });
};

export const useGenerateWorkoutPlan = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: () => apiClient.generateWorkoutPlan(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workoutPlan'] });
      toast({
        title: 'Workout Plan Generated',
        description: 'Your personalized workout plan is ready!',
      });
    },
    onError: () => {
      toast({
        title: 'Generation Failed',
        description: 'Failed to generate workout plan. Please try again.',
        variant: 'destructive',
      });
    },
  });
};

// Progress hooks
export const useProgressHistory = (days: number = 30) => {
  return useQuery({
    queryKey: ['progressHistory', days],
    queryFn: async () => {
      try {
        return await apiClient.getProgressHistory(days);
      } catch (error) {
        // Return empty array for 404 - no progress entries yet
        if (error instanceof Error && error.message === 'NOT_FOUND') {
          return [];
        }
        throw error;
      }
    },
    staleTime: 1000 * 60 * 5, // 5 minutes
    retry: false, // Don't retry 404s
  });
};

export const useLogProgress = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (progressData: Partial<ProgressEntry>) => apiClient.logProgress(progressData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['progressHistory'] });
      toast({
        title: 'Progress Logged',
        description: 'Your progress has been recorded successfully',
      });
    },
    onError: () => {
      toast({
        title: 'Log Failed',
        description: 'Failed to log your progress. Please try again.',
        variant: 'destructive',
      });
    },
  });
};

// AI Insights hooks
export const useAIInsights = (limit: number = 10) => {
  return useQuery({
    queryKey: ['aiInsights', limit],
    queryFn: async () => {
      try {
        return await apiClient.getAIInsights(limit);
      } catch (error) {
        // Return empty array for 404 - no insights yet
        if (error instanceof Error && error.message === 'NOT_FOUND') {
          return [];
        }
        throw error;
      }
    },
    staleTime: 1000 * 60 * 5, // 5 minutes
    retry: false, // Don't retry 404s
  });
};

export const useRequestAIAnalysis = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: () => apiClient.requestAIAnalysis(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['aiInsights'] });
      toast({
        title: 'Analysis Complete',
        description: 'New AI insights are available',
      });
    },
    onError: () => {
      toast({
        title: 'Analysis Failed',
        description: 'Failed to analyze your data. Please try again.',
        variant: 'destructive',
      });
    },
  });
};

// AI Chat hook
export const useChatWithAI = () => {
  return useMutation({
    mutationFn: (message: string) => apiClient.chatWithAI(message),
    onError: () => {
      toast({
        title: 'Chat Error',
        description: 'Failed to send message. Please try again.',
        variant: 'destructive',
      });
    },
  });
};
