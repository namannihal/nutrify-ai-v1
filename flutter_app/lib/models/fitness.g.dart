// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutPlan _$WorkoutPlanFromJson(Map<String, dynamic> json) => WorkoutPlan(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  weekStart: json['week_start'] as String,
  difficultyLevel: (json['difficulty_level'] as num?)?.toInt(),
  focusAreas: (json['focus_areas'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  estimatedCaloriesBurn: (json['estimated_calories_burn'] as num?)?.toInt(),
  workouts: (json['workouts'] as List<dynamic>)
      .map((e) => DailyWorkout.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdByAi: json['created_by_ai'] as bool,
  adaptationReason: json['adaptation_reason'] as String?,
);

Map<String, dynamic> _$WorkoutPlanToJson(WorkoutPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'week_start': instance.weekStart,
      'difficulty_level': instance.difficultyLevel,
      'focus_areas': instance.focusAreas,
      'estimated_calories_burn': instance.estimatedCaloriesBurn,
      'workouts': instance.workouts,
      'created_by_ai': instance.createdByAi,
      'adaptation_reason': instance.adaptationReason,
    };

DailyWorkout _$DailyWorkoutFromJson(Map<String, dynamic> json) => DailyWorkout(
  day: json['day'] as String,
  workouts: (json['workouts'] as List<dynamic>)
      .map((e) => Workout.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DailyWorkoutToJson(DailyWorkout instance) =>
    <String, dynamic>{'day': instance.day, 'workouts': instance.workouts};

Workout _$WorkoutFromJson(Map<String, dynamic> json) => Workout(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  estimatedCalories: (json['estimated_calories'] as num?)?.toInt(),
  intensityLevel: (json['intensity_level'] as num?)?.toInt(),
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WorkoutToJson(Workout instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'duration_minutes': instance.durationMinutes,
  'estimated_calories': instance.estimatedCalories,
  'intensity_level': instance.intensityLevel,
  'exercises': instance.exercises,
};

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  sets: (json['sets'] as num?)?.toInt(),
  reps: (json['reps'] as num?)?.toInt(),
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  restTimeSeconds: (json['rest_time_seconds'] as num?)?.toInt(),
  muscleGroups: (json['muscle_groups'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  equipmentRequired: (json['equipment_required'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  instructions: json['instructions'] as String?,
  videoUrl: json['video_url'] as String?,
  formCues: (json['form_cues'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'sets': instance.sets,
  'reps': instance.reps,
  'duration_seconds': instance.durationSeconds,
  'rest_time_seconds': instance.restTimeSeconds,
  'muscle_groups': instance.muscleGroups,
  'equipment_required': instance.equipmentRequired,
  'instructions': instance.instructions,
  'video_url': instance.videoUrl,
  'form_cues': instance.formCues,
};
