import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/progress_provider.dart';
import '../../models/progress.dart';

class AddProgressScreen extends ConsumerStatefulWidget {
  const AddProgressScreen({super.key});

  @override
  ConsumerState<AddProgressScreen> createState() => _AddProgressScreenState();
}

class _AddProgressScreenState extends ConsumerState<AddProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _notesController = TextEditingController();

  // Body measurements
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _hipsController = TextEditingController();
  final _armsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  int _moodScore = 5;
  int _energyScore = 5;
  bool _useCm = true; // true for cm, false for inches

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _sleepHoursController.dispose();
    _notesController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _hipsController.dispose();
    _armsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getMoodEmoji(int score) {
    if (score <= 2) return '😢';
    if (score <= 4) return '😐';
    if (score <= 6) return '🙂';
    if (score <= 8) return '😊';
    return '😄';
  }

  String _getEnergyEmoji(int score) {
    if (score <= 2) return '😴';
    if (score <= 4) return '🥱';
    if (score <= 6) return '😐';
    if (score <= 8) return '💪';
    return '⚡';
  }

  Future<void> _saveProgress() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one field is filled
    final hasWeight = _weightController.text.isNotEmpty;
    final hasBodyFat = _bodyFatController.text.isNotEmpty;
    final hasSleep = _sleepHoursController.text.isNotEmpty;
    final hasMeasurements = _waistController.text.isNotEmpty ||
        _chestController.text.isNotEmpty ||
        _hipsController.text.isNotEmpty ||
        _armsController.text.isNotEmpty;
    final hasNotes = _notesController.text.isNotEmpty;

    if (!hasWeight && !hasBodyFat && !hasSleep && !hasMeasurements && !hasNotes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in at least one field'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build measurements map (always store in cm)
      final measurements = <String, dynamic>{};
      if (_waistController.text.isNotEmpty) {
        final value = double.tryParse(_waistController.text);
        measurements['waist_cm'] = _useCm ? value : (value! * 2.54); // Convert inches to cm
      }
      if (_chestController.text.isNotEmpty) {
        final value = double.tryParse(_chestController.text);
        measurements['chest_cm'] = _useCm ? value : (value! * 2.54);
      }
      if (_hipsController.text.isNotEmpty) {
        final value = double.tryParse(_hipsController.text);
        measurements['hips_cm'] = _useCm ? value : (value! * 2.54);
      }
      if (_armsController.text.isNotEmpty) {
        final value = double.tryParse(_armsController.text);
        measurements['arms_cm'] = _useCm ? value : (value! * 2.54);
      }

      final entry = ProgressEntryCreate(
        entryDate: _selectedDate.toIso8601String().split('T')[0],
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        bodyFatPercentage: _bodyFatController.text.isNotEmpty
            ? double.tryParse(_bodyFatController.text)
            : null,
        moodScore: _moodScore,
        energyScore: _energyScore,
        sleepHours: _sleepHoursController.text.isNotEmpty
            ? double.tryParse(_sleepHoursController.text)
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        measurements: measurements.isNotEmpty ? measurements : null,
      );

      await ref.read(progressNotifierProvider.notifier).addProgressEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Progress entry saved!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Progress'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveProgress,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date Selection Card
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text('Entry Date'),
                subtitle: Text(
                  '${_getDayName(_selectedDate.weekday)}, ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
            ),

            const SizedBox(height: 24),

            // Body Measurements Section
            _buildSectionHeader(context, 'Body Measurements', Icons.monitor_weight),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      suffixText: 'kg',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0 || weight > 500) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bodyFatController,
                    decoration: const InputDecoration(
                      labelText: 'Body Fat',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final bodyFat = double.tryParse(value);
                        if (bodyFat == null || bodyFat < 0 || bodyFat > 100) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Additional Measurements (expandable)
            ExpansionTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Body Measurements'),
              subtitle: const Text('Waist, chest, hips, arms'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Unit Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Unit:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: true,
                                label: Text('cm'),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('in'),
                              ),
                            ],
                            selected: {_useCm},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() {
                                _useCm = newSelection.first;
                              });
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _waistController,
                              decoration: InputDecoration(
                                labelText: 'Waist',
                                suffixText: _useCm ? 'cm' : 'in',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _chestController,
                              decoration: InputDecoration(
                                labelText: 'Chest',
                                suffixText: _useCm ? 'cm' : 'in',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hipsController,
                              decoration: InputDecoration(
                                labelText: 'Hips',
                                suffixText: _useCm ? 'cm' : 'in',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _armsController,
                              decoration: InputDecoration(
                                labelText: 'Arms',
                                suffixText: _useCm ? 'cm' : 'in',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sleep Section
            _buildSectionHeader(context, 'Sleep', Icons.bedtime),
            const SizedBox(height: 12),

            TextFormField(
              controller: _sleepHoursController,
              decoration: const InputDecoration(
                labelText: 'Hours of Sleep',
                hintText: 'How many hours did you sleep?',
                suffixText: 'hours',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final hours = double.tryParse(value);
                  if (hours == null || hours < 0 || hours > 24) {
                    return 'Enter valid hours (0-24)';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Wellbeing Section
            _buildSectionHeader(context, 'How Are You Feeling?', Icons.favorite),
            const SizedBox(height: 16),

            // Mood Score Slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mood, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Mood',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          '${_getMoodEmoji(_moodScore)} $_moodScore/10',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _moodScore.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _moodScore.toString(),
                      onChanged: (value) {
                        setState(() {
                          _moodScore = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Poor',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Excellent',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Energy Score Slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Energy Level',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          '${_getEnergyEmoji(_energyScore)} $_energyScore/10',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _energyScore.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _energyScore.toString(),
                      onChanged: (value) {
                        setState(() {
                          _energyScore = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exhausted',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Energetic',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes Section
            _buildSectionHeader(context, 'Notes', Icons.notes),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'How did you feel today? Any wins or challenges?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveProgress,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Progress Entry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
