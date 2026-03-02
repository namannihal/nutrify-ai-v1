import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
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
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightController = TextEditingController();

  // Unit preferences
  bool _useMetricHeight = true; // true = cm, false = ft/in
  bool _useMetricWeight = true; // true = kg, false = lbs

  // Form data
  String? _gender;
  String? _activityLevel; // Still needed for TDEE calculation
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
    _heightFeetController.dispose();
    _heightInchesController.dispose();
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

  int get _totalPages => _welcomePages.length + 2; // Welcome pages + 2 form pages (Body Metrics, Consent)

  /// Convert height to cm for storage
  double _getHeightInCm() {
    if (_useMetricHeight) {
      return double.parse(_heightController.text);
    } else {
      // Convert ft/in to cm
      final feet = double.tryParse(_heightFeetController.text) ?? 0;
      final inches = double.tryParse(_heightInchesController.text) ?? 0;
      return (feet * 30.48) + (inches * 2.54);
    }
  }

  /// Convert weight to kg for storage
  double _getWeightInKg() {
    final weight = double.parse(_weightController.text);
    if (_useMetricWeight) {
      return weight;
    } else {
      // Convert lbs to kg
      return weight * 0.453592;
    }
  }

  Future<void> _submitProfile() async {
    // Debug: Print all field values
    debugPrint('=== ONBOARDING VALIDATION ===');
    debugPrint('Age: ${_ageController.text}');
    debugPrint('Gender: $_gender');
    debugPrint('Height (metric=$_useMetricHeight): ${_heightController.text} | ft=${_heightFeetController.text} in=${_heightInchesController.text}');
    debugPrint('Weight: ${_weightController.text}');
    debugPrint('Activity Level: $_activityLevel');
    debugPrint('Data Consent: $_dataConsent');
    debugPrint('Health Disclaimer: $_healthDisclaimer');
    debugPrint('=============================');

    // Validate required fields with specific error messages
    final heightValid = _useMetricHeight
        ? _heightController.text.isNotEmpty
        : (_heightFeetController.text.isNotEmpty || _heightInchesController.text.isNotEmpty);

    // Build list of missing fields for better UX
    final missingFields = <String>[];
    if (_ageController.text.isEmpty) missingFields.add('Age');
    if (_gender == null) missingFields.add('Gender');
    if (!heightValid) missingFields.add('Height');
    if (_weightController.text.isEmpty) missingFields.add('Weight');
    if (_activityLevel == null) missingFields.add('Activity Level');
    if (!_dataConsent) missingFields.add('Data Consent');
    if (!_healthDisclaimer) missingFields.add('Health Disclaimer');

    if (missingFields.isNotEmpty) {
      debugPrint('MISSING FIELDS: $missingFields');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Missing: ${missingFields.join(", ")}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
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
                      'Creating Your Profile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Setting up your personalized health journey',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    try {
      final profileData = {
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'height': _getHeightInCm(),
        'weight': _getWeightInKg(),
        'activity_level': _activityLevel,
        'data_consent': _dataConsent,
        'health_disclaimer': _healthDisclaimer,
        'onboarding_completed': true,
        // Store unit preferences for display
        'unit_preferences': {
          'height_metric': _useMetricHeight,
          'weight_metric': _useMetricWeight,
        },
      };

      // Update profile
      final success = await ref.read(authNotifierProvider.notifier).updateProfile(profileData);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!success) {
        throw Exception('Failed to update profile');
      }

      // Navigate directly to dashboard - no auto plan generation
      if (mounted) {
        context.go('/dashboard');

        // Show welcome message
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome! Explore the app and generate personalized plans when ready.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
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
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe
                  children: [
                    // Welcome pages
                    ..._welcomePages.map((page) => _buildWelcomePage(page)),

                    // Simplified profile setup pages (2 only)
                    _buildBodyMetricsPage(),
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

  Widget _buildBodyMetricsPage() {
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
            'This helps us calculate your nutritional needs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Age
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age *',
              prefixIcon: Icon(Icons.cake),
              hintText: 'Enter your age',
            ),
          ),
          const SizedBox(height: 16),

          // Gender
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Gender *',
              prefixIcon: Icon(Icons.person),
            ),
            items: ['male', 'female', 'other'].map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(gender[0].toUpperCase() + gender.substring(1)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 24),

          // Height with unit toggle
          Row(
            children: [
              Text(
                'Height *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('cm')),
                  ButtonSegment(value: false, label: Text('ft/in')),
                ],
                selected: {_useMetricHeight},
                onSelectionChanged: (selection) {
                  setState(() {
                    _useMetricHeight = selection.first;
                    // Clear values when switching
                    _heightController.clear();
                    _heightFeetController.clear();
                    _heightInchesController.clear();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_useMetricHeight)
            TextFormField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: Icon(Icons.height),
                hintText: 'e.g., 170',
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightFeetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Feet',
                      prefixIcon: Icon(Icons.height),
                      hintText: 'e.g., 5',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heightInchesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Inches',
                      hintText: 'e.g., 8',
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Weight with unit toggle
          Row(
            children: [
              Text(
                'Weight *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('kg')),
                  ButtonSegment(value: false, label: Text('lbs')),
                ],
                selected: {_useMetricWeight},
                onSelectionChanged: (selection) {
                  setState(() {
                    _useMetricWeight = selection.first;
                    _weightController.clear();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _useMetricWeight ? 'Weight (kg)' : 'Weight (lbs)',
              prefixIcon: const Icon(Icons.monitor_weight),
              hintText: _useMetricWeight ? 'e.g., 70' : 'e.g., 154',
            ),
          ),
          const SizedBox(height: 24),

          // Activity Level
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: const InputDecoration(
              labelText: 'Activity Level *',
              prefixIcon: Icon(Icons.directions_run),
            ),
            items: [
              {'value': 'sedentary', 'label': 'Sedentary', 'desc': 'Little or no exercise'},
              {'value': 'lightly_active', 'label': 'Lightly Active', 'desc': 'Light exercise 1-3 days/week'},
              {'value': 'moderately_active', 'label': 'Moderately Active', 'desc': 'Moderate exercise 3-5 days/week'},
              {'value': 'very_active', 'label': 'Very Active', 'desc': 'Hard exercise 6-7 days/week'},
              {'value': 'extremely_active', 'label': 'Extremely Active', 'desc': 'Very hard exercise & physical job'},
            ].map((level) => DropdownMenuItem(
              value: level['value'],
              child: Text(level['label']!),
            )).toList(),
            onChanged: (value) => setState(() => _activityLevel = value),
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