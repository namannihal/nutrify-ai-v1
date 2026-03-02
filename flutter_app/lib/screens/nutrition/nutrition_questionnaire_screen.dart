import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/generation_provider.dart';

/// Nutrition questionnaire shown before generating AI meal plans
/// Collects detailed nutrition preferences that weren't part of onboarding
class NutritionQuestionnaireScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const NutritionQuestionnaireScreen({super.key, this.onComplete});

  @override
  ConsumerState<NutritionQuestionnaireScreen> createState() =>
      _NutritionQuestionnaireScreenState();
}

class _NutritionQuestionnaireScreenState
    extends ConsumerState<NutritionQuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  // Form data
  String? _dietType;
  List<String> _cuisinePreferences = [];
  String? _mealsPerDay;
  String? _cookingTime;
  String? _budgetLevel;
  List<String> _allergies = [];
  List<String> _intolerances = [];
  List<String> _medicalConditions = [];
  List<String> _foodLikes = [];
  List<String> _supplements = [];
  String? _eatingStyle;

  final List<String> _dietTypes = [
    'No Restriction',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Keto',
    'Paleo',
    'Mediterranean',
    'Low Carb',
    'Low Fat',
    'Halal',
    'Kosher',
  ];

  final List<String> _cuisineOptions = [
    'American',
    'Italian',
    'Mexican',
    'Chinese',
    'Japanese',
    'Indian',
    'Thai',
    'Mediterranean',
    'Middle Eastern',
    'Korean',
    'Vietnamese',
    'French',
  ];

  final List<String> _commonLikes = [
    'Chicken',
    'Fish',
    'Beef',
    'Pork',
    'Eggs',
    'Dairy',
    'Vegetables',
    'Fruits',
    'Grains',
    'Nuts',
    'I like everything',
  ];
  final List<String> _allergyOptions = [
    'Peanuts',
    'Tree Nuts',
    'Milk/Dairy',
    'Eggs',
    'Wheat',
    'Soy',
    'Fish',
    'Shellfish',
    'Sesame',
    'None',
  ];

  final List<String> _intoleranceOptions = [
    'Lactose',
    'Gluten',
    'Fructose',
    'Histamine',
    'Caffeine',
    'None',
  ];

  final List<String> _medicalConditionOptions = [
    'Diabetes',
    'High Blood Pressure',
    'High Cholesterol',
    'GERD/Acid Reflux',
    'IBS',
    'Celiac Disease',
    'Kidney Disease',
    'Heart Disease',
    'None',
  ];

  final List<String> _supplementOptions = [
    'Protein Powder',
    'Creatine',
    'BCAAs',
    'Pre-Workout',
    'Multivitamin',
    'Omega-3 / Fish Oil',
    'Vitamin D',
    'None',
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
      final nutritionPreferences = {
        'diet_type': _dietType,
        'cuisine_preferences': _cuisinePreferences,
        'meals_per_day': _mealsPerDay,
        'cooking_time': _cookingTime,
        'budget_level': _budgetLevel,
        'allergies': _allergies.contains('None') ? [] : _allergies,
        'intolerances': _intolerances.contains('None') ? [] : _intolerances,
        'medical_conditions':
            _medicalConditions.contains('None') ? [] : _medicalConditions,
        'food_likes': _foodLikes.contains('I like everything') ? [] : _foodLikes,
        'supplements': _supplements.contains('None') ? [] : _supplements,
        'eating_style': _eatingStyle,
        'questionnaire_completed': true,
      };

      // Update profile with nutrition preferences
      final success =
          await ref.read(authNotifierProvider.notifier).updateProfile({
        'nutrition_preferences': nutritionPreferences,
      });

      if (success && mounted) {
        // Auto-trigger generation
        ref.read(generationNotifierProvider.notifier).startNutritionGeneration();
        
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
        title: const Text('Nutrition Profile'),
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
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDietTypePage(),
                _buildMealPreferencesPage(),
                _buildRestrictionsPage(),
                _buildLifestylePage(),
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

  Widget _buildDietTypePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diet Preferences',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Do you follow a specific diet?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Diet type selection
          ..._dietTypes.map((diet) {
            final isSelected = _dietType == diet;
            final icons = {
              'No Restriction': Icons.restaurant,
              'Vegetarian': Icons.eco,
              'Vegan': Icons.grass,
              'Pescatarian': Icons.set_meal,
              'Keto': Icons.local_fire_department,
              'Paleo': Icons.nature,
              'Mediterranean': Icons.water,
              'Low Carb': Icons.grain,
              'Low Fat': Icons.opacity,
              'Halal': Icons.mosque,
              'Kosher': Icons.synagogue,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSelectionCard(
                title: diet,
                icon: icons[diet] ?? Icons.restaurant,
                isSelected: isSelected,
                onTap: () => setState(() => _dietType = diet),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Cuisine preferences
          Text(
            'Favorite Cuisines',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select cuisines you enjoy (helps variety)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cuisineOptions.map((cuisine) {
              final isSelected = _cuisinePreferences.contains(cuisine);
              return FilterChip(
                label: Text(cuisine),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _cuisinePreferences.add(cuisine);
                    } else {
                      _cuisinePreferences.remove(cuisine);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Preferences',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'How do you like to eat?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Meals per day
          Text(
            'Meals per day',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                ['2 meals', '3 meals', '4 meals', '5 meals', '6 meals'].map((meals) {
              final isSelected = _mealsPerDay == meals;
              return ChoiceChip(
                label: Text(meals),
                selected: isSelected,
                onSelected: (_) => setState(() => _mealsPerDay = meals),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Cooking time preference
          Text(
            'Time available for cooking',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          ...['minimal', 'moderate', 'plenty'].map((time) {
            final labels = {
              'minimal': 'Minimal (< 15 min)',
              'moderate': 'Moderate (15-30 min)',
              'plenty': 'Plenty (30+ min)',
            };
            final descriptions = {
              'minimal': 'Quick meals, minimal prep',
              'moderate': 'Some cooking, reasonable effort',
              'plenty': 'Enjoy cooking, elaborate meals ok',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOptionCard(
                title: labels[time]!,
                subtitle: descriptions[time]!,
                icon: Icons.timer,
                isSelected: _cookingTime == time,
                onTap: () => setState(() => _cookingTime = time),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Budget
          Text(
            'Grocery budget',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['budget', 'moderate', 'flexible'].map((budget) {
              final labels = {
                'budget': 'Budget-friendly',
                'moderate': 'Moderate',
                'flexible': 'Flexible',
              };
              final isSelected = _budgetLevel == budget;
              return ChoiceChip(
                label: Text(labels[budget]!),
                selected: isSelected,
                onSelected: (_) => setState(() => _budgetLevel = budget),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restrictions & Health',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Important for safe meal planning',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Allergies
          Text(
            'Food Allergies',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll completely avoid these ingredients',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergyOptions.map((allergy) {
              final isSelected = _allergies.contains(allergy);
              return FilterChip(
                label: Text(allergy),
                selected: isSelected,
                selectedColor:
                    Theme.of(context).colorScheme.errorContainer,
                onSelected: (selected) {
                  setState(() {
                    if (allergy == 'None') {
                      _allergies = selected ? ['None'] : [];
                    } else {
                      _allergies.remove('None');
                      if (selected) {
                        _allergies.add(allergy);
                      } else {
                        _allergies.remove(allergy);
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Intolerances
          Text(
            'Food Intolerances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _intoleranceOptions.map((intolerance) {
              final isSelected = _intolerances.contains(intolerance);
              return FilterChip(
                label: Text(intolerance),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (intolerance == 'None') {
                      _intolerances = selected ? ['None'] : [];
                    } else {
                      _intolerances.remove('None');
                      if (selected) {
                        _intolerances.add(intolerance);
                      } else {
                        _intolerances.remove(intolerance);
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Medical conditions
          Text(
            'Medical Conditions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Helps us recommend appropriate foods',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _medicalConditionOptions.map((condition) {
              final isSelected = _medicalConditions.contains(condition);
              return FilterChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (condition == 'None') {
                      _medicalConditions = selected ? ['None'] : [];
                    } else {
                      _medicalConditions.remove('None');
                      if (selected) {
                        _medicalConditions.add(condition);
                      } else {
                        _medicalConditions.remove(condition);
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestylePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lifestyle & Preferences',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Final touches for your perfect meal plan',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Food likes
          Text(
            'Foods you like',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select foods you enjoy (helps personalize meal plans)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonLikes.map((food) {
              final isSelected = _foodLikes.contains(food);
              return ChoiceChip(
                label: Text(food),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (food == 'I like everything') {
                      _foodLikes = selected ? ['I like everything'] : [];
                    } else {
                      _foodLikes.remove('I like everything');
                      if (selected) {
                        _foodLikes.add(food);
                      } else {
                        _foodLikes.remove(food);
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Supplements
          Text(
            'Current supplements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'So we can factor them into your nutrition',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _supplementOptions.map((supplement) {
              final isSelected = _supplements.contains(supplement);
              return FilterChip(
                label: Text(supplement),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (supplement == 'None') {
                      _supplements = selected ? ['None'] : [];
                    } else {
                      _supplements.remove('None');
                      if (selected) {
                        _supplements.add(supplement);
                      } else {
                        _supplements.remove(supplement);
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Eating style
          Text(
            'Eating style',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          ...['structured', 'flexible', 'intuitive'].map((style) {
            final labels = {
              'structured': 'Structured',
              'flexible': 'Flexible',
              'intuitive': 'Intuitive',
            };
            final descriptions = {
              'structured': 'Prefer exact portions and meal times',
              'flexible': 'Like guidelines but with room to adjust',
              'intuitive': 'Eat based on hunger cues',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOptionCard(
                title: labels[style]!,
                subtitle: descriptions[style]!,
                icon: Icons.restaurant_menu,
                isSelected: _eatingStyle == style,
                onTap: () => setState(() => _eatingStyle = style),
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
                    'Your AI meal plan will be personalized based on these preferences.',
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
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
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
