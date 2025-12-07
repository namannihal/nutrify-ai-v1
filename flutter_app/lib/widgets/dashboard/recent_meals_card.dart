import 'package:flutter/material.dart';
import '../../models/nutrition.dart';

class RecentMealsCard extends StatelessWidget {
  final List<Meal>? breakfastMeals;
  final List<Meal>? lunchMeals;
  final List<Meal>? snackMeals;
  final List<Meal>? dinnerMeals;
  final String? aiSuggestion;
  final VoidCallback? onViewAll;

  const RecentMealsCard({
    super.key,
    this.breakfastMeals,
    this.lunchMeals,
    this.snackMeals,
    this.dinnerMeals,
    this.aiSuggestion,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    // Collect all logged meals
    final hasMeals = (breakfastMeals?.isNotEmpty ?? false) ||
        (lunchMeals?.isNotEmpty ?? false) ||
        (snackMeals?.isNotEmpty ?? false) ||
        (dinnerMeals?.isNotEmpty ?? false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Meals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasMeals)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No meals logged today',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._buildMealsList(context),
            if (aiSuggestion != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiSuggestion!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      ),
    );
  }

  List<Widget> _buildMealsList(BuildContext context) {
    final List<Widget> mealWidgets = [];

    // Add breakfast meals
    if (breakfastMeals?.isNotEmpty ?? false) {
      for (var meal in breakfastMeals!) {
        if (mealWidgets.isNotEmpty) {
          mealWidgets.add(const SizedBox(height: 12));
        }
        mealWidgets.add(_buildMealItem(
          context,
          'Breakfast',
          meal.name,
          '${meal.calories} kcal',
          Icons.wb_sunny,
          Colors.orange,
        ));
      }
    }

    // Add lunch meals
    if (lunchMeals?.isNotEmpty ?? false) {
      for (var meal in lunchMeals!) {
        if (mealWidgets.isNotEmpty) {
          mealWidgets.add(const SizedBox(height: 12));
        }
        mealWidgets.add(_buildMealItem(
          context,
          'Lunch',
          meal.name,
          '${meal.calories} kcal',
          Icons.wb_cloudy,
          Colors.blue,
        ));
      }
    }

    // Add snack meals
    if (snackMeals?.isNotEmpty ?? false) {
      for (var meal in snackMeals!) {
        if (mealWidgets.isNotEmpty) {
          mealWidgets.add(const SizedBox(height: 12));
        }
        mealWidgets.add(_buildMealItem(
          context,
          'Snack',
          meal.name,
          '${meal.calories} kcal',
          Icons.coffee,
          Colors.brown,
        ));
      }
    }

    // Add dinner meals
    if (dinnerMeals?.isNotEmpty ?? false) {
      for (var meal in dinnerMeals!) {
        if (mealWidgets.isNotEmpty) {
          mealWidgets.add(const SizedBox(height: 12));
        }
        mealWidgets.add(_buildMealItem(
          context,
          'Dinner',
          meal.name,
          '${meal.calories} kcal',
          Icons.nightlight,
          Colors.indigo,
        ));
      }
    }

    return mealWidgets;
  }

  Widget _buildMealItem(
    BuildContext context,
    String mealType,
    String description,
    String calories,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mealType,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          calories,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}