import 'package:flutter/material.dart';
import '../services/api.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  bool isGenerating = false;
  String status = 'No plan yet';

  Future<void> generate() async {
    setState(() => isGenerating = true);
    try {
      final res = await ApiClient().generateNutrition();
      setState(() => status = 'Plan generated: ${res['id'] ?? 'unknown'}');
    } catch (e) {
      setState(() => status = 'Error: $e');
    } finally {
      setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: isGenerating ? null : generate, child: Text(isGenerating ? 'Generating...' : 'Generate Nutrition Plan')),
          ],
        ),
      ),
    );
  }
}
