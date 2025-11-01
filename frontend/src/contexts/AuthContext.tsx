import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { apiClient, User } from '@/services/api';

interface AuthContextType {
  user: User | null;
  onboardingCompleted: boolean | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, name: string) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [onboardingCompleted, setOnboardingCompleted] = useState<boolean | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Check for existing auth on mount
  useEffect(() => {
    const initAuth = async () => {
      const token = localStorage.getItem('auth_token');
      if (token) {
        try {
          // Fetch basic user info first
          const basicUser = await apiClient.getCurrentUser();
          setUser(basicUser);
          
          // Try to fetch profile, but handle 404 gracefully
          try {
            const profile = await apiClient.getUserProfile();
            setOnboardingCompleted(Boolean(profile?.onboarding_completed));
          } catch (profileError) {
            // Profile doesn't exist yet (404) - onboarding not completed
            if (profileError instanceof Error && profileError.message === 'NOT_FOUND') {
              setOnboardingCompleted(false);
            } else {
              throw profileError;
            }
          }
        } catch (error) {
          // Token invalid or server error - clear stored token
          console.error('initAuth error', error);
          localStorage.removeItem('auth_token');
          setUser(null);
          setOnboardingCompleted(null);
        }
      } else {
        setOnboardingCompleted(null);
      }
      setIsLoading(false);
    };

    initAuth();
  }, []);

  const login = async (email: string, password: string) => {
    try {
      const response = await apiClient.login(email, password);
      localStorage.setItem('auth_token', response.token);
      // After login, refresh user/profile from server
      await refreshUser();
    } catch (error) {
      console.error('Login failed:', error);
      throw error;
    }
  };

  const register = async (email: string, password: string, name: string) => {
    try {
      const response = await apiClient.register({ email, password, name });
      localStorage.setItem('auth_token', response.token);
      // After register, refresh user/profile
      await refreshUser();
    } catch (error) {
      console.error('Registration failed:', error);
      throw error;
    }
  };

  const logout = () => {
    apiClient.logout();
    setUser(null);
    localStorage.removeItem('auth_token');
  };

  const refreshUser = async () => {
    try {
      const basicUser = await apiClient.getCurrentUser();
      setUser(basicUser);
      
      // Try to fetch profile, but handle 404 gracefully
      try {
        const profile = await apiClient.getUserProfile();
        setOnboardingCompleted(Boolean(profile?.onboarding_completed));
      } catch (profileError) {
        // Profile doesn't exist yet (404) - onboarding not completed
        if (profileError instanceof Error && profileError.message === 'NOT_FOUND') {
          setOnboardingCompleted(false);
        } else {
          throw profileError;
        }
      }
    } catch (error) {
      console.error('Failed to refresh user:', error);
    }
  };

  const value: AuthContextType = {
    user,
    onboardingCompleted,
    isAuthenticated: !!user,
    isLoading,
    login,
    register,
    logout,
    refreshUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
