import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fitness.dart';
import '../services/api_service.dart';

// Fitness state
class FitnessState {
  final WorkoutPlan? currentPlan;
  final bool isLoading;
  final String? error;

  const FitnessState({
    this.currentPlan,
    this.isLoading = false,
    this.error,
  });

  FitnessState copyWith({
    WorkoutPlan? currentPlan,
    bool? isLoading,
    String? error,
  }) {
    return FitnessState(
      currentPlan: currentPlan ?? this.currentPlan,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Fitness notifier
class FitnessNotifier extends StateNotifier<FitnessState> {
  final ApiService _apiService;

  FitnessNotifier(this._apiService) : super(const FitnessState());

  Future<void> loadCurrentPlan() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final plan = await _apiService.getCurrentWorkoutPlan();
      state = state.copyWith(currentPlan: plan, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> generateNewPlan() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final plan = await _apiService.generateWorkoutPlan();
      state = state.copyWith(currentPlan: plan, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> logWorkout({
    required String workoutId,
    required List<Map<String, dynamic>> exercisesCompleted,
    required int duration,
    required String date,
  }) async {
    try {
      await _apiService.logWorkout(
        workoutId: workoutId,
        exercisesCompleted: exercisesCompleted,
        duration: duration,
        date: date,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final fitnessNotifierProvider = StateNotifierProvider<FitnessNotifier, FitnessState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FitnessNotifier(apiService);
});

// API Service Provider (reused from auth_provider)
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});