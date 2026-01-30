import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'cache_service.dart';

final _logger = Logger();
final _uuid = Uuid();

/// Service for managing workout data in local SQLite cache
class WorkoutCacheService {
  static WorkoutCacheService? _instance;
  final CacheService _cache;

  WorkoutCacheService._() : _cache = CacheService.instance;

  static WorkoutCacheService get instance {
    _instance ??= WorkoutCacheService._();
    return _instance!;
  }

  // === Workout Session Methods ===

  /// Save workout session with all sets to local database
  Future<void> saveWorkoutSession({
    required String sessionId,
    required String workoutName,
    String? workoutId,
    required DateTime startedAt,
    DateTime? completedAt,
    required String status,
    required int totalVolume,
    required int durationSeconds,
    String? notes,
    required List<ExerciseSetLocal> sets,
  }) async {
    final db = await _cache.database;

    await db.transaction((txn) async {
      // Insert/update session
      await txn.insert(
        'workout_sessions',
        {
          'id': sessionId,
          'workout_id': workoutId,
          'workout_name': workoutName,
          'started_at': startedAt.toIso8601String(),
          'completed_at': completedAt?.toIso8601String(),
          'status': status,
          'total_volume': totalVolume,
          'duration_seconds': durationSeconds,
          'notes': notes,
          'sync_status': 'pending',
          'sync_attempts': 0,
          'created_locally_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert all sets
      for (final set in sets) {
        await txn.insert(
          'exercise_sets',
          {
            'id': set.id,
            'session_id': sessionId,
            'exercise_id': set.exerciseId,
            'exercise_name': set.exerciseName,
            'set_number': set.setNumber,
            'weight_kg': set.weightKg,
            'reps': set.reps,
            'is_warmup': set.isWarmup ? 1 : 0,
            'rest_seconds': set.restSeconds,
            'completed_at': set.completedAt.toIso8601String(),
            'notes': set.notes,
            'sync_status': 'pending',
            'is_pr': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    _logger.i('Saved workout session $sessionId with ${sets.length} sets to local DB');
  }

  /// Update an existing workout session
  /// Updates workout name, duration, notes, and replaces all exercise sets
  Future<void> updateWorkoutSession({
    required String sessionId,
    required String workoutName,
    required int durationSeconds,
    String? notes,
    required List<ExerciseSetLocal> sets,
  }) async {
    final db = await _cache.database;

    await db.transaction((txn) async {
      // Calculate total volume from new sets
      int totalVolume = 0;
      for (final set in sets) {
        if (!set.isWarmup) {
          totalVolume += (set.weightKg * set.reps).toInt();
        }
      }

      // Update session
      await txn.update(
        'workout_sessions',
        {
          'workout_name': workoutName,
          'duration_seconds': durationSeconds,
          'notes': notes,
          'total_volume': totalVolume,
          'sync_status': 'pending', // Mark as needing sync
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      // Delete all existing sets for this session
      await txn.delete(
        'exercise_sets',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );

      // Insert new sets
      for (final set in sets) {
        await txn.insert(
          'exercise_sets',
          {
            'id': set.id,
            'session_id': sessionId,
            'exercise_id': set.exerciseId,
            'exercise_name': set.exerciseName,
            'set_number': set.setNumber,
            'weight_kg': set.weightKg,
            'reps': set.reps,
            'is_warmup': set.isWarmup ? 1 : 0,
            'rest_seconds': set.restSeconds,
            'completed_at': set.completedAt.toIso8601String(),
            'notes': set.notes,
            'sync_status': 'pending',
            'is_pr': 0, // PRs will be recalculated by backend
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    _logger.i('Updated workout session $sessionId with ${sets.length} sets');
  }

  /// Get a workout session by ID
  Future<WorkoutSessionLocal?> getWorkoutSession(String sessionId) async {
    final db = await _cache.database;
    final results = await db.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (results.isEmpty) return null;
    return WorkoutSessionLocal.fromMap(results.first);
  }

  /// Get all sets for a workout session
  Future<List<ExerciseSetLocal>> getSessionSets(String sessionId) async {
    final db = await _cache.database;
    final results = await db.query(
      'exercise_sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'completed_at ASC',
    );

    return results.map((r) => ExerciseSetLocal.fromMap(r)).toList();
  }

  /// Get workout session summary (for immediate display after finishing)
  Future<Map<String, dynamic>?> getSessionSummary(String sessionId) async {
    final session = await getWorkoutSession(sessionId);
    if (session == null) return null;

    final sets = await getSessionSets(sessionId);

    // Count unique exercises (excluding warmup sets)
    final exercisesCompleted = sets
        .where((s) => !s.isWarmup)
        .map((s) => s.exerciseName)
        .toSet()
        .length;

    return {
      'id': session.id,
      'workout_name': session.workoutName,
      'started_at': session.startedAt.toIso8601String(),
      'completed_at': session.completedAt?.toIso8601String(),
      'duration_seconds': session.durationSeconds,
      'total_volume': session.totalVolume,
      'total_sets': sets.where((s) => !s.isWarmup).length,
      'exercises_completed': exercisesCompleted,
      'new_prs': [], // PRs are determined by backend after sync
    };
  }

  /// Get all pending sessions that need syncing
  Future<List<WorkoutSessionLocal>> getPendingSessions() async {
    final db = await _cache.database;
    final results = await db.query(
      'workout_sessions',
      where: 'sync_status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_locally_at ASC',
    );

    return results.map((r) => WorkoutSessionLocal.fromMap(r)).toList();
  }

  /// Update sync status for a session and all its sets
  Future<void> updateSyncStatus(String sessionId, String syncStatus) async {
    final db = await _cache.database;

    await db.transaction((txn) async {
      await txn.update(
        'workout_sessions',
        {'sync_status': syncStatus, 'last_sync_attempt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      await txn.update(
        'exercise_sets',
        {'sync_status': syncStatus},
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    });

    _logger.d('Updated sync status for session $sessionId to $syncStatus');
  }

  /// Increment sync attempts counter
  Future<void> incrementSyncAttempts(String sessionId) async {
    final db = await _cache.database;
    await db.rawUpdate(
      'UPDATE workout_sessions SET sync_attempts = sync_attempts + 1 WHERE id = ?',
      [sessionId],
    );
  }

  /// Mark sets as PRs after successful sync
  Future<void> markSetsAsPR(List<String> setIds) async {
    if (setIds.isEmpty) return;

    final db = await _cache.database;
    final placeholders = List.filled(setIds.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE exercise_sets SET is_pr = 1 WHERE id IN ($placeholders)',
      setIds,
    );

    _logger.d('Marked ${setIds.length} sets as PRs');
  }

  /// Get workout history (last N days)
  Future<List<WorkoutSessionLocal>> getRecentWorkouts({int days = 30}) async {
    final db = await _cache.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final results = await db.query(
      'workout_sessions',
      where: 'status = ? AND completed_at >= ?',
      whereArgs: ['completed', cutoffDate.toIso8601String()],
      orderBy: 'completed_at DESC',
    );

    return results.map((r) => WorkoutSessionLocal.fromMap(r)).toList();
  }

  /// Get exercise history for a specific exercise
  Future<List<ExerciseSetLocal>> getExerciseHistory(String exerciseName, {int limit = 50}) async {
    final db = await _cache.database;
    final results = await db.rawQuery('''
      SELECT es.* FROM exercise_sets es
      INNER JOIN workout_sessions ws ON es.session_id = ws.id
      WHERE es.exercise_name = ? AND ws.status = 'completed'
      ORDER BY es.completed_at DESC
      LIMIT ?
    ''', [exerciseName, limit]);

    return results.map((r) => ExerciseSetLocal.fromMap(r)).toList();
  }

  /// Count workouts completed on a specific date (for validation)
  Future<int> countWorkoutsForDate(DateTime date) async {
    final db = await _cache.database;

    // Get start and end of day in local time
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM workout_sessions
      WHERE status = 'completed'
      AND completed_at >= ?
      AND completed_at <= ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    return (result.first['count'] as int?) ?? 0;
  }

  /// Get workouts completed on a specific date
  Future<List<WorkoutSessionLocal>> getWorkoutsForDate(DateTime date) async {
    final db = await _cache.database;

    // Get start and end of day in local time
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final results = await db.query(
      'workout_sessions',
      where: 'status = ? AND completed_at >= ? AND completed_at <= ?',
      whereArgs: ['completed', startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'completed_at DESC',
    );

    return results.map((r) => WorkoutSessionLocal.fromMap(r)).toList();
  }

  /// Get exercise summary for a workout session (unique exercises and set counts)
  Future<Map<String, int>> getSessionExerciseSummary(String sessionId) async {
    final db = await _cache.database;

    final results = await db.rawQuery('''
      SELECT exercise_name, COUNT(*) as set_count
      FROM exercise_sets
      WHERE session_id = ? AND is_warmup = 0
      GROUP BY exercise_name
      ORDER BY MIN(set_number)
    ''', [sessionId]);

    return Map.fromEntries(
      results.map((row) => MapEntry(
        row['exercise_name'] as String,
        row['set_count'] as int,
      ))
    );
  }

  /// Delete old synced workouts (keep last N days)
  Future<void> cleanupOldWorkouts({int keepDays = 90}) async {
    final db = await _cache.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

    final deletedCount = await db.delete(
      'workout_sessions',
      where: 'sync_status = ? AND completed_at < ?',
      whereArgs: ['synced', cutoffDate.toIso8601String()],
    );

    _logger.i('Deleted $deletedCount old synced workouts');
  }

  // === Sync Queue Methods ===

  /// Add session to sync queue
  Future<void> queueWorkoutSync(String sessionId, String action) async {
    final db = await _cache.database;

    final session = await getWorkoutSession(sessionId);
    final sets = await getSessionSets(sessionId);

    final payload = {
      'session': session?.toMap(),
      'sets': sets.map((s) => s.toMap()).toList(),
    };

    await db.insert('workout_sync_queue', {
      'session_id': sessionId,
      'action': action,
      'payload': json.encode(payload),
      'attempts': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    _logger.d('Queued workout $sessionId for sync (action: $action)');
  }

  /// Get pending items from sync queue
  Future<List<Map<String, dynamic>>> getPendingSyncQueue() async {
    final db = await _cache.database;
    return db.query(
      'workout_sync_queue',
      where: 'attempts < ?',
      whereArgs: [5], // Max 5 retry attempts
      orderBy: 'created_at ASC',
    );
  }

  /// Remove item from sync queue
  Future<void> removeSyncQueueItem(int queueId) async {
    final db = await _cache.database;
    await db.delete('workout_sync_queue', where: 'id = ?', whereArgs: [queueId]);
  }

  /// Update sync queue item with error
  Future<void> updateSyncQueueError(int queueId, String error) async {
    final db = await _cache.database;
    await db.rawUpdate(
      'UPDATE workout_sync_queue SET attempts = attempts + 1, last_attempt = ?, error_message = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), error, queueId],
    );
  }
}

// === Data Models ===

class WorkoutSessionLocal {
  final String id;
  final String? workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status;
  final int totalVolume;
  final int durationSeconds;
  final String? notes;
  final String syncStatus;
  final int syncAttempts;
  final DateTime? lastSyncAttempt;
  final DateTime createdLocallyAt;

  WorkoutSessionLocal({
    required this.id,
    this.workoutId,
    required this.workoutName,
    required this.startedAt,
    this.completedAt,
    required this.status,
    required this.totalVolume,
    required this.durationSeconds,
    this.notes,
    required this.syncStatus,
    required this.syncAttempts,
    this.lastSyncAttempt,
    required this.createdLocallyAt,
  });

  factory WorkoutSessionLocal.fromMap(Map<String, dynamic> map) {
    return WorkoutSessionLocal(
      id: map['id'] as String,
      workoutId: map['workout_id'] as String?,
      workoutName: map['workout_name'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      status: map['status'] as String,
      totalVolume: map['total_volume'] as int,
      durationSeconds: map['duration_seconds'] as int,
      notes: map['notes'] as String?,
      syncStatus: map['sync_status'] as String,
      syncAttempts: map['sync_attempts'] as int,
      lastSyncAttempt: map['last_sync_attempt'] != null ? DateTime.parse(map['last_sync_attempt'] as String) : null,
      createdLocallyAt: DateTime.parse(map['created_locally_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'workout_name': workoutName,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status,
      'total_volume': totalVolume,
      'duration_seconds': durationSeconds,
      'notes': notes,
      'sync_status': syncStatus,
      'sync_attempts': syncAttempts,
      'last_sync_attempt': lastSyncAttempt?.toIso8601String(),
      'created_locally_at': createdLocallyAt.toIso8601String(),
    };
  }
}

class ExerciseSetLocal {
  final String id;
  final String sessionId;
  final String? exerciseId;
  final String exerciseName;
  final int setNumber;
  final double weightKg;
  final int reps;
  final bool isWarmup;
  final int restSeconds;
  final DateTime completedAt;
  final String? notes;
  final String syncStatus;
  final bool isPR;

  ExerciseSetLocal({
    required this.id,
    required this.sessionId,
    this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.isWarmup,
    required this.restSeconds,
    required this.completedAt,
    this.notes,
    required this.syncStatus,
    required this.isPR,
  });

  factory ExerciseSetLocal.fromMap(Map<String, dynamic> map) {
    return ExerciseSetLocal(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      exerciseId: map['exercise_id'] as String?,
      exerciseName: map['exercise_name'] as String,
      setNumber: map['set_number'] as int,
      weightKg: (map['weight_kg'] as num).toDouble(),
      reps: map['reps'] as int,
      isWarmup: (map['is_warmup'] as int) == 1,
      restSeconds: map['rest_seconds'] as int,
      completedAt: DateTime.parse(map['completed_at'] as String),
      notes: map['notes'] as String?,
      syncStatus: map['sync_status'] as String,
      isPR: (map['is_pr'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'set_number': setNumber,
      'weight_kg': weightKg,
      'reps': reps,
      'is_warmup': isWarmup ? 1 : 0,
      'rest_seconds': restSeconds,
      'completed_at': completedAt.toIso8601String(),
      'notes': notes,
      'sync_status': syncStatus,
      'is_pr': isPR ? 1 : 0,
    };
  }
}
