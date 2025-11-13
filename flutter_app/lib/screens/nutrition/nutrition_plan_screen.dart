import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nutrition_provider.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final nutritionState = ref.watch(nutritionNotifierProvider);

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
                          _buildMacroColumn(context, 'Calories', '1,247', '2,200', Colors.orange),
                          _buildMacroColumn(context, 'Protein', '89g', '150g', Colors.red),
                          _buildMacroColumn(context, 'Carbs', '145g', '275g', Colors.blue),
                          _buildMacroColumn(context, 'Fat', '42g', '73g', Colors.green),
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
              
              _buildMealCard(context, 'Breakfast', 'Oatmeal with berries and nuts', '485 kcal', Icons.wb_sunny, Colors.orange),
              const SizedBox(height: 12),
              _buildMealCard(context, 'Lunch', 'Grilled chicken salad with quinoa', '620 kcal', Icons.wb_cloudy, Colors.blue),
              const SizedBox(height: 12),
              _buildMealCard(context, 'Snack', 'Greek yogurt with almonds', '142 kcal', Icons.coffee, Colors.brown),
              const SizedBox(height: 12),
              _buildMealCard(context, 'Dinner', 'Salmon with roasted vegetables', '680 kcal', Icons.nights_stay, Colors.indigo),
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