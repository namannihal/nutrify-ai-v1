// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) =>
    WorkoutSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutId: json['workout_id'] as String?,
      workoutName: json['workout_name'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      status: json['status'] as String,
      totalVolume: json['total_volume'] == null
          ? 0
          : _parseInt(json['total_volume']),
      durationSeconds: json['duration_seconds'] == null
          ? 0
          : _parseInt(json['duration_seconds']),
      notes: json['notes'] as String?,
      sets:
          (json['sets'] as List<dynamic>?)
              ?.map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkoutSessionToJson(WorkoutSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'workout_id': instance.workoutId,
      'workout_name': instance.workoutName,
      'started_at': instance.startedAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'status': instance.status,
      'total_volume': instance.totalVolume,
      'duration_seconds': instance.durationSeconds,
      'notes': instance.notes,
      'sets': instance.sets,
    };

ExerciseSet _$ExerciseSetFromJson(Map<String, dynamic> json) => ExerciseSet(
  id: json['id'] as String,
  sessionId: json['session_id'] as String,
  exerciseId: json['exercise_id'] as String?,
  exerciseName: json['exercise_name'] as String,
  setNumber: _parseInt(json['set_number']),
  weightKg: _parseDouble(json['weight_kg']),
  reps: _parseInt(json['reps']),
  isWarmup: json['is_warmup'] as bool? ?? false,
  isPR: json['is_pr'] as bool? ?? false,
  restSeconds: json['rest_seconds'] == null
      ? 0
      : _parseInt(json['rest_seconds']),
  completedAt: DateTime.parse(json['completed_at'] as String),
  notes: json['notes'] as String?,
  durationSeconds: _parseInt(json['duration_seconds']),
  distanceMeters: _parseDouble(json['distance_meters']),
);

Map<String, dynamic> _$ExerciseSetToJson(ExerciseSet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'exercise_id': instance.exerciseId,
      'exercise_name': instance.exerciseName,
      'set_number': instance.setNumber,
      'weight_kg': instance.weightKg,
      'reps': instance.reps,
      'is_warmup': instance.isWarmup,
      'is_pr': instance.isPR,
      'rest_seconds': instance.restSeconds,
      'completed_at': instance.completedAt.toIso8601String(),
      'notes': instance.notes,
      'duration_seconds': instance.durationSeconds,
      'distance_meters': instance.distanceMeters,
    };

WorkoutSessionSummary _$WorkoutSessionSummaryFromJson(
  Map<String, dynamic> json,
) => WorkoutSessionSummary(
  id: json['id'] as String,
  workoutName: json['workout_name'] as String,
  startedAt: DateTime.parse(json['started_at'] as String),
  completedAt: DateTime.parse(json['completed_at'] as String),
  durationSeconds: _parseInt(json['duration_seconds']),
  totalVolume: _parseInt(json['total_volume']),
  totalSets: _parseInt(json['total_sets']),
  exercisesCompleted: _parseInt(json['exercises_completed']),
  newPRs:
      (json['new_prs'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
);

Map<String, dynamic> _$WorkoutSessionSummaryToJson(
  WorkoutSessionSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'workout_name': instance.workoutName,
  'started_at': instance.startedAt.toIso8601String(),
  'completed_at': instance.completedAt.toIso8601String(),
  'duration_seconds': instance.durationSeconds,
  'total_volume': instance.totalVolume,
  'total_sets': instance.totalSets,
  'exercises_completed': instance.exercisesCompleted,
  'new_prs': instance.newPRs,
};

PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) =>
    PersonalRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseName: json['exercise_name'] as String,
      recordType: json['record_type'] as String,
      value: _parseDouble(json['value']),
      weightKg: _parseDouble(json['weight_kg']),
      reps: _parseInt(json['reps']),
      achievedAt: DateTime.parse(json['achieved_at'] as String),
      sessionId: json['session_id'] as String?,
    );

Map<String, dynamic> _$PersonalRecordToJson(PersonalRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'exercise_name': instance.exerciseName,
      'record_type': instance.recordType,
      'value': instance.value,
      'weight_kg': instance.weightKg,
      'reps': instance.reps,
      'achieved_at': instance.achievedAt.toIso8601String(),
      'session_id': instance.sessionId,
    };

ExerciseHistoryEntry _$ExerciseHistoryEntryFromJson(
  Map<String, dynamic> json,
) => ExerciseHistoryEntry(
  date: DateTime.parse(json['date'] as String),
  weightKg: _parseDouble(json['weight_kg']),
  reps: _parseInt(json['reps']),
  isPR: json['is_pr'] as bool? ?? false,
);

Map<String, dynamic> _$ExerciseHistoryEntryToJson(
  ExerciseHistoryEntry instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'weight_kg': instance.weightKg,
  'reps': instance.reps,
  'is_pr': instance.isPR,
};

ExerciseHistory _$ExerciseHistoryFromJson(Map<String, dynamic> json) =>
    ExerciseHistory(
      exerciseName: json['exercise_name'] as String,
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map(
                (e) => ExerciseHistoryEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      bestWeight: _parseDouble(json['best_weight']),
      bestVolume: _parseDouble(json['best_volume']),
    );

Map<String, dynamic> _$ExerciseHistoryToJson(ExerciseHistory instance) =>
    <String, dynamic>{
      'exercise_name': instance.exerciseName,
      'entries': instance.entries,
      'best_weight': instance.bestWeight,
      'best_volume': instance.bestVolume,
    };
