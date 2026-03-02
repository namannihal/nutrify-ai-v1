import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification.dart';
import '../providers/gamification_provider.dart';

/// Compact streak card for home screen
class StreakCard extends ConsumerWidget {
  final VoidCallback? onTap;

  const StreakCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return streakAsync.when(
      data: (streak) {
        if (streak == null) {
          return const SizedBox.shrink();
        }
        return _buildCard(context, streak, isDark, theme);
      },
      loading: () => _buildLoadingCard(isDark),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(
    BuildContext context,
    UserStreak streak,
    bool isDark,
    ThemeData theme,
  ) {
    final isActive = streak.isStreakActive;
    final streakColor = isActive ? Colors.orange : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [Colors.orange.shade700, Colors.deepOrange.shade600]
                : [Colors.grey.shade600, Colors.grey.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: streakColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flame icon with animation
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  isActive ? '🔥' : '❄️',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Streak info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${streak.currentStreak} Day${streak.currentStreak != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isActive
                        ? streak.workedOutToday
                            ? 'Great work today!'
                            : 'Keep it going!'
                        : 'Start your streak!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Weekly dots
            Column(
              children: [
                _buildWeekDots(streak),
                const SizedBox(height: 4),
                Text(
                  'This week',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDots(UserStreak streak) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // 0 = Monday

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final worked = streak.currentWeekWorkouts & (1 << index) != 0;
        final isToday = index == today;

        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: worked
                ? Colors.white
                : isToday
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: isToday
                ? Border.all(color: Colors.white, width: 1.5)
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const SizedBox(
        height: 56,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Detailed streak stats for profile or achievements page
class StreakStatsCard extends ConsumerWidget {
  const StreakStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return streakAsync.when(
      data: (streak) {
        if (streak == null) {
          return const SizedBox.shrink();
        }
        return _buildStatsCard(context, streak, isDark, theme);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    UserStreak streak,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Workout Streak',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Main stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  '${streak.currentStreak}',
                  'Current',
                  Colors.orange,
                  isDark,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  '${streak.longestStreak}',
                  'Best',
                  Colors.purple,
                  isDark,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  '${streak.totalWorkouts}',
                  'Total',
                  Colors.blue,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Weekly calendar
          Text(
            'This Week',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          _buildWeekCalendar(streak, isDark, theme),
          const SizedBox(height: 16),
          // Total time
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total workout time: ${streak.formattedTotalTime}',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCalendar(UserStreak streak, bool isDark, ThemeData theme) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now().weekday - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final worked = streak.currentWeekWorkouts & (1 << index) != 0;
        final isToday = index == today;
        final isPast = index < today;

        return Column(
          children: [
            Text(
              days[index],
              style: TextStyle(
                fontSize: 11,
                color: isToday
                    ? theme.colorScheme.primary
                    : isDark
                        ? Colors.grey[500]
                        : Colors.grey[600],
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: worked
                    ? Colors.green
                    : isToday
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : isPast
                            ? (isDark ? Colors.grey[800] : Colors.grey[200])
                            : (isDark ? Colors.grey[850] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: worked
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : isPast
                        ? Icon(Icons.close,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            size: 16)
                        : null,
              ),
            ),
          ],
        );
      }),
    );
  }
}
