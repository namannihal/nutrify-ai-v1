import 'package:json_annotation/json_annotation.dart';

part 'fitness.g.dart';

@JsonSerializable()
class WorkoutPlan {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'week_start')
  final String weekStart;
  @JsonKey(name: 'difficulty_level')
  final int? difficultyLevel;
  @JsonKey(name: 'focus_areas')
  final List<String>? focusAreas;
  @JsonKey(name: 'estimated_calories_burn')
  final int? estimatedCaloriesBurn;
  final List<DailyWorkout> workouts;
  @JsonKey(name: 'created_by_ai')
  final bool createdByAi;
  @JsonKey(name: 'adaptation_reason')
  final String? adaptationReason;

  WorkoutPlan({
    required this.id,
    required this.userId,
    required this.weekStart,
    this.difficultyLevel,
    this.focusAreas,
    this.estimatedCaloriesBurn,
    required this.workouts,
    required this.createdByAi,
    this.adaptationReason,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => _$WorkoutPlanFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutPlanToJson(this);
}

@JsonSerializable()
class DailyWorkout {
  final String day;
  final List<Workout> workouts;

  DailyWorkout({
    required this.day,
    required this.workouts,
  });

  factory DailyWorkout.fromJson(Map<String, dynamic> json) => _$DailyWorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$DailyWorkoutToJson(this);
}

@JsonSerializable()
class Workout {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'estimated_calories')
  final int? estimatedCalories;
  @JsonKey(name: 'intensity_level')
  final int? intensityLevel;
  final List<Exercise> exercises;

  Workout({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    this.estimatedCalories,
    this.intensityLevel,
    required this.exercises,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => _$WorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutToJson(this);
}

@JsonSerializable()
class Exercise {
  final String id;
  final String name;
  final String? description;
  final int? sets;
  final int? reps;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  @JsonKey(name: 'rest_time_seconds')
  final int? restTimeSeconds;
  @JsonKey(name: 'muscle_groups')
  final List<String>? muscleGroups;
  @JsonKey(name: 'equipment_required')
  final List<String>? equipmentRequired;
  final String? instructions;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'form_cues')
  final List<String>? formCues;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.restTimeSeconds,
    this.muscleGroups,
    this.equipmentRequired,
    this.instructions,
    this.videoUrl,
    this.formCues,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);
}