import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../models/progress.dart';

enum ProgressMetric {
  weight,
  bodyFat,
  muscleMass,
  chest,
  waist,
  hips,
  arms,
}

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressMetric _selectedMetric = ProgressMetric.weight;


  @override
  Widget build(BuildContext context) {
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
            
            // Progress Chart Card with Metric Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress Chart',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton<ProgressMetric>(
                          value: _selectedMetric,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: ProgressMetric.weight,
                              child: Text('Weight'),
                            ),
                            DropdownMenuItem(
                              value: ProgressMetric.bodyFat,
                              child: Text('Body Fat %'),
                            ),
                            DropdownMenuItem(
                              value: ProgressMetric.muscleMass,
                              child: Text('Muscle Mass'),
                            ),
                            DropdownMenuItem(
                              value: ProgressMetric.chest,
                              child: Text('Chest'),
                            ),
                            DropdownMenuItem(
                              value: ProgressMetric.waist,
                              child: Text('Waist'),
                            ),
                            DropdownMenuItem(
                              value: ProgressMetric.hips,
                              child: Text('Hips'),
                            ),
                            DropdownMenuItem(
                              value: ProgressMetric.arms,
                              child: Text('Arms'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMetric = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildMetricChart(context, progressState.entries, _selectedMetric),
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

  Widget _buildMetricChart(BuildContext context, List<ProgressEntry> entries, ProgressMetric metric) {
    // Filter entries based on selected metric
    final metricEntries = entries.where((e) {
      switch (metric) {
        case ProgressMetric.weight:
          return e.weight != null;
        case ProgressMetric.bodyFat:
          return e.bodyFatPercentage != null;
        case ProgressMetric.muscleMass:
          return e.muscleMass != null;
        case ProgressMetric.chest:
          return e.measurements?['chest_cm'] != null;
        case ProgressMetric.waist:
          return e.measurements?['waist_cm'] != null;
        case ProgressMetric.hips:
          return e.measurements?['hips_cm'] != null;
        case ProgressMetric.arms:
          return e.measurements?['arms_cm'] != null;
      }
    }).toList()
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));

    if (metricEntries.isEmpty) {
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
              'No ${_getMetricName(metric).toLowerCase()} data yet',
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

    // Check for sudden changes and show warning
    _checkForSuddenChanges(context, metricEntries, metric);

    // Take last 14 entries max for better visualization
    final chartEntries = metricEntries.length > 14
        ? metricEntries.sublist(metricEntries.length - 14)
        : metricEntries;

    // Create spots for the chart
    final spots = <FlSpot>[];
    for (int i = 0; i < chartEntries.length; i++) {
      final value = _getMetricValue(chartEntries[i], metric);
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    if (spots.isEmpty) return const SizedBox();

    // Calculate min/max for Y axis
    final values = spots.map((s) => s.y).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    
    
    // Ensure minimum padding even if all values are the same
    final valueRange = maxValue - minValue;
    final padding = valueRange > 0 
        ? valueRange * 0.2 
        : (maxValue > 0 ? maxValue * 0.1 : 1.0); // Fallback to 1.0 if maxValue is 0
    final yMin = (minValue - padding).clamp(0.0, double.infinity);
    final yMax = maxValue + padding;
    
    // Ensure minimum interval for chart axes (prevent division by zero)
    final yRange = yMax - yMin;
    final safeInterval = yRange > 0 ? yRange / 4 : 1.0;
    
    // Additional safety: ensure interval is never zero
    final finalInterval = safeInterval > 0 ? safeInterval : 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: finalInterval,
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
              interval: finalInterval,
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
            color: _getMetricColor(context, metric),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getMetricColor(context, metric),
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _getMetricColor(context, metric).withValues(alpha: 0.1),
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
                  '${DateFormat('MMM d').format(date)}\n${spot.y.toStringAsFixed(1)} ${_getMetricUnit(metric)}',
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

  void _checkForSuddenChanges(BuildContext context, List<ProgressEntry> entries, ProgressMetric metric) {
    if (entries.length < 2) return;

    final latest = entries.last;
    final previous = entries[entries.length - 2];
    
    final latestValue = _getMetricValue(latest, metric);
    final previousValue = _getMetricValue(previous, metric);
    
    if (latestValue == null || previousValue == null) return;

    final change = (latestValue - previousValue).abs();
    bool showWarning = false;
    String warningMessage = '';

    switch (metric) {
      case ProgressMetric.weight:
        if (change >= 10.0) {
          showWarning = true;
          warningMessage = 'Sudden weight change of ${change.toStringAsFixed(1)}kg detected. Please verify your entry is correct.';
        }
        break;
      case ProgressMetric.bodyFat:
        if (change >= 5.0) {
          showWarning = true;
          warningMessage = 'Sudden body fat change of ${change.toStringAsFixed(1)}% detected. Please verify your entry is correct.';
        }
        break;
      case ProgressMetric.muscleMass:
        if (change >= 5.0) {
          showWarning = true;
          warningMessage = 'Sudden muscle mass change of ${change.toStringAsFixed(1)}kg detected. Please verify your entry is correct.';
        }
        break;
      case ProgressMetric.chest:
      case ProgressMetric.waist:
      case ProgressMetric.hips:
      case ProgressMetric.arms:
        if (change >= 10.0) {
          showWarning = true;
          warningMessage = 'Sudden ${_getMetricName(metric).toLowerCase()} change of ${change.toStringAsFixed(1)}cm detected. Please verify your entry is correct.';
        }
        break;
    }

    if (showWarning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(warningMessage)),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      });
    }
  }

  String _getMetricName(ProgressMetric metric) {
    switch (metric) {
      case ProgressMetric.weight:
        return 'Weight';
      case ProgressMetric.bodyFat:
        return 'Body Fat';
      case ProgressMetric.muscleMass:
        return 'Muscle Mass';
      case ProgressMetric.chest:
        return 'Chest';
      case ProgressMetric.waist:
        return 'Waist';
      case ProgressMetric.hips:
        return 'Hips';
      case ProgressMetric.arms:
        return 'Arms';
    }
  }

  String _getMetricUnit(ProgressMetric metric) {
    switch (metric) {
      case ProgressMetric.weight:
        return 'kg';
      case ProgressMetric.bodyFat:
        return '%';
      case ProgressMetric.muscleMass:
        return 'kg';
      case ProgressMetric.chest:
      case ProgressMetric.waist:
      case ProgressMetric.hips:
      case ProgressMetric.arms:
        return 'cm';
    }
  }

  double? _getMetricValue(ProgressEntry entry, ProgressMetric metric) {
    switch (metric) {
      case ProgressMetric.weight:
        return entry.weight;
      case ProgressMetric.bodyFat:
        return entry.bodyFatPercentage;
      case ProgressMetric.muscleMass:
        return entry.muscleMass;
      case ProgressMetric.chest:
        return entry.measurements?['chest_cm']?.toDouble();
      case ProgressMetric.waist:
        return entry.measurements?['waist_cm']?.toDouble();
      case ProgressMetric.hips:
        return entry.measurements?['hips_cm']?.toDouble();
      case ProgressMetric.arms:
        return entry.measurements?['arms_cm']?.toDouble();
    }
  }

  Color _getMetricColor(BuildContext context, ProgressMetric metric) {
    switch (metric) {
      case ProgressMetric.weight:
        return Theme.of(context).colorScheme.primary;
      case ProgressMetric.bodyFat:
        return Colors.orange;
      case ProgressMetric.muscleMass:
        return Colors.green;
      case ProgressMetric.chest:
        return Colors.purple;
      case ProgressMetric.waist:
        return Colors.teal;
      case ProgressMetric.hips:
        return Colors.pink;
      case ProgressMetric.arms:
        return Colors.indigo;
    }
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
    
    // Ensure minimum padding even if all weights are the same
    final weightRange = maxWeight - minWeight;
    final padding = weightRange > 0 
        ? weightRange * 0.2 
        : (maxWeight > 0 ? maxWeight * 0.1 : 1.0); // Fallback to 1.0 if maxWeight is 0
    final yMin = (minWeight - padding).clamp(0.0, double.infinity);
    final yMax = maxWeight + padding;
    
    // Ensure minimum interval for chart axes (prevent division by zero)
    final yRange = yMax - yMin;
    final safeInterval = yRange > 0 ? yRange / 4 : 1.0;
    
    // Additional safety: ensure interval is never zero
    final finalInterval = safeInterval > 0 ? safeInterval : 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: finalInterval,
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
              interval: finalInterval,
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