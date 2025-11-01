import { Toaster } from '@/components/ui/sonner';
import { TooltipProvider } from '@/components/ui/tooltip';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './contexts/AuthContext';
import { ProtectedRoute } from './components/ProtectedRoute';
import Layout from './components/Layout';
import Landing from './pages/Landing';
import Index from './pages/Index';
import Onboarding from './pages/Onboarding';
import NutritionPlan from './pages/NutritionPlan';
import FitnessPlan from './pages/FitnessPlan';
import Progress from './pages/Progress';
import AIChat from './pages/AIChat';
import NotFound from './pages/NotFound';

// Check if user has completed onboarding (server-side)
const hasCompletedOnboarding = (onboardingCompleted: boolean | null) => {
  // If server hasn't provided info yet, fall back to localStorage for UX
  if (onboardingCompleted === null) {
    return localStorage.getItem('onboarding_completed') === 'true';
  }
  return onboardingCompleted === true;
};

// Protected Route with Layout Component
const ProtectedRouteWithLayout = ({ children }: { children: React.ReactNode }) => {
  return (
    <ProtectedRoute>
      <Layout>{children}</Layout>
    </ProtectedRoute>
  );
};

// Landing Route Component - redirects to dashboard if already authenticated
const LandingRoute = () => {
  const { isAuthenticated, onboardingCompleted } = useAuth();
  
  if (isAuthenticated && hasCompletedOnboarding(onboardingCompleted)) {
    return <Navigate to="/dashboard" replace />;
  }
  return <Landing />;
};

// Onboarding Route - redirects to dashboard if already completed
const OnboardingRoute = () => {
  const { isAuthenticated, onboardingCompleted, isLoading } = useAuth();
  
  if (isLoading) {
    return <div>Loading...</div>;
  }
  
  if (!isAuthenticated) {
    return <Navigate to="/" replace />;
  }
  
  if (hasCompletedOnboarding(onboardingCompleted)) {
    return <Navigate to="/dashboard" replace />;
  }
  
  return <Onboarding />;
};

// Dashboard Route - redirects to onboarding if not completed
const DashboardRoute = ({ children }: { children: React.ReactNode }) => {
  const { onboardingCompleted, isLoading } = useAuth();
  
  if (isLoading) {
    return <div>Loading...</div>;
  }
  
  if (!hasCompletedOnboarding(onboardingCompleted)) {
    return <Navigate to="/onboarding" replace />;
  }
  
  return <Layout>{children}</Layout>;
};

const App = () => (
  <TooltipProvider>
    <Toaster />
    <BrowserRouter>
      <Routes>
        {/* Landing Page */}
        <Route path="/" element={<LandingRoute />} />
        
        {/* Onboarding Route */}
        <Route path="/onboarding" element={<OnboardingRoute />} />
        
        {/* Protected Routes - require onboarding completion */}
        <Route path="/dashboard" element={
          <ProtectedRoute>
            <DashboardRoute>
              <Index />
            </DashboardRoute>
          </ProtectedRoute>
        } />
        <Route path="/nutrition" element={
          <ProtectedRoute>
            <DashboardRoute>
              <NutritionPlan />
            </DashboardRoute>
          </ProtectedRoute>
        } />
        <Route path="/fitness" element={
          <ProtectedRoute>
            <DashboardRoute>
              <FitnessPlan />
            </DashboardRoute>
          </ProtectedRoute>
        } />
        <Route path="/progress" element={
          <ProtectedRoute>
            <DashboardRoute>
              <Progress />
            </DashboardRoute>
          </ProtectedRoute>
        } />
        <Route path="/chat" element={
          <ProtectedRoute>
            <DashboardRoute>
              <AIChat />
            </DashboardRoute>
          </ProtectedRoute>
        } />
        
        {/* 404 Route */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  </TooltipProvider>
);

export default App;