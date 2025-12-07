import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../models/progress.dart';
import '../../widgets/common/loading_overlay.dart';

class NutritionPlanScreen extends ConsumerStatefulWidget {
  const NutritionPlanScreen({super.key});

  @override
  ConsumerState<NutritionPlanScreen> createState() => _NutritionPlanScreenState();
}

class _NutritionPlanScreenState extends ConsumerState<NutritionPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nutritionNotifierProvider.notifier).loadCurrentPlan();
      ref.read(progressNotifierProvider.notifier).loadProgressEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nutritionState = ref.watch(nutritionNotifierProvider);
    final profile = ref.watch(authNotifierProvider).profile;
    final progressState = ref.watch(progressNotifierProvider);
    final currentPlan = nutritionState.currentPlan;
    
    // Get daily targets from AI-generated nutrition plan
    final calorieTarget = currentPlan?.dailyCalories ?? _calculateCalorieTarget(profile);
    final proteinTarget = (currentPlan?.macros['protein_grams'] as num?)?.toInt() ?? 
                         (calorieTarget * 0.3 / 4).round();
    final carbsTarget = (currentPlan?.macros['carbs_grams'] as num?)?.toInt() ?? 
                       (calorieTarget * 0.4 / 4).round();
    final fatTarget = (currentPlan?.macros['fat_grams'] as num?)?.toInt() ?? 
                     (calorieTarget * 0.3 / 9).round();
    
    // Get today's meals from the plan
    final today = DateTime.now().weekday; // 1=Monday, 7=Sunday
    final todaysMeals = currentPlan?.meals.firstWhere(
      (meal) => _getDayNumber(meal.day) == today,
      orElse: () => currentPlan.meals.first,
    );
    
    // Get today's progress for consumed values
    final todayDate = DateTime.now().toIso8601String().split('T')[0];
    ProgressEntry? todayProgress;
    
    try {
      todayProgress = progressState.entries.firstWhere(
        (entry) => entry.entryDate.startsWith(todayDate),
      );
    } catch (e) {
      // No entry for today
      todayProgress = null;
    }
    
    // Calculate consumed values from today's meals in the AI-generated plan
    // These represent the planned intake for today
    final consumedCalories = todaysMeals != null ? (
      todaysMeals.breakfast.fold<int>(0, (sum, meal) => sum + meal.calories) +
      todaysMeals.lunch.fold<int>(0, (sum, meal) => sum + meal.calories) +
      todaysMeals.dinner.fold<int>(0, (sum, meal) => sum + meal.calories) +
      todaysMeals.snacks.fold<int>(0, (sum, meal) => sum + meal.calories)
    ) : 0;
    
    final consumedProtein = todaysMeals != null ? (
      todaysMeals.breakfast.fold<double>(0, (sum, meal) => sum + meal.proteinGrams) +
      todaysMeals.lunch.fold<double>(0, (sum, meal) => sum + meal.proteinGrams) +
      todaysMeals.dinner.fold<double>(0, (sum, meal) => sum + meal.proteinGrams) +
      todaysMeals.snacks.fold<double>(0, (sum, meal) => sum + meal.proteinGrams)
    ).toInt() : 0;
    
    final consumedCarbs = todaysMeals != null ? (
      todaysMeals.breakfast.fold<double>(0, (sum, meal) => sum + meal.carbsGrams) +
      todaysMeals.lunch.fold<double>(0, (sum, meal) => sum + meal.carbsGrams) +
      todaysMeals.dinner.fold<double>(0, (sum, meal) => sum + meal.carbsGrams) +
      todaysMeals.snacks.fold<double>(0, (sum, meal) => sum + meal.carbsGrams)
    ).toInt() : 0;
    
    final consumedFat = todaysMeals != null ? (
      todaysMeals.breakfast.fold<double>(0, (sum, meal) => sum + meal.fatGrams) +
      todaysMeals.lunch.fold<double>(0, (sum, meal) => sum + meal.fatGrams) +
      todaysMeals.dinner.fold<double>(0, (sum, meal) => sum + meal.fatGrams) +
      todaysMeals.snacks.fold<double>(0, (sum, meal) => sum + meal.fatGrams)
    ).toInt() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // TODO: Show date picker
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: nutritionState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMacroColumn(context, 'Calories', consumedCalories.toString(), calorieTarget.toString(), Colors.orange),
                          _buildMacroColumn(context, 'Protein', '${consumedProtein}g', '${proteinTarget}g', Colors.red),
                          _buildMacroColumn(context, 'Carbs', '${consumedCarbs}g', '${carbsTarget}g', Colors.blue),
                          _buildMacroColumn(context, 'Fat', '${consumedFat}g', '${fatTarget}g', Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Meal Plan
              Text(
                'Today\'s Meal Plan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (currentPlan == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No nutrition plan yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generate your personalized meal plan from the dashboard',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (currentPlan != null && todaysMeals?.breakfast.isNotEmpty == true)
                ...todaysMeals!.breakfast.map((meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMealCard(
                    context, 
                    'Breakfast', 
                    meal.name,
                    '${meal.calories} kcal', 
                    Icons.wb_sunny, 
                    Colors.orange,
                  ),
                )),
              
              if (currentPlan != null && todaysMeals?.lunch.isNotEmpty == true)
                ...todaysMeals!.lunch.map((meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMealCard(
                    context, 
                    'Lunch', 
                    meal.name,
                    '${meal.calories} kcal', 
                    Icons.wb_cloudy, 
                    Colors.blue,
                  ),
                )),
              
              if (currentPlan != null && todaysMeals?.snacks.isNotEmpty == true)
                ...todaysMeals!.snacks.map((meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMealCard(
                    context, 
                    'Snack', 
                    meal.name,
                    '${meal.calories} kcal', 
                    Icons.coffee, 
                    Colors.brown,
                  ),
                )),
              
              if (currentPlan != null && todaysMeals?.dinner.isNotEmpty == true)
                ...todaysMeals!.dinner.map((meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMealCard(
                    context, 
                    'Dinner', 
                    meal.name,
                    '${meal.calories} kcal', 
                    Icons.nights_stay, 
                    Colors.indigo,
                  ),
                )),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add meal logging
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  int _calculateCalorieTarget(profile) {
    if (profile == null) return 2000;
    
    final age = profile.age ?? 25;
    final weight = profile.weight ?? 70;
    final height = profile.height ?? 170;
    final gender = profile.gender ?? 'male';
    final activityLevel = profile.activityLevel ?? 'moderate';
    final goal = profile.primaryGoal ?? 'maintain';
    
    // Mifflin-St Jeor BMR
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    bmr += gender == 'male' ? 5 : -161;
    
    // Activity multiplier
    final activityMultipliers = {
      'sedentary': 1.2,
      'lightly_active': 1.375,
      'moderately_active': 1.55,
      'very_active': 1.725,
      'extremely_active': 1.9,
    };
    final tdee = bmr * (activityMultipliers[activityLevel] ?? 1.55);
    
    // Goal adjustment
    double targetCalories = tdee;
    if (goal == 'weight_loss') {
      targetCalories -= 500;
    } else if (goal == 'muscle_gain') {
      targetCalories += 300;
    }
    
    return targetCalories.round();
  }

  int _getDayNumber(String day) {
    const days = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    return days[day.toLowerCase()] ?? 1;
  }

  Widget _buildMacroColumn(BuildContext context, String label, String value, String target, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'of $target',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, String meal, String description, String calories, IconData icon, Color color) {
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
          meal,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              calories,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // TODO: Show meal details
        },
      ),
    );
  }
}