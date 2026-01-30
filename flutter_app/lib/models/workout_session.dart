import 'package:json_annotation/json_annotation.dart';

part 'workout_session.g.dart';

/// Exercise type enum for different tracking modes
enum ExerciseType {
  weighted,    // Reps × Weight (Bench Press, Squats)
  bodyweight,  // Reps only (Push-ups, Pull-ups)
  duration,    // Time (Plank, Wall Sit)
  cardio,      // Distance/Time (Running, Cycling)
}

/// Helper to parse numbers that might come as strings from backend
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class WorkoutSession {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'workout_name')
  final String workoutName;
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  final String status;
  @JsonKey(name: 'total_volume', fromJson: _parseInt)
  final int totalVolume;
  @JsonKey(name: 'duration_seconds', fromJson: _parseInt)
  final int durationSeconds;
  final String? notes;
  final List<ExerciseSet> sets;

  WorkoutSession({
    required this.id,
    required this.userId,
    this.workoutId,
    required this.workoutName,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.totalVolume = 0,
    this.durationSeconds = 0,
    this.notes,
    this.sets = const [],
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutSessionToJson(this);

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  Duration get duration => Duration(seconds: durationSeconds);

  int get totalSets => sets.where((s) => !s.isWarmup).length;
  int get exercisesCompleted =>
      sets.where((s) => !s.isWarmup).map((s) => s.exerciseName).toSet().length;
}

@JsonSerializable()
class ExerciseSet {
  final String id;
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'exercise_id')
  final String? exerciseId;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'set_number', fromJson: _parseInt)
  final int setNumber;
  @JsonKey(name: 'weight_kg', fromJson: _parseDouble)
  final double weightKg;
  @JsonKey(fromJson: _parseInt)
  final int reps;
  @JsonKey(name: 'is_warmup')
  final bool isWarmup;
  @JsonKey(name: 'is_pr')
  final bool isPR;
  @JsonKey(name: 'rest_seconds', fromJson: _parseInt)
  final int restSeconds;
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;
  final String? notes;
  // Duration in seconds for timed exercises
  @JsonKey(name: 'duration_seconds', fromJson: _parseInt)
  final int? durationSeconds;
  // Distance in meters for cardio
  @JsonKey(name: 'distance_meters', fromJson: _parseDouble)
  final double? distanceMeters;

  ExerciseSet({
    required this.id,
    required this.sessionId,
    this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.isWarmup = false,
    this.isPR = false,
    this.restSeconds = 0,
    required this.completedAt,
    this.notes,
    this.durationSeconds,
    this.distanceMeters,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSetFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSetToJson(this);

  int get volume => (weightKg * reps).round();
}

@JsonSerializable()
class WorkoutSessionSummary {
  final String id;
  @JsonKey(name: 'workout_name')
  final String workoutName;
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;
  @JsonKey(name: 'duration_seconds', fromJson: _parseInt)
  final int durationSeconds;
  @JsonKey(name: 'total_volume', fromJson: _parseInt)
  final int totalVolume;
  @JsonKey(name: 'total_sets', fromJson: _parseInt)
  final int totalSets;
  @JsonKey(name: 'exercises_completed', fromJson: _parseInt)
  final int exercisesCompleted;
  @JsonKey(name: 'new_prs')
  final List<Map<String, dynamic>> newPRs;

  WorkoutSessionSummary({
    required this.id,
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
    required this.totalVolume,
    required this.totalSets,
    required this.exercisesCompleted,
    this.newPRs = const [],
  });

  factory WorkoutSessionSummary.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutSessionSummaryToJson(this);

  Duration get duration => Duration(seconds: durationSeconds);
}

@JsonSerializable()
class PersonalRecord {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'record_type')
  final String recordType;
  @JsonKey(fromJson: _parseDouble)
  final double value;
  @JsonKey(name: 'weight_kg', fromJson: _parseDouble)
  final double? weightKg;
  @JsonKey(fromJson: _parseInt)
  final int? reps;
  @JsonKey(name: 'achieved_at')
  final DateTime achievedAt;
  @JsonKey(name: 'session_id')
  final String? sessionId;

  PersonalRecord({
    required this.id,
    required this.userId,
    required this.exerciseName,
    required this.recordType,
    required this.value,
    this.weightKg,
    this.reps,
    required this.achievedAt,
    this.sessionId,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalRecordToJson(this);
}

@JsonSerializable()
class ExerciseHistoryEntry {
  final DateTime date;
  @JsonKey(name: 'weight_kg', fromJson: _parseDouble)
  final double weightKg;
  @JsonKey(fromJson: _parseInt)
  final int reps;
  @JsonKey(name: 'is_pr')
  final bool isPR;

  ExerciseHistoryEntry({
    required this.date,
    required this.weightKg,
    required this.reps,
    this.isPR = false,
  });

  factory ExerciseHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$ExerciseHistoryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseHistoryEntryToJson(this);
}

@JsonSerializable()
class ExerciseHistory {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  final List<ExerciseHistoryEntry> entries;
  @JsonKey(name: 'best_weight', fromJson: _parseDouble)
  final double? bestWeight;
  @JsonKey(name: 'best_volume', fromJson: _parseDouble)
  final double? bestVolume;

  ExerciseHistory({
    required this.exerciseName,
    this.entries = const [],
    this.bestWeight,
    this.bestVolume,
  });

  factory ExerciseHistory.fromJson(Map<String, dynamic> json) =>
      _$ExerciseHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseHistoryToJson(this);
}

/// Local model for tracking exercise progress during an active workout
class ActiveExerciseProgress {
  final String exerciseId;
  final String name;
  final ExerciseType exerciseType;
  final int targetSets;
  final int? targetReps;
  final int? targetDurationSeconds; // For duration-based exercises
  final int? restSeconds;
  final List<CompletedSetLocal> completedSets;
  final List<ExerciseHistoryEntry>? previousSession;

  ActiveExerciseProgress({
    required this.exerciseId,
    required this.name,
    this.exerciseType = ExerciseType.weighted,
    required this.targetSets,
    this.targetReps,
    this.targetDurationSeconds,
    this.restSeconds,
    this.completedSets = const [],
    this.previousSession,
  });

  ActiveExerciseProgress copyWith({
    String? exerciseId,
    String? name,
    ExerciseType? exerciseType,
    int? targetSets,
    int? targetReps,
    int? targetDurationSeconds,
    int? restSeconds,
    List<CompletedSetLocal>? completedSets,
    List<ExerciseHistoryEntry>? previousSession,
  }) {
    return ActiveExerciseProgress(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      exerciseType: exerciseType ?? this.exerciseType,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetDurationSeconds: targetDurationSeconds ?? this.targetDurationSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      completedSets: completedSets ?? this.completedSets,
      previousSession: previousSession ?? this.previousSession,
    );
  }

  int get remainingSets => targetSets - completedSets.length;
  bool get isComplete => completedSets.length >= targetSets;

  /// Check if this is a bodyweight exercise (no weight needed)
  bool get isBodyweight => exerciseType == ExerciseType.bodyweight;

  /// Check if this is a timed exercise
  bool get isTimed => exerciseType == ExerciseType.duration;

  /// Check if this is a cardio exercise
  bool get isCardio => exerciseType == ExerciseType.cardio;
}

/// Local model for a completed set (before syncing with backend)
class CompletedSetLocal {
  final String? id; // Unique ID for the set (for edit mode)
  final int setNumber;
  final double weightKg;
  final int reps;
  final int? durationSeconds; // For timed exercises
  final double? distanceMeters; // For cardio
  final bool isWarmup;
  final bool isPR;
  final String? backendId; // Set after syncing with backend
  final DateTime? completedAt; // When the set was completed

  CompletedSetLocal({
    this.id,
    required this.setNumber,
    this.weightKg = 0,
    this.reps = 0,
    this.durationSeconds,
    this.distanceMeters,
    this.isWarmup = false,
    this.isPR = false,
    this.backendId,
    this.completedAt,
  });

  CompletedSetLocal copyWith({
    String? id,
    int? setNumber,
    double? weightKg,
    int? reps,
    int? durationSeconds,
    double? distanceMeters,
    bool? isWarmup,
    bool? isPR,
    String? backendId,
    DateTime? completedAt,
  }) {
    return CompletedSetLocal(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isWarmup: isWarmup ?? this.isWarmup,
      isPR: isPR ?? this.isPR,
      backendId: backendId ?? this.backendId,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  int get volume => (weightKg * reps).round();

  /// Format display string based on what data is available
  String get displayString {
    if (durationSeconds != null && durationSeconds! > 0) {
      final mins = durationSeconds! ~/ 60;
      final secs = durationSeconds! % 60;
      return mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
    }
    if (distanceMeters != null && distanceMeters! > 0) {
      if (distanceMeters! >= 1000) {
        return '${(distanceMeters! / 1000).toStringAsFixed(2)} km';
      }
      return '${distanceMeters!.round()} m';
    }
    if (weightKg > 0) {
      return '${weightKg} kg × $reps';
    }
    return '$reps reps';
  }
}
