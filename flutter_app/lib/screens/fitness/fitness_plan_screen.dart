import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/generation_provider.dart' show generationNotifierProvider, GenerationState, GenerationTaskState;
import '../../models/fitness.dart';
import '../../widgets/common/loading_overlay.dart';
import 'active_workout_screen.dart';
import 'fitness_questionnaire_screen.dart';

class FitnessPlanScreen extends ConsumerStatefulWidget {
  const FitnessPlanScreen({super.key});

  @override
  ConsumerState<FitnessPlanScreen> createState() => _FitnessPlanScreenState();
}

class _FitnessPlanScreenState extends ConsumerState<FitnessPlanScreen> {
  int _selectedDay = DateTime.now().weekday; // 1=Monday, 7=Sunday

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fitnessNotifierProvider.notifier).loadCurrentPlan();
      ref.read(fitnessNotifierProvider.notifier).loadWeeklyStats();

      // Setup generation completion callbacks
      final generationNotifier = ref.read(generationNotifierProvider.notifier);
      generationNotifier.onFitnessComplete = (resultId) {
        // Refresh the fitness plan when generation completes
        ref.read(fitnessNotifierProvider.notifier).loadCurrentPlan(forceRefresh: true);
        ref.read(fitnessNotifierProvider.notifier).loadWeeklyStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Your new workout plan is ready!')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      };
      generationNotifier.onFitnessError = (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Generation failed: $error')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final fitnessState = ref.watch(fitnessNotifierProvider);
    final generationState = ref.watch(generationNotifierProvider);
    final currentPlan = fitnessState.currentPlan;
    final fitnessTask = generationState.fitnessTask;
    final isGenerating = fitnessTask?.isActive ?? false;

    // Get selected day's workout - DailyWorkout contains a list of workouts
    DailyWorkout? selectedDayWorkouts;

    if (currentPlan?.workouts != null) {
      try {
        selectedDayWorkouts = currentPlan!.workouts.firstWhere(
          (dailyWorkout) => _getDayNumber(dailyWorkout.day) == _selectedDay,
        );
      } catch (e) {
        // No workout for selected day
        selectedDayWorkouts = null;
      }
    }

    // Get the first workout for selected day (if any)
    final selectedWorkout = selectedDayWorkouts?.workouts.isNotEmpty == true
        ? selectedDayWorkouts!.workouts.first
        : null;

    // Get weekly stats from workout logs
    final weeklyStats = fitnessState.weeklyStats;
    final completedWorkouts = weeklyStats.completedWorkouts;
    final targetWorkouts = currentPlan?.workouts.where((dw) => dw.workouts.isNotEmpty).length ?? 4;
    final totalDuration = weeklyStats.totalDurationHours;
    final caloriesBurned = weeklyStats.totalCaloriesBurned;

    final authState = ref.watch(authNotifierProvider);
    final hasAssessment = authState.profile?.fitnessPreferences != null &&
        (authState.profile!.fitnessPreferences!['questionnaire_completed'] == true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Plan'),
        actions: [
          // Regenerate button hidden - AI generation coming soon
          // if (currentPlan != null)
          //   IconButton(
          //     icon: const Icon(Icons.refresh),
          //     onPressed: fitnessState.isLoading ? null : () => _showRegenerateDialog(context, ref),
          //     tooltip: 'Regenerate Plan',
          //   ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show workout history
            },
          ),
          if (hasAssessment)
             IconButton(
               icon: const Icon(Icons.refresh),
               onPressed: fitnessState.isLoading ? null : () => _showRegenerateDialog(context, ref),
               tooltip: 'Regenerate Plan',
             ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: fitnessState.isLoading,
        child: Column(
          children: [
            // Generation Progress Banner
            if (isGenerating)
              _buildGenerationBanner(context, fitnessTask!),
            // Day Selector
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final dayNumber = index + 1; // 1=Monday, 7=Sunday
                  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final isSelected = dayNumber == _selectedDay;
                  final isToday = dayNumber == DateTime.now().weekday;

                  // Check if this day has a workout
                  bool hasWorkout = false;
                  if (currentPlan?.workouts != null) {
                    try {
                      final dayWorkout = currentPlan!.workouts.firstWhere(
                        (dw) => _getDayNumber(dw.day) == dayNumber,
                      );
                      hasWorkout = dayWorkout.workouts.isNotEmpty;
                    } catch (e) {
                      hasWorkout = false;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(dayNames[index]),
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: hasWorkout
                          ? Icon(
                              Icons.fitness_center,
                              size: 14,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.primary,
                            )
                          : isToday && !isSelected
                              ? const Icon(Icons.circle, size: 8)
                              : null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDay = dayNumber;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasAssessment ? Icons.fitness_center : Icons.assignment_late,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          hasAssessment ? 'No Workout Plan Yet' : 'Complete Assessment',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasAssessment
                              ? 'Generate a personalized workout plan based on your experience and equipment.'
                              : 'To generate a personalized plan, we first need to understand your fitness profile.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: hasAssessment
                              ? () => _startGeneration(context, ref)
                              : () => _showFitnessQuestionnaire(context),
                          icon: Icon(hasAssessment ? Icons.auto_awesome : Icons.assignment),
                          label: Text(hasAssessment ? 'Generate Plan with AI' : 'Start Assessment'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Custom Workout Option - Always Available
                        OutlinedButton.icon(
                          onPressed: () => _showQuickStartDialog(context),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Custom Workout'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Feature preview list
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildFeaturePreviewItem(context, Icons.auto_awesome, 'AI-generated personalized workouts'),
                              const SizedBox(height: 12),
                              _buildFeaturePreviewItem(context, Icons.fitness_center, 'Based on your fitness goals'),
                              const SizedBox(height: 12),
                              _buildFeaturePreviewItem(context, Icons.calendar_month, 'Weekly workout schedules'),
                              const SizedBox(height: 12),
                              _buildFeaturePreviewItem(context, Icons.trending_up, 'Progressive overload planning'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (selectedWorkout != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedWorkout.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selectedWorkout.durationMinutes} min • ${selectedWorkout.exercises.length} exercises',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ActiveWorkoutScreen(
                                      workout: selectedWorkout,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start'),
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
              
              if (selectedWorkout != null)
                const SizedBox(height: 16),
              
              if (selectedWorkout != null)
                ...selectedWorkout.exercises.map((exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildExerciseCard(
                    context, 
                    exercise.name,
                    '${exercise.sets ?? 0} sets × ${exercise.reps ?? 0} reps',
                    Icons.fitness_center,
                  ),
                )).toList(),
              
              if (currentPlan != null && selectedWorkout == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.self_improvement,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rest Day',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No workout scheduled for this day.\nUse this time to recover!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showQuickStartDialog(context),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Quick Start Workout'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Quick Start button when there's a workout scheduled
              if (currentPlan != null && selectedWorkout != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _showQuickStartDialog(context),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Quick Start Different Workout'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ),
          ],
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

  void _showWorkoutOptions(BuildContext context, Workout workout) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${workout.durationMinutes} min • ${workout.exercises.length} exercises',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              leading: Icon(Icons.play_circle_fill, color: Theme.of(context).colorScheme.primary),
              title: const Text('Start Workout'),
              subtitle: const Text('Track sets, reps, and weights'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveWorkoutScreen(workout: workout),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Quick Log (Completed)'),
              subtitle: const Text('Mark workout as fully completed'),
              onTap: () {
                Navigator.pop(context);
                _showLogWorkoutDialog(context, workout, completed: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.pie_chart, color: Colors.orange),
              title: const Text('Quick Log (Partial)'),
              subtitle: const Text('Completed some exercises'),
              onTap: () {
                Navigator.pop(context);
                _showLogWorkoutDialog(context, workout, completed: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('View Workout Details'),
              subtitle: const Text('See all exercises and instructions'),
              onTap: () {
                Navigator.pop(context);
                _showWorkoutDetails(context, workout);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLogWorkoutDialog(BuildContext context, Workout workout, {required bool completed}) {
    int completionPercentage = completed ? 100 : 50;
    int perceivedExertion = 5;
    int moodAfter = 7;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(completed ? 'Log Completed Workout' : 'Log Partial Workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workout.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${workout.durationMinutes} min • ${workout.estimatedCalories ?? 0} kcal',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Completion percentage (only for partial)
                if (!completed) ...[
                  Text(
                    'Completion: $completionPercentage%',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Slider(
                    value: completionPercentage.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 9,
                    label: '$completionPercentage%',
                    onChanged: (value) {
                      setDialogState(() {
                        completionPercentage = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                // Perceived exertion
                Text(
                  'How hard was it? (1-10): $perceivedExertion',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: perceivedExertion.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: perceivedExertion.toString(),
                  onChanged: (value) {
                    setDialogState(() {
                      perceivedExertion = value.round();
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Mood after
                Text(
                  'Mood after workout (1-10): $moodAfter',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: moodAfter.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: moodAfter.toString(),
                  onChanged: (value) {
                    setDialogState(() {
                      moodAfter = value.round();
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Notes
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'How did it go?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _logWorkout(
                  workout,
                  completed: completionPercentage >= 100,
                  completionPercentage: completionPercentage,
                  perceivedExertion: perceivedExertion,
                  moodAfter: moodAfter,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );
              },
              child: const Text('Log Workout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logWorkout(
    Workout workout, {
    required bool completed,
    required int completionPercentage,
    required int perceivedExertion,
    required int moodAfter,
    String? notes,
  }) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Logging workout...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      final today = DateTime.now().toIso8601String().split('T')[0];

      final success = await ref.read(fitnessNotifierProvider.notifier).logWorkout(
        workoutDate: today,
        durationMinutes: workout.durationMinutes,
        workoutId: workout.id,
        workoutName: workout.name,
        caloriesBurned: workout.estimatedCalories,
        perceivedExertion: perceivedExertion,
        moodAfter: moodAfter,
        completed: completed,
        completionPercentage: completionPercentage,
        notes: notes,
      );

      if (!mounted) return;

      // Refresh weekly stats after successful log
      if (success) {
        ref.read(fitnessNotifierProvider.notifier).loadWeeklyStats();
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Workout logged! Great job!'
                      : 'Failed to log workout. Please try again.',
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log workout: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showWorkoutDetails(BuildContext context, Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workout.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Workout info
              Row(
                children: [
                  Chip(
                    label: Text('${workout.durationMinutes} min'),
                    avatar: const Icon(Icons.timer, size: 16),
                  ),
                  const SizedBox(width: 8),
                  if (workout.estimatedCalories != null)
                    Chip(
                      label: Text('${workout.estimatedCalories} kcal'),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Exercises
              Text(
                'Exercises (${workout.exercises.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...workout.exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${exercise.sets ?? 0} sets × ${exercise.reps ?? 0} reps',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showLogWorkoutDialog(context, workout, completed: true);
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Log as Completed'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePreviewItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  void _showFitnessQuestionnaire(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FitnessQuestionnaireScreen(
          onComplete: () {
            // Questionnaire completed - show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitness profile saved! AI plan generation coming soon.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showQuickStartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Theme(
        data: Theme.of(context).copyWith(
          brightness: Brightness.light,
          dialogBackgroundColor: Colors.white,
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Quick Start Workout'),
          content: const Text(
            'Start a custom workout session where you can add exercises from our library and track your sets, reps, and weights.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Create a placeholder workout for quick start
                final quickWorkout = Workout(
                  id: 'quick_start_${DateTime.now().millisecondsSinceEpoch}',
                  name: 'Quick Workout',
                  description: 'Custom workout session',
                  durationMinutes: 60,
                  exercises: [], // Start with empty exercises, user can add from library
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveWorkoutScreen(workout: quickWorkout),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegenerateDialog(BuildContext context, WidgetRef ref) {
    // Guard: Ensure assessment is completed
    final authState = ref.read(authNotifierProvider);
    final hasAssessment = authState.profile?.fitnessPreferences != null &&
        (authState.profile!.fitnessPreferences!['questionnaire_completed'] == true);
    
    if (!hasAssessment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your fitness assessment first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Regenerate Workout Plan?'),
        content: const Text(
          'This will create a new AI-generated workout plan with different exercises. '
          'Your current plan will be replaced.\n\n'
          'Generation happens in the background - you can continue using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Start background generation
              final started = await ref
                  .read(generationNotifierProvider.notifier)
                  .startFitnessGeneration();

              if (started) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Generating new workout plan in background...'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.blue,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('A generation is already in progress.'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationBanner(BuildContext context, GenerationTaskState task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: task.progress > 0 ? task.progress / 100 : null,
              backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generating Workout Plan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (task.message?.isNotEmpty == true)
                  Text(
                    task.message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (task.progress > 0)
            Text(
              '${task.progress}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
  Future<void> _startGeneration(BuildContext context, WidgetRef ref) async {
    // Guard: Ensure assessment is completed before allowing generation
    final authState = ref.read(authNotifierProvider);
    final hasAssessment = authState.profile?.fitnessPreferences != null &&
        (authState.profile!.fitnessPreferences!['questionnaire_completed'] == true);
    
    if (!hasAssessment) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete your fitness assessment first!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    final success = await ref.read(generationNotifierProvider.notifier).startFitnessGeneration();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitness plan generation started! This may take a few minutes.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}