import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterIntakeCard extends ConsumerStatefulWidget {
  const WaterIntakeCard({super.key});

  @override
  ConsumerState<WaterIntakeCard> createState() => _WaterIntakeCardState();
}

class _WaterIntakeCardState extends ConsumerState<WaterIntakeCard> {
  int _currentGlasses = 0;
  final int _goal = 8; // 8 glasses per day

  @override
  void initState() {
    super.initState();
    _loadWaterIntake();
  }

  Future<void> _loadWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString('water_date');
    
    // Reset if it's a new day
    if (savedDate != today) {
      await prefs.setString('water_date', today);
      await prefs.setInt('water_glasses', 0);
      if (mounted) {
        setState(() {
          _currentGlasses = 0;
        });
      }
    } else {
      final glasses = prefs.getInt('water_glasses') ?? 0;
      if (mounted) {
        setState(() {
          _currentGlasses = glasses;
        });
      }
    }
  }

  Future<void> _addGlass() async {
    final prefs = await SharedPreferences.getInstance();
    final newCount = _currentGlasses + 1;
    await prefs.setInt('water_glasses', newCount);
    
    setState(() {
      _currentGlasses = newCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentGlasses / _goal).clamp(0.0, 1.0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Water Intake',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_currentGlasses/$_goal glasses',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.blue.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : Colors.blue,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Add Glass Button - Compact Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.filled(
                  onPressed: _addGlass,
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Add 1 glass',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
