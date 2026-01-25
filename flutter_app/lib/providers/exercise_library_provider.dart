import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/exercise_library.dart';
import '../services/local_database.dart';

final _logger = Logger();

/// State for exercise library
class ExerciseLibraryState {
  final List<LibraryExercise> allExercises;
  final List<LibraryExercise> filteredExercises;
  final List<LibraryExercise> customExercises;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? categoryFilter;
  final String? equipmentFilter;
  final String? muscleFilter;
  final String? levelFilter;
  final LibraryExerciseType? typeFilter;

  // Cached unique values for filters
  final List<String> categories;
  final List<String> equipment;
  final List<String> muscles;
  final List<String> levels;

  const ExerciseLibraryState({
    this.allExercises = const [],
    this.filteredExercises = const [],
    this.customExercises = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.categoryFilter,
    this.equipmentFilter,
    this.muscleFilter,
    this.levelFilter,
    this.typeFilter,
    this.categories = const [],
    this.equipment = const [],
    this.muscles = const [],
    this.levels = const [],
  });

  ExerciseLibraryState copyWith({
    List<LibraryExercise>? allExercises,
    List<LibraryExercise>? filteredExercises,
    List<LibraryExercise>? customExercises,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? categoryFilter,
    String? equipmentFilter,
    String? muscleFilter,
    String? levelFilter,
    LibraryExerciseType? typeFilter,
    List<String>? categories,
    List<String>? equipment,
    List<String>? muscles,
    List<String>? levels,
    bool clearCategoryFilter = false,
    bool clearEquipmentFilter = false,
    bool clearMuscleFilter = false,
    bool clearLevelFilter = false,
    bool clearTypeFilter = false,
  }) {
    return ExerciseLibraryState(
      allExercises: allExercises ?? this.allExercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
      customExercises: customExercises ?? this.customExercises,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      equipmentFilter: clearEquipmentFilter ? null : (equipmentFilter ?? this.equipmentFilter),
      muscleFilter: clearMuscleFilter ? null : (muscleFilter ?? this.muscleFilter),
      levelFilter: clearLevelFilter ? null : (levelFilter ?? this.levelFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      categories: categories ?? this.categories,
      equipment: equipment ?? this.equipment,
      muscles: muscles ?? this.muscles,
      levels: levels ?? this.levels,
    );
  }

  bool get hasFilters =>
      categoryFilter != null ||
      equipmentFilter != null ||
      muscleFilter != null ||
      levelFilter != null ||
      typeFilter != null;
}

/// Provider for exercise library
class ExerciseLibraryNotifier extends StateNotifier<ExerciseLibraryState> {
  ExerciseLibraryNotifier() : super(const ExerciseLibraryState()) {
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load JSON from assets
      final jsonString =
          await rootBundle.loadString('assets/data/exercises.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final bundledExercises = jsonList
          .map((json) => LibraryExercise.fromJson(json as Map<String, dynamic>))
          .toList();

      // Load custom exercises from local database
      final customExercises = await LocalDatabase.getCustomExercises();
      _logger.i('Loaded ${customExercises.length} custom exercises');

      // Merge: custom exercises first, then bundled
      final allExercises = [...customExercises, ...bundledExercises];

      // Extract unique values for filters
      final categoriesSet = <String>{};
      final equipmentSet = <String>{};
      final musclesSet = <String>{};
      final levelsSet = <String>{};

      for (final exercise in allExercises) {
        categoriesSet.add(exercise.category.toLowerCase());
        equipmentSet.add(exercise.equipment.toLowerCase());
        levelsSet.add(exercise.level.toLowerCase());

        for (final muscle in exercise.primaryMuscles) {
          musclesSet.add(muscle.toLowerCase());
        }
        if (exercise.secondaryMuscles != null) {
          for (final muscle in exercise.secondaryMuscles!) {
            musclesSet.add(muscle.toLowerCase());
          }
        }
      }

      final categories = categoriesSet.toList()..sort();
      final equipment = equipmentSet.toList()..sort();
      final muscles = musclesSet.toList()..sort();
      final levels = ['beginner', 'intermediate', 'expert'];

      state = state.copyWith(
        allExercises: allExercises,
        filteredExercises: allExercises,
        customExercises: customExercises,
        isLoading: false,
        categories: categories,
        equipment: equipment,
        muscles: muscles,
        levels: levels,
      );

      _logger.i('Loaded ${allExercises.length} total exercises (${customExercises.length} custom)');
    } catch (e, stack) {
      _logger.e('Failed to load exercises: $e', stackTrace: stack);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load exercises: $e',
      );
    }
  }

  /// Search exercises by query
  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Set category filter
  void setCategoryFilter(String? category) {
    state = state.copyWith(
      categoryFilter: category,
      clearCategoryFilter: category == null,
    );
    _applyFilters();
  }

  /// Set equipment filter
  void setEquipmentFilter(String? equipment) {
    state = state.copyWith(
      equipmentFilter: equipment,
      clearEquipmentFilter: equipment == null,
    );
    _applyFilters();
  }

  /// Set muscle filter
  void setMuscleFilter(String? muscle) {
    state = state.copyWith(
      muscleFilter: muscle,
      clearMuscleFilter: muscle == null,
    );
    _applyFilters();
  }

  /// Set level filter
  void setLevelFilter(String? level) {
    state = state.copyWith(
      levelFilter: level,
      clearLevelFilter: level == null,
    );
    _applyFilters();
  }

