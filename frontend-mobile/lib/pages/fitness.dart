import 'package:flutter/material.dart';
import '../services/api.dart';

class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key});

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  bool isGenerating = false;
  String status = 'No plan yet';

  Future<void> generate() async {
    setState(() => isGenerating = true);
    try {
      final res = await ApiClient().generateWorkout();
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
      appBar: AppBar(title: const Text('Fitness Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: isGenerating ? null : generate, child: Text(isGenerating ? 'Generating...' : 'Generate Workout Plan')),
          ],
        ),
      ),
    );
  }
}
