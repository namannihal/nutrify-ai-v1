import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/fitness_provider.dart';
import '../../models/fitness.dart';
import '../../widgets/common/loading_overlay.dart';

class FitnessPlanScreen extends ConsumerStatefulWidget {
  const FitnessPlanScreen({super.key});

  @override
  ConsumerState<FitnessPlanScreen> createState() => _FitnessPlanScreenState();
}

class _FitnessPlanScreenState extends ConsumerState<FitnessPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fitnessNotifierProvider.notifier).loadCurrentPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fitnessState = ref.watch(fitnessNotifierProvider);
    final currentPlan = fitnessState.currentPlan;
    
    // Get today's workout - DailyWorkout contains a list of workouts
    final today = DateTime.now().weekday;
    DailyWorkout? todaysWorkouts;
    
    if (currentPlan?.workouts != null) {
      try {
        todaysWorkouts = currentPlan!.workouts.firstWhere(
          (dailyWorkout) => _getDayNumber(dailyWorkout.day) == today,
        );
      } catch (e) {
        // No workout for today, use first one if available
        if (currentPlan!.workouts.isNotEmpty) {
          todaysWorkouts = currentPlan.workouts.first;
        }
      }
    }
    
    // Get the first workout for today (if any)
    final firstWorkout = todaysWorkouts?.workouts.isNotEmpty == true 
        ? todaysWorkouts!.workouts.first 
        : null;
    
    // TODO: Get actual weekly stats from workout logs
    final completedWorkouts = 0;
    final targetWorkouts = currentPlan?.workouts.where((dw) => dw.workouts.isNotEmpty).length ?? 4;
    final totalDuration = 0.0;
    final caloriesBurned = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show workout history
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: fitnessState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly Progress Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Week\'s Progress',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(context, 'Workouts', completedWorkouts.toString(), '/ $targetWorkouts', Colors.blue),
                          _buildStatColumn(context, 'Duration', '${totalDuration.toStringAsFixed(1)}h', 'this week', Colors.green),
                          _buildStatColumn(context, 'Calories', caloriesBurned.toString(), 'burned', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Today's Workout
              Text(
                'Today\'s Workout',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (currentPlan == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workout plan yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generate your personalized workout plan from the dashboard',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (firstWorkout != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firstWorkout.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${firstWorkout.durationMinutes} minutes • ${firstWorkout.exercises.length} exercises',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Start workout
                              },
                              child: const Text('Start'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Exercises',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (firstWorkout != null)
                const SizedBox(height: 16),
              
              if (firstWorkout != null)
                ...firstWorkout.exercises.map((exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildExerciseCard(
                    context, 
                    exercise.name,
                    '${exercise.sets ?? 0} sets × ${exercise.reps ?? 0} reps',
                    Icons.fitness_center,
                  ),
                )).toList(),
              
              if (currentPlan != null && firstWorkout == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Rest day - no workout scheduled',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _getDayNumber(String day) {
    const days = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    return days[day.toLowerCase()] ?? 1;
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, String subtitle, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(BuildContext context, String name, String details, IconData icon) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(details),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Show exercise details
        },
      ),
    );
  }
}