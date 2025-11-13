import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition.dart';
import '../services/api_service.dart';

// Nutrition state
class NutritionState {
  final NutritionPlan? currentPlan;
  final bool isLoading;
  final String? error;

  const NutritionState({
    this.currentPlan,
    this.isLoading = false,
    this.error,
  });

  NutritionState copyWith({
    NutritionPlan? currentPlan,
    bool? isLoading,
    String? error,
  }) {
    return NutritionState(
      currentPlan: currentPlan ?? this.currentPlan,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Nutrition notifier
class NutritionNotifier extends StateNotifier<NutritionState> {
  final ApiService _apiService;

  NutritionNotifier(this._apiService) : super(const NutritionState());

  Future<void> loadCurrentPlan() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final plan = await _apiService.getCurrentNutritionPlan();
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
      final plan = await _apiService.generateNutritionPlan();
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

  Future<bool> logMeal({
    required String mealType,
    required List<Map<String, dynamic>> foods,
    required String date,
  }) async {
    try {
      await _apiService.logMeal(
        mealType: mealType,
        foods: foods,
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
final nutritionNotifierProvider = StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NutritionNotifier(apiService);
});

// API Service Provider (reused from auth_provider)
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});