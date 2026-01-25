/// Local exercise library model
/// Data loaded from bundled assets/data/exercises.json

import 'package:json_annotation/json_annotation.dart';
import 'workout_session.dart';

part 'exercise_library.g.dart';

/// Exercise type for tracking purposes
enum LibraryExerciseType {
  weighted,   // Reps × Weight (Bench Press, Squats)
  bodyweight, // Reps only (Push-ups, Pull-ups)
  duration,   // Time (Plank, Wall Sit)
  cardio,     // Distance/Time (Running, Cycling)
}

@JsonSerializable()
class LibraryExercise {
  final String id;
  final String name;
  final String? force;
  @JsonKey(defaultValue: 'beginner')
  final String level;
  final String? mechanic;
  @JsonKey(defaultValue: 'body only')
  final String equipment;
  @JsonKey(defaultValue: 'strength')
  final String category;

  @JsonKey(name: 'primaryMuscles', defaultValue: <String>[])
  final List<String> primaryMuscles;

  @JsonKey(name: 'secondaryMuscles')
  final List<String>? secondaryMuscles;

  final List<String>? instructions;
  final List<String>? images;

  LibraryExercise({
    required this.id,
    required this.name,
    this.force,
    required this.level,
    this.mechanic,
    required this.equipment,
    required this.category,
    required this.primaryMuscles,
    this.secondaryMuscles,
    this.instructions,
    this.images,
  });

  factory LibraryExercise.fromJson(Map<String, dynamic> json) =>
      _$LibraryExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryExerciseToJson(this);

  /// Determine exercise type based on category and equipment
  LibraryExerciseType get exerciseType {
    final cat = category.toLowerCase();
    final equip = equipment.toLowerCase();
    final nameLower = name.toLowerCase();

    // Cardio exercises
    if (cat == 'cardio' ||
        nameLower.contains('run') ||
        nameLower.contains('jog') ||
        nameLower.contains('sprint') ||
        nameLower.contains('cycle') ||
        nameLower.contains('bike') ||
        nameLower.contains('row')) {
      return LibraryExerciseType.cardio;
    }

    // Duration/timed exercises
    if (cat == 'stretching' ||
        nameLower.contains('plank') ||
        nameLower.contains('hold') ||
        nameLower.contains('stretch') ||
        nameLower.contains('hang') ||
        nameLower.contains('wall sit')) {
      return LibraryExerciseType.duration;
    }

    // Bodyweight exercises (no equipment, reps-based)
    if (equip == 'body only' && cat != 'stretching') {
      return LibraryExerciseType.bodyweight;
    }

    // Default to weighted
    return LibraryExerciseType.weighted;
  }

  /// Convert to ExerciseType used in workout session
  ExerciseType get workoutExerciseType {
    switch (exerciseType) {
      case LibraryExerciseType.weighted:
        return ExerciseType.weighted;
      case LibraryExerciseType.bodyweight:
        return ExerciseType.bodyweight;
      case LibraryExerciseType.duration:
        return ExerciseType.duration;
      case LibraryExerciseType.cardio:
        return ExerciseType.cardio;
    }
  }

  /// Get formatted muscle groups string
  String get muscleGroupsDisplay {
    final muscles = [...primaryMuscles];
    if (secondaryMuscles != null && secondaryMuscles!.isNotEmpty) {
      muscles.addAll(secondaryMuscles!);
    }
    return muscles.map((m) => _formatMuscle(m)).join(', ');
  }

  /// Get primary muscles formatted
  String get primaryMusclesDisplay {
    return primaryMuscles.map((m) => _formatMuscle(m)).join(', ');
  }

  String _formatMuscle(String muscle) {
    return muscle
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Get equipment formatted
  String get equipmentDisplay {
    if (equipment.isEmpty || equipment.toLowerCase() == 'body only') {
      return 'No Equipment';
    }
    return equipment
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Get level formatted
  String get levelDisplay {
    return '${level[0].toUpperCase()}${level.substring(1)}';
  }

  /// Get category formatted
  String get categoryDisplay {
    return '${category[0].toUpperCase()}${category.substring(1)}';
  }

  /// Check if exercise matches search query
  bool matchesSearch(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;

    // Search in name
    if (name.toLowerCase().contains(q)) return true;

    // Search in category
    if (category.toLowerCase().contains(q)) return true;

    // Search in equipment
    if (equipment.toLowerCase().contains(q)) return true;

    // Search in muscles
    for (final muscle in primaryMuscles) {
      if (muscle.toLowerCase().contains(q)) return true;
    }
    if (secondaryMuscles != null) {
      for (final muscle in secondaryMuscles!) {
        if (muscle.toLowerCase().contains(q)) return true;
      }
    }

    return false;
  }

  /// Check if exercise matches filters
  bool matchesFilters({
    String? categoryFilter,
    String? equipmentFilter,
    String? muscleFilter,
    String? levelFilter,
    LibraryExerciseType? typeFilter,
  }) {
    if (categoryFilter != null &&
        category.toLowerCase() != categoryFilter.toLowerCase()) {
      return false;
    }

    if (equipmentFilter != null &&
        !equipment.toLowerCase().contains(equipmentFilter.toLowerCase())) {
      return false;
    }

    if (muscleFilter != null) {
      final muscleLower = muscleFilter.toLowerCase();
      final hasMuscle = primaryMuscles.any((m) => m.toLowerCase().contains(muscleLower)) ||
          (secondaryMuscles?.any((m) => m.toLowerCase().contains(muscleLower)) ?? false);
      if (!hasMuscle) return false;
    }

    if (levelFilter != null &&
        level.toLowerCase() != levelFilter.toLowerCase()) {
      return false;
    }

    if (typeFilter != null && exerciseType != typeFilter) {
      return false;
    }

    return true;
  }
}
