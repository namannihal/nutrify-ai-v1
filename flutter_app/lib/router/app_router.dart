import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/nutrition/nutrition_plan_screen.dart';
import '../screens/fitness/fitness_plan_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/ai/ai_chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/main_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final hasCompletedOnboarding = authState.hasCompletedOnboarding;
      final currentLocation = state.matchedLocation;
      
      final isAuthPage = currentLocation == '/login' || currentLocation == '/register';
      final isOnboardingPage = currentLocation == '/onboarding';
      
      // If not logged in and trying to access protected routes
      if (!isLoggedIn && !isAuthPage && !isOnboardingPage) {
        return '/login';
      }
      
      // If logged in
      if (isLoggedIn) {
        // User hasn't completed onboarding and not already on onboarding page
        if (!hasCompletedOnboarding && !isOnboardingPage) {
          return '/onboarding';
        }
        
        // User has completed onboarding but still on auth/onboarding pages
        if (hasCompletedOnboarding && (isAuthPage || isOnboardingPage)) {
          return '/dashboard';
        }
      }
      
      return null; // No redirect needed
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Main App Routes (Protected)
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/nutrition',
            name: 'nutrition',
            builder: (context, state) => const NutritionPlanScreen(),
          ),
          GoRoute(
            path: '/fitness',
            name: 'fitness',
            builder: (context, state) => const FitnessPlanScreen(),
          ),
          GoRoute(
            path: '/progress',
            name: 'progress',
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/ai-chat',
            name: 'ai-chat',
            builder: (context, state) => const AiChatScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you\'re looking for doesn\'t exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});