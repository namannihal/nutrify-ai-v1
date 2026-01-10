import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../widgets/common/loading_overlay.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  // Form controllers
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  // Form data
  String? _gender;
  String? _primaryGoal;
  String? _activityLevel;
  String? _fitnessExperience;
  List<String> _selectedDietaryRestrictions = [];
  String? _mealsPerDay;
  String? _workoutDaysPerWeek;
  List<String> _selectedEquipment = [];
  bool _dataConsent = false;
  bool _healthDisclaimer = false;

  final List<OnboardingPage> _welcomePages = [
    OnboardingPage(
      title: 'AI-Powered Nutrition',
      subtitle: 'Get personalized meal plans tailored to your goals and preferences',
      image: Icons.restaurant_menu,
      color: Color(0xFF2563EB),
    ),
    OnboardingPage(
      title: 'Smart Fitness Plans',
      subtitle: 'Adaptive workout routines that evolve with your progress',
      image: Icons.fitness_center,
      color: Color(0xFF10B981),
    ),
    OnboardingPage(
      title: 'Progress Tracking',
      subtitle: 'Monitor your journey with detailed analytics and insights',
      image: Icons.trending_up,
      color: Color(0xFF8B5CF6),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
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

  void _skipToProfile() {
    _pageController.jumpToPage(_welcomePages.length);
  }

  int get _totalPages => _welcomePages.length + 5; // Welcome pages + 5 form pages

  Future<void> _submitProfile() async {
    // Validate required fields
    if (_ageController.text.isEmpty || _heightController.text.isEmpty || 
        _weightController.text.isEmpty || _gender == null || _primaryGoal == null ||
        _activityLevel == null || !_dataConsent || !_healthDisclaimer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields and accept the terms'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final profileData = {
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'height': double.parse(_heightController.text),
        'weight': double.parse(_weightController.text),
        'primary_goal': _primaryGoal,
        'activity_level': _activityLevel,
        'fitness_experience': _fitnessExperience,
        'dietary_restrictions': _selectedDietaryRestrictions,
        'meals_per_day': _mealsPerDay != null ? int.parse(_mealsPerDay!) : 3,
        'workout_days_per_week': _workoutDaysPerWeek,
        'equipment_access': _selectedEquipment,
        'data_consent': _dataConsent,
        'health_disclaimer': _healthDisclaimer,
        'onboarding_completed': true, // Mark onboarding as complete
      };

      // Step 1: Update profile
      final success = await ref.read(authNotifierProvider.notifier).updateProfile(profileData);
      
      if (!success) {
        throw Exception('Failed to update profile');
      }
      
      // Step 2: Auto-generate AI plans
      if (mounted) {
        // Show generating dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        'Setting up your personalized plans...',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Generating AI meal and workout plans',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take 10-15 seconds',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Generate both plans in parallel
        final results = await Future.wait([
          ref.read(nutritionNotifierProvider.notifier).generateNewPlan(),
          ref.read(fitnessNotifierProvider.notifier).generateNewPlan(),
        ]);

        final nutritionSuccess = results[0];
        final fitnessSuccess = results[1];

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Navigate to dashboard
        if (mounted) {
          context.go('/dashboard');
          
          // Show success message after navigation
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              final message = nutritionSuccess && fitnessSuccess
                  ? '🎉 Your personalized plans are ready!'
                  : nutritionSuccess
                      ? '✓ Meal plan ready! Workout plan failed.'
                      : fitnessSuccess
                          ? '✓ Workout plan ready! Meal plan failed.'
                          : '⚠️ Plans generation failed. Please try manually.';
              
              final color = nutritionSuccess && fitnessSuccess
                  ? Colors.green
                  : nutritionSuccess || fitnessSuccess
                      ? Colors.orange
                      : Colors.red;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: color,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      // Try to close any dialogs safely
      try {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {
        // Dialog might not be open, ignore
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete setup: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
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
    final isWelcomePage = _currentPage < _welcomePages.length;
    
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        child: SafeArea(
          child: Column(
            children: [
              // Skip/Back Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0 && !isWelcomePage)
                      TextButton.icon(
                        onPressed: _previousPage,
                        icon: Icon(Icons.arrow_back),
                        label: Text('Back'),
                      )
                    else
                      SizedBox(width: 80),
                    if (isWelcomePage)
                      TextButton(
                        onPressed: _skipToProfile,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Page View
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  physics: NeverScrollableScrollPhysics(), // Disable swipe
                  children: [
                    // Welcome pages
                    ..._welcomePages.map((page) => _buildWelcomePage(page)),
                    
                    // Profile setup pages
                    _buildBasicInfoPage(),
                    _buildGoalsPage(),
                    _buildFitnessPage(),
                    _buildNutritionPage(),
                    _buildConsentPage(),
                  ],
                ),
              ),
              
              // Bottom Section
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _totalPages,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Next/Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _nextPage,
                        child: Text(
                          _currentPage == _totalPages - 1 
                              ? 'Complete Setup' 
                              : _currentPage == _welcomePages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              page.image,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us create a personalized plan just for you',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Age *',
              prefixIcon: Icon(Icons.cake),
            ),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(
              labelText: 'Gender *',
              prefixIcon: Icon(Icons.person),
            ),
            items: ['male', 'female', 'other'].map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(gender.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Height (cm) *',
                    prefixIcon: Icon(Icons.height),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Weight (kg) *',
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                ),
              ),
            ],
          ),
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
            'What\'s your goal?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your primary fitness objective',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          ...['weight_loss', 'muscle_gain', 'maintenance', 'endurance', 'strength'].map((goal) {
            final isSelected = _primaryGoal == goal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => setState(() => _primaryGoal = goal),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
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
                        _getGoalIcon(goal),
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _formatGoalText(goal),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFitnessPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fitness Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: InputDecoration(
              labelText: 'Activity Level *',
              prefixIcon: Icon(Icons.directions_run),
            ),
            items: ['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active']
                .map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(_formatActivityLevel(level)),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _activityLevel = value),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _fitnessExperience,
            decoration: InputDecoration(
              labelText: 'Fitness Experience',
              prefixIcon: Icon(Icons.fitness_center),
            ),
            items: ['beginner', 'intermediate', 'advanced']
                .map((exp) => DropdownMenuItem(
                      value: exp,
                      child: Text(exp.toUpperCase()),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _fitnessExperience = value),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _workoutDaysPerWeek,
            decoration: InputDecoration(
              labelText: 'Workout Days Per Week',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            items: ['3', '4', '5', '6', '7']
                .map((days) => DropdownMenuItem(
                      value: days,
                      child: Text('$days days'),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _workoutDaysPerWeek = value),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Available Equipment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['dumbbells', 'barbell', 'resistance_bands', 'pull_up_bar', 'none'].map((equipment) {
              final isSelected = _selectedEquipment.contains(equipment);
              return FilterChip(
                label: Text(_formatEquipment(equipment)),
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
      ),
    );
  }

  Widget _buildNutritionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Preferences',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          DropdownButtonFormField<String>(
            value: _mealsPerDay,
            decoration: InputDecoration(
              labelText: 'Meals Per Day',
              prefixIcon: Icon(Icons.restaurant),
            ),
            items: ['3', '4', '5', '6']
                .map((meals) => DropdownMenuItem(
                      value: meals,
                      child: Text('$meals meals'),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _mealsPerDay = value),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Dietary Restrictions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['vegetarian', 'vegan', 'gluten_free', 'dairy_free', 'keto', 'paleo', 'none'].map((restriction) {
              final isSelected = _selectedDietaryRestrictions.contains(restriction);
              return FilterChip(
                label: Text(_formatDietaryRestriction(restriction)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDietaryRestrictions.add(restriction);
                    } else {
                      _selectedDietaryRestrictions.remove(restriction);
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

  Widget _buildConsentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & Consent',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review and accept the following',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          CheckboxListTile(
            value: _dataConsent,
            onChanged: (value) => setState(() => _dataConsent = value ?? false),
            title: Text('Data Usage Consent'),
            subtitle: Text(
              'I consent to Nutrify AI using my data to provide personalized recommendations',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          CheckboxListTile(
            value: _healthDisclaimer,
            onChanged: (value) => setState(() => _healthDisclaimer = value ?? false),
            title: Text('Health Disclaimer'),
            subtitle: Text(
              'I understand this app provides general guidance and is not a substitute for professional medical advice',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your data is encrypted and stored securely. You can delete your account anytime.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case 'weight_loss': return Icons.trending_down;
      case 'muscle_gain': return Icons.fitness_center;
      case 'maintenance': return Icons.balance;
      case 'endurance': return Icons.directions_run;
      case 'strength': return Icons.sports_martial_arts;
      default: return Icons.flag;
    }
  }

  String _formatGoalText(String goal) {
    return goal.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatActivityLevel(String level) {
    return level.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatEquipment(String equipment) {
    return equipment.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatDietaryRestriction(String restriction) {
    return restriction.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final IconData image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.color,
  });
}