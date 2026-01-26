import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/generation_provider.dart';

/// Fitness questionnaire shown before generating AI workout plans
/// Collects detailed fitness preferences that weren't part of onboarding
class FitnessQuestionnaireScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const FitnessQuestionnaireScreen({super.key, this.onComplete});

  @override
  ConsumerState<FitnessQuestionnaireScreen> createState() =>
      _FitnessQuestionnaireScreenState();
}

class _FitnessQuestionnaireScreenState
    extends ConsumerState<FitnessQuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  // Form data
  bool _hasGymAccess = false;
  bool _hasHomeEquipment = false;
  List<String> _selectedEquipment = [];
  String? _fitnessExperience;
  String? _workoutFrequency;
  String? _preferredDuration;
  List<String> _focusAreas = [];
  List<String> _injuries = [];
  String? _cardioPreference;
  List<String> _fitnessGoals = [];

  final List<String> _equipmentOptions = [
    'Dumbbells',
    'Barbell',
    'Kettlebells',
    'Resistance Bands',
    'Pull-up Bar',
    'Bench',
    'Cable Machine',
    'Squat Rack',
    'Treadmill',
    'Stationary Bike',
    'Rowing Machine',
    'Yoga Mat',
  ];

  final List<String> _muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Core',
    'Legs',
    'Glutes',
    'Full Body',
  ];

  final List<String> _commonInjuries = [
    'Lower Back',
    'Knee',
    'Shoulder',
    'Wrist',
    'Ankle',
    'Neck',
    'Hip',
    'None',
  ];

  final List<String> _goalOptions = [
    'Build Muscle',
    'Lose Fat',
    'Increase Strength',
    'Improve Endurance',
    'Better Flexibility',
    'Sports Performance',
    'General Fitness',
    'Rehabilitation',
  ];

  int get _totalPages => 4;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitQuestionnaire();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitQuestionnaire() async {
    setState(() => _isSubmitting = true);

    try {
      final fitnessPreferences = {
        'has_gym_access': _hasGymAccess,
        'has_home_equipment': _hasHomeEquipment,
        'available_equipment': _selectedEquipment,
        'fitness_experience': _fitnessExperience,
        'workout_frequency': _workoutFrequency,
        'preferred_duration': _preferredDuration,
        'focus_areas': _focusAreas,
        'injuries_limitations': _injuries.contains('None') ? [] : _injuries,
        'cardio_preference': _cardioPreference,
        'fitness_goals': _fitnessGoals,
        'questionnaire_completed': true,
      };

      // Update profile with fitness preferences
      final success = await ref.read(authNotifierProvider.notifier).updateProfile({
        'fitness_preferences': fitnessPreferences,
      });

      if (success && mounted) {
        // Auto-trigger generation
        ref.read(generationNotifierProvider.notifier).startFitnessGeneration();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved! Generating your plan...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onComplete?.call();
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        throw Exception('Failed to save preferences');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildGymAccessPage(),
                _buildExperiencePage(),
                _buildPreferencesPage(),
                _buildGoalsPage(),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _currentPage > 0 ? 2 : 1,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _nextPage,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentPage == _totalPages - 1
                                ? 'Complete'
                                : 'Continue',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGymAccessPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where do you workout?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us recommend appropriate exercises',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Gym access toggle
          _buildOptionCard(
            title: 'Gym Access',
            subtitle: 'I have access to a gym or fitness center',
            icon: Icons.fitness_center,
            isSelected: _hasGymAccess,
            onTap: () => setState(() => _hasGymAccess = !_hasGymAccess),
          ),
          const SizedBox(height: 12),

          // Home equipment toggle
          _buildOptionCard(
            title: 'Home Equipment',
            subtitle: 'I have workout equipment at home',
            icon: Icons.home,
            isSelected: _hasHomeEquipment,
            onTap: () => setState(() => _hasHomeEquipment = !_hasHomeEquipment),
          ),

          if (_hasGymAccess || _hasHomeEquipment) ...[
            const SizedBox(height: 32),
            Text(
              'Available Equipment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all equipment you have access to',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equipmentOptions.map((equipment) {
                final isSelected = _selectedEquipment.contains(equipment);
                return FilterChip(
                  label: Text(equipment),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEquipment.add(equipment);
                      } else {
                        _selectedEquipment.remove(equipment);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],

          if (!_hasGymAccess && !_hasHomeEquipment) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No problem! We\'ll create a bodyweight workout plan for you.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperiencePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Experience',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us understand your fitness background',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Experience level
          Text(
            'Fitness Experience',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          ...['beginner', 'intermediate', 'advanced'].map((level) {
            final labels = {
              'beginner': 'Beginner',
              'intermediate': 'Intermediate',
              'advanced': 'Advanced',
            };
            final descriptions = {
              'beginner': 'New to working out or returning after a long break',
              'intermediate': '6+ months of consistent training',
              'advanced': '2+ years of dedicated training',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSelectionCard(
                title: labels[level]!,
                subtitle: descriptions[level]!,
                isSelected: _fitnessExperience == level,
                onTap: () => setState(() => _fitnessExperience = level),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Workout frequency
          Text(
            'How often do you want to workout?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['2-3 days', '3-4 days', '4-5 days', '5-6 days', '6-7 days']
                .map((freq) {
              final isSelected = _workoutFrequency == freq;
              return ChoiceChip(
                label: Text(freq),
                selected: isSelected,
                onSelected: (_) => setState(() => _workoutFrequency = freq),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Preferred duration
          Text(
            'Preferred workout duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['30 min', '45 min', '60 min', '75 min', '90 min']
                .map((duration) {
              final isSelected = _preferredDuration == duration;
              return ChoiceChip(
                label: Text(duration),
                selected: isSelected,
                onSelected: (_) => setState(() => _preferredDuration = duration),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training Preferences',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your workout experience',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Focus areas
          Text(
            'Areas to focus on',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select up to 3 areas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _muscleGroups.map((muscle) {
              final isSelected = _focusAreas.contains(muscle);
              return FilterChip(
                label: Text(muscle),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected && _focusAreas.length < 3) {
                      _focusAreas.add(muscle);
                    } else if (!selected) {
                      _focusAreas.remove(muscle);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Injuries/Limitations
          Text(
            'Any injuries or limitations?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll avoid exercises that stress these areas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonInjuries.map((injury) {
              final isSelected = _injuries.contains(injury);
              return FilterChip(
                label: Text(injury),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (injury == 'None') {
                      if (selected) {
                        _injuries = ['None'];
                      } else {
                        _injuries.remove('None');
                      }
                    } else {
                      _injuries.remove('None');
                      if (selected) {
                        _injuries.add(injury);
                      } else {
                        _injuries.remove(injury);
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Cardio preference
          Text(
            'Cardio preference',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          ...['love_it', 'tolerate', 'avoid'].map((pref) {
            final labels = {
              'love_it': 'Love it!',
              'tolerate': 'I can tolerate it',
              'avoid': 'Prefer to avoid',
            };
            final icons = {
              'love_it': Icons.favorite,
              'tolerate': Icons.thumbs_up_down,
              'avoid': Icons.not_interested,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSelectionCard(
                title: labels[pref]!,
                subtitle: '',
                icon: icons[pref]!,
                isSelected: _cardioPreference == pref,
                onTap: () => setState(() => _cardioPreference = pref),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Fitness Goals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'What do you want to achieve?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          Text(
            'Select all that apply',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 16),

          ..._goalOptions.map((goal) {
            final isSelected = _fitnessGoals.contains(goal);
            final icons = {
              'Build Muscle': Icons.fitness_center,
              'Lose Fat': Icons.local_fire_department,
              'Increase Strength': Icons.sports_martial_arts,
              'Improve Endurance': Icons.directions_run,
              'Better Flexibility': Icons.self_improvement,
              'Sports Performance': Icons.sports,
              'General Fitness': Icons.favorite,
              'Rehabilitation': Icons.healing,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOptionCard(
                title: goal,
                subtitle: '',
                icon: icons[goal] ?? Icons.flag,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _fitnessGoals.remove(goal);
                    } else {
                      _fitnessGoals.add(goal);
                    }
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your AI workout plan will be customized based on these preferences.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}
