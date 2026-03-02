import 'package:flutter/material.dart';
import '../../models/fitness.dart';

class WorkoutProgressCard extends StatelessWidget {
  final List<Workout>? workouts;
  final int completedCount;
  final VoidCallback? onViewAll;
  final Function(Workout)? onStartWorkout;

  const WorkoutProgressCard({
    super.key,
    this.workouts,
    this.completedCount = 0,
    this.onViewAll,
    this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final hasWorkouts = workouts?.isNotEmpty ?? false;
    final totalWorkouts = workouts?.length ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'This Week\'s Workouts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasWorkouts)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No workout plan yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._buildWorkoutsList(context),
            if (hasWorkouts) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$completedCount of $totalWorkouts workouts completed this week. ${completedCount == totalWorkouts ? 'Amazing!' : 'Keep it up!'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWorkoutsList(BuildContext context) {
    if (workouts == null || workouts!.isEmpty) return [];

    final List<Widget> workoutWidgets = [];
    
    for (int i = 0; i < workouts!.length; i++) {
      if (i > 0) {
        workoutWidgets.add(const SizedBox(height: 12));
      }
      
      final workout = workouts![i];
      final isCompleted = i < completedCount;
      final isToday = i == completedCount; // Current workout to do
      
      // Use duration from workout or calculate from exercises
      final totalMinutes = workout.durationMinutes;
      
      final dayLabel = 'Day ${i + 1}';

      workoutWidgets.add(_buildWorkoutItem(
        context,
        dayLabel,
        workout.name,
        workout.description ?? '$totalMinutes min',
        isCompleted,
        isToday ? () => onStartWorkout?.call(workout) : null,
      ));
    }

    return workoutWidgets;
  }

  Widget _buildWorkoutItem(
    BuildContext context,
    String day,
    String workoutName,
    String duration,
    bool isCompleted,
    VoidCallback? onStart,
  ) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isCompleted
              ? Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$day - $workoutName',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                duration,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!isCompleted && onStart != null)
          InkWell(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Start',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}