import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/dashboard/stats_card.dart';
import '../../widgets/dashboard/quick_actions.dart';
import '../../widgets/dashboard/recent_meals_card.dart';
import '../../widgets/dashboard/workout_progress_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nutritionNotifierProvider.notifier).loadCurrentPlan();
      ref.read(fitnessNotifierProvider.notifier).loadCurrentPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final nutritionState = ref.watch(nutritionNotifierProvider);
    final fitnessState = ref.watch(fitnessNotifierProvider);
    
    final isLoading = nutritionState.isLoading || fitnessState.isLoading;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: isLoading,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Good ${_getGreeting()}, ${user?.firstName ?? 'there'}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to crush your goals today?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outlined),
                  onPressed: () => context.go('/profile'),
                ),
              ],
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Calories Today',
                          value: '1,247',
                          target: '/ 2,200',
                          progress: 0.57,
                          color: Theme.of(context).colorScheme.primary,
                          icon: Icons.local_fire_department,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Water Intake',
                          value: '6',
                          target: '/ 8 glasses',
                          progress: 0.75,
                          color: Theme.of(context).colorScheme.tertiary,
                          icon: Icons.water_drop,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Workouts',
                          value: '3',
                          target: '/ 4 this week',
                          progress: 0.75,
                          color: Theme.of(context).colorScheme.secondary,
                          icon: Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Sleep',
                          value: '7.2h',
                          target: '/ 8h',
                          progress: 0.9,
                          color: Colors.indigo,
                          icon: Icons.bedtime,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  const QuickActions(),
                  
                  const SizedBox(height: 24),
                  
                  // Today's Nutrition
                  const RecentMealsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Workout Progress
                  const WorkoutProgressCard(),
                  
                  const SizedBox(height: 100), // Bottom padding for navigation
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }
}