  /// Set exercise type filter
  void setTypeFilter(LibraryExerciseType? type) {
    state = state.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
    );
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearCategoryFilter: true,
      clearEquipmentFilter: true,
      clearMuscleFilter: true,
      clearLevelFilter: true,
      clearTypeFilter: true,
    );
    _applyFilters();
  }

  /// Add a custom exercise
  Future<void> addCustomExercise(LibraryExercise exercise) async {
    try {
      // Save to local database
      await LocalDatabase.saveCustomExercise(exercise);
      _logger.i('Saved custom exercise: ${exercise.name}');

      // Update state
      final updatedCustom = [exercise, ...state.customExercises];
      final updatedAll = [exercise, ...state.allExercises];

      state = state.copyWith(
        customExercises: updatedCustom,
        allExercises: updatedAll,
      );

      // Re-apply filters to show the new exercise
      _applyFilters();
    } catch (e) {
      _logger.e('Failed to save custom exercise: $e');
      rethrow;
    }
  }

  /// Delete a custom exercise
  Future<void> deleteCustomExercise(String exerciseId) async {
    try {
      await LocalDatabase.deleteCustomExercise(exerciseId);
      _logger.i('Deleted custom exercise: $exerciseId');

      // Update state
      final updatedCustom = state.customExercises
          .where((e) => e.id != exerciseId)
          .toList();
      final updatedAll = state.allExercises
          .where((e) => e.id != exerciseId)
          .toList();

      state = state.copyWith(
        customExercises: updatedCustom,
        allExercises: updatedAll,
      );

      _applyFilters();
    } catch (e) {
      _logger.e('Failed to delete custom exercise: $e');
      rethrow;
    }
  }

  /// Check if an exercise is custom
  bool isCustomExercise(String exerciseId) {
    return state.customExercises.any((e) => e.id == exerciseId);
  }

  /// Reload exercises (useful after adding custom exercises from other screens)
  Future<void> reload() async {
    await _loadExercises();
  }

  void _applyFilters() {
    final filtered = state.allExercises.where((exercise) {
      // Apply search query
      if (!exercise.matchesSearch(state.searchQuery)) {
        return false;
      }

      // Apply filters
      return exercise.matchesFilters(
        categoryFilter: state.categoryFilter,
        equipmentFilter: state.equipmentFilter,
        muscleFilter: state.muscleFilter,
        levelFilter: state.levelFilter,
        typeFilter: state.typeFilter,
      );
    }).toList();

    state = state.copyWith(filteredExercises: filtered);
  }

  /// Get popular exercises (commonly used ones)
  List<LibraryExercise> getPopularExercises({int limit = 20}) {
    final popularIds = [
      'Barbell_Bench_Press_-_Medium_Grip',
      'Barbell_Squat',
      'Barbell_Deadlift',
      'Pull-Up',
      'Push-Up',
      'Dumbbell_Shoulder_Press',
      'Dumbbell_Bicep_Curl',
      'Triceps_Pushdown',
      'Leg_Press',
      'Lat_Pulldown',
      'Dumbbell_Lunges',
      'Plank',
      'Dumbbell_Row',
      'Cable_Fly',
      'Leg_Curl',
      'Calf_Raise',
      'Crunch',
      'Russian_Twist',
      'Dumbbell_Lateral_Raise',
      'Face_Pull',
    ];

    final popular = <LibraryExercise>[];
    for (final id in popularIds) {
      final exercise = state.allExercises.firstWhere(
        (e) => e.id == id,
        orElse: () => state.allExercises.isNotEmpty
            ? state.allExercises.first
            : LibraryExercise(
                id: '',
                name: '',
                level: 'beginner',
                equipment: 'body only',
                category: 'strength',
                primaryMuscles: [],
              ),
      );
      if (exercise.id.isNotEmpty && !popular.contains(exercise)) {
        popular.add(exercise);
      }
      if (popular.length >= limit) break;
    }

    // Fill with other exercises if not enough
    if (popular.length < limit && state.allExercises.isNotEmpty) {
      for (final exercise in state.allExercises) {
        if (!popular.contains(exercise)) {
          popular.add(exercise);
        }
        if (popular.length >= limit) break;
      }
    }

    return popular;
  }

  /// Get exercises by muscle group
  List<LibraryExercise> getExercisesByMuscle(String muscle, {int limit = 50}) {
    return state.allExercises
        .where((e) =>
            e.primaryMuscles
                .any((m) => m.toLowerCase().contains(muscle.toLowerCase())) ||
            (e.secondaryMuscles?.any(
                    (m) => m.toLowerCase().contains(muscle.toLowerCase())) ??
                false))
        .take(limit)
        .toList();
  }

  /// Get exercises by category
  List<LibraryExercise> getExercisesByCategory(String category,
      {int limit = 50}) {
    return state.allExercises
        .where((e) => e.category.toLowerCase() == category.toLowerCase())
        .take(limit)
        .toList();
  }
}

/// Provider instance
final exerciseLibraryProvider =
    StateNotifierProvider<ExerciseLibraryNotifier, ExerciseLibraryState>((ref) {
  return ExerciseLibraryNotifier();
});

/// Provider for popular exercises
final popularExercisesProvider = Provider<List<LibraryExercise>>((ref) {
  final libraryNotifier = ref.watch(exerciseLibraryProvider.notifier);
  return libraryNotifier.getPopularExercises();
});
