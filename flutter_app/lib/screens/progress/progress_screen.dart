import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../models/progress.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(progressNotifierProvider);
    final profile = ref.watch(authNotifierProvider).profile;
    
    // Get latest entry for current stats
    final latestEntry = progressState.entries.isNotEmpty 
        ? progressState.entries.first 
        : null;
    
    // Calculate changes (comparing latest to second latest)
    final weightChange = _calculateChange(
      progressState.entries.map((e) => e.weight).toList(),
    );
    final bodyFatChange = _calculateChange(
      progressState.entries.map((e) => e.bodyFatPercentage).toList(),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              context.push('/add-progress');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Weight',
                    latestEntry?.weight != null 
                        ? '${latestEntry!.weight!.toStringAsFixed(1)} kg'
                        : profile?.weight != null
                            ? '${profile!.weight!.toStringAsFixed(1)} kg'
                            : '--',
                    weightChange != null ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg' : '--',
                    Icons.monitor_weight,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Body Fat',
                    latestEntry?.bodyFatPercentage != null 
                        ? '${latestEntry!.bodyFatPercentage!.toStringAsFixed(1)}%'
                        : '--',
                    bodyFatChange != null ? '${bodyFatChange >= 0 ? '+' : ''}${bodyFatChange.toStringAsFixed(1)}%' : '--',
                    Icons.straighten,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress Chart Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildWeightChart(context, progressState.entries),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Entries
            Text(
              'Recent Entries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (progressState.entries.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No progress entries yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to log your first entry',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...progressState.entries.take(5).map((entry) {
                final date = DateTime.parse(entry.entryDate);
                final now = DateTime.now();
                final difference = now.difference(date).inDays;
                
                String dateText;
                if (difference == 0) {
                  dateText = 'Today';
                } else if (difference == 1) {
                  dateText = 'Yesterday';
                } else {
                  dateText = '$difference days ago';
                }
                
                final weightText = entry.weight != null 
                    ? 'Weight: ${entry.weight!.toStringAsFixed(1)} kg' 
                    : 'No weight data';
                final bodyFatText = entry.bodyFatPercentage != null 
                    ? 'Body Fat: ${entry.bodyFatPercentage!.toStringAsFixed(1)}%' 
                    : 'No body fat data';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProgressEntry(context, dateText, weightText, bodyFatText),
                );
              }).toList(),
            
            const SizedBox(height: 16),
            
            // Achievements Section
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Calculate achievements dynamically
            ..._buildAchievements(context, progressState.entries),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart(BuildContext context, List<ProgressEntry> entries) {
    // Filter entries with weight data and sort by date (oldest first for chart)
    final weightEntries = entries
        .where((e) => e.weight != null)
        .toList()
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));

    if (weightEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No weight data yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add progress entries to see your chart',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Take last 14 entries max for better visualization
    final chartEntries = weightEntries.length > 14
        ? weightEntries.sublist(weightEntries.length - 14)
        : weightEntries;

    // Create spots for the chart
    final spots = <FlSpot>[];
    for (int i = 0; i < chartEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), chartEntries[i].weight!));
    }

    // Calculate min/max for Y axis
    final weights = chartEntries.map((e) => e.weight!).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.2;
    final yMin = (minWeight - padding).clamp(0.0, double.infinity);
    final yMax = maxWeight + padding;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (yMax - yMin) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: chartEntries.length > 7 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartEntries.length) {
                  return const SizedBox.shrink();
                }
                final date = DateTime.parse(chartEntries[index].entryDate);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('d/M').format(date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: (yMax - yMin) / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (chartEntries.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final entry = chartEntries[index];
                final date = DateTime.parse(entry.entryDate);
                return LineTooltipItem(
                  '${DateFormat('MMM d').format(date)}\n${spot.y.toStringAsFixed(1)} kg',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAchievements(BuildContext context, List<ProgressEntry> entries) {
    final List<Widget> achievements = [];
    
    if (entries.isEmpty) {
      achievements.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'No achievements yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep logging your progress to earn achievements!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
      return achievements;
    }
    
    // Check for consecutive days streak
    final streakDays = _calculateStreak(entries);
    if (streakDays >= 7) {
      achievements.add(_buildAchievementCard(
        context,
        '$streakDays-Day Streak',
        'Logged progress for $streakDays consecutive days',
        Icons.local_fire_department,
        Colors.orange,
      ));
      achievements.add(const SizedBox(height: 12));
    } else if (streakDays >= 3) {
      achievements.add(_buildAchievementCard(
        context,
        '$streakDays-Day Streak',
        'Keep it up! Aim for 7 days',
        Icons.local_fire_department,
        Colors.orange.withOpacity(0.6),
      ));
      achievements.add(const SizedBox(height: 12));
    }
    
    // Check for weight loss/gain goal
    if (entries.length >= 2) {
      final weights = entries
          .map((e) => e.weight)
          .where((w) => w != null)
          .cast<double>()
          .toList();
      
      if (weights.length >= 2) {
        final weightChange = weights.first - weights.last;
        if (weightChange.abs() >= 2.0) {
          final isLoss = weightChange < 0;
          achievements.add(_buildAchievementCard(
            context,
            isLoss ? 'Weight Loss Goal' : 'Weight Gain Goal',
            '${isLoss ? 'Lost' : 'Gained'} ${weightChange.abs().toStringAsFixed(1)}kg',
            Icons.emoji_events,
            Colors.amber,
          ));
          achievements.add(const SizedBox(height: 12));
        }
      }
    }
    
    // Check for consistency (10+ entries)
    if (entries.length >= 10) {
      achievements.add(_buildAchievementCard(
        context,
        'Consistency Champion',
        'Logged ${entries.length} progress entries',
        Icons.star,
        Colors.purple,
      ));
      achievements.add(const SizedBox(height: 12));
    }
    
    // Check for body fat improvement
    if (entries.length >= 2) {
      final bodyFatValues = entries
          .map((e) => e.bodyFatPercentage)
          .where((bf) => bf != null)
          .cast<double>()
          .toList();
      
      if (bodyFatValues.length >= 2) {
        final bodyFatChange = bodyFatValues.first - bodyFatValues.last;
        if (bodyFatChange <= -2.0) {
          achievements.add(_buildAchievementCard(
            context,
            'Body Transformation',
            'Reduced body fat by ${bodyFatChange.abs().toStringAsFixed(1)}%',
            Icons.fitness_center,
            Colors.green,
          ));
          achievements.add(const SizedBox(height: 12));
        }
      }
    }
    
    if (achievements.isEmpty) {
      achievements.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Keep logging to unlock achievements!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    
    return achievements;
  }
  
  int _calculateStreak(List<ProgressEntry> entries) {
    if (entries.isEmpty) return 0;
    
    // Sort entries by date (most recent first)
    final sortedEntries = entries.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a.entryDate);
        final dateB = DateTime.parse(b.entryDate);
        return dateB.compareTo(dateA);
      });
    
    int streak = 0;
    DateTime? lastDate;
    
    for (var entry in sortedEntries) {
      final entryDate = DateTime.parse(entry.entryDate);
      final normalizedEntryDate = DateTime(entryDate.year, entryDate.month, entryDate.day);
      
      if (lastDate == null) {
        // First entry
        final today = DateTime.now();
        final normalizedToday = DateTime(today.year, today.month, today.day);
        
        // Check if the most recent entry is today or yesterday
        final difference = normalizedToday.difference(normalizedEntryDate).inDays;
        if (difference > 1) {
          // Streak is broken
          return 0;
        }
        streak = 1;
        lastDate = normalizedEntryDate;
      } else {
        // Check if this entry is consecutive
        final difference = lastDate.difference(normalizedEntryDate).inDays;
        if (difference == 1) {
          streak++;
          lastDate = normalizedEntryDate;
        } else {
          // Streak broken
          break;
        }
      }
    }
    
    return streak;
  }

  static double? _calculateChange(List<double?> values) {
    if (values.length < 2) return null;
    final latest = values.first;
    final previous = values[1];
    if (latest == null || previous == null) return null;
    return latest - previous;
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, String change, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              change,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressEntry(BuildContext context, String date, String weight, String bodyFat) {
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
            Icons.timeline,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(date),
        subtitle: Text('$weight • $bodyFat'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Show progress details
        },
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, String title, String description, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}