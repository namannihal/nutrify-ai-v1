import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'local_database.dart';
import 'api_service.dart';
import 'workout_cache_service.dart';
import '../models/nutrition.dart';
import '../models/fitness.dart';

final _logger = Logger();

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  final WorkoutCacheService _workoutCache = WorkoutCacheService.instance;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  SyncStatus _workoutSyncStatus = SyncStatus.idle;
  SyncStatus get workoutSyncStatus => _workoutSyncStatus;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  final _workoutSyncController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get workoutSyncStream => _workoutSyncController.stream;

  Timer? _periodicSyncTimer;

  /// Initialize the sync service and start periodic syncing
  void initialize({Duration syncInterval = const Duration(hours: 1)}) {
    _logger.d('Initializing SyncService with interval: $syncInterval');

    // Cancel any existing timer
    _periodicSyncTimer?.cancel();

    // Start periodic sync
    _periodicSyncTimer = Timer.periodic(syncInterval, (_) {
      syncAll();
    });

    // Do an initial sync
    syncAll();
  }

  /// Stop the sync service
  void dispose() {
    _periodicSyncTimer?.cancel();
    _statusController.close();
    _workoutSyncController.close();
  }

  /// Sync all data (nutrition, fitness plans, and workouts)
  Future<bool> syncAll() async {
    if (_status == SyncStatus.syncing) {
      _logger.d('Sync already in progress, skipping');
      return false;
    }

    _setStatus(SyncStatus.syncing);

    try {
      // Process any pending sync queue items first
      await _processSyncQueue();

      // Sync workouts first (most important for user data)
      await syncPendingWorkouts();

      // Then fetch latest from server
      await syncNutritionPlan();
      await syncFitnessPlan();

      _lastSyncTime = DateTime.now();
      _setStatus(SyncStatus.completed);
      _logger.d('Sync completed successfully at $_lastSyncTime');
      return true;
    } catch (e) {
      _logger.e('Sync failed: $e');
      _setStatus(SyncStatus.failed);
      return false;
    }
  }

  /// Sync nutrition plan from server to local
  Future<void> syncNutritionPlan() async {
    try {
      final plan = await _apiService.getCurrentNutritionPlan();
      if (plan != null) {
        await LocalDatabase.saveNutritionPlan(plan, plan.userId);
        _logger.d('Synced nutrition plan from server');
      }
    } catch (e) {
      // 404 is expected if no plan exists
      if (!e.toString().contains('404')) {
        _logger.e('Failed to sync nutrition plan: $e');
        rethrow;
      }
    }
  }

  /// Sync fitness plan from server to local
  Future<void> syncFitnessPlan() async {
    try {
      final plan = await _apiService.getCurrentFitnessPlan();
      if (plan != null) {
        await LocalDatabase.saveFitnessPlan(plan, plan.userId);
        _logger.d('Synced fitness plan from server');
      }
    } catch (e) {
      // 404 is expected if no plan exists
      if (!e.toString().contains('404')) {
        _logger.e('Failed to sync fitness plan: $e');
        rethrow;
      }
    }
  }

  /// Process pending items in the sync queue
  Future<void> _processSyncQueue() async {
    final pendingItems = await LocalDatabase.getPendingSyncItems();

    for (final item in pendingItems) {
      try {
        final tableName = item['table_name'] as String;
        final action = item['action'] as String;
        final id = item['id'] as int;

        _logger.d('Processing sync queue item: $tableName - $action');

        // For now, we use server-wins strategy, so we just clear the queue
        // In the future, we could implement proper conflict resolution here
        await LocalDatabase.removeSyncQueueItem(id);
      } catch (e) {
        _logger.e('Failed to process sync queue item: $e');
      }
    }
  }

  /// Save nutrition plan locally and mark for sync
  Future<void> saveNutritionPlanLocally(NutritionPlan plan, String userId) async {
    await LocalDatabase.saveNutritionPlan(plan, userId);
  }

  /// Save fitness plan locally and mark for sync
  Future<void> saveFitnessPlanLocally(WorkoutPlan plan, String userId) async {
    await LocalDatabase.saveFitnessPlan(plan, userId);
  }

  /// Get nutrition plan (local first, then server)
  Future<NutritionPlan?> getNutritionPlan(String userId, {bool forceServer = false}) async {
    // Try local first (unless forced to use server)
    if (!forceServer) {
      final localPlan = await LocalDatabase.getNutritionPlan(userId);
      if (localPlan != null) {
        _logger.d('Returning nutrition plan from local storage');

        // Trigger background sync
        _syncInBackground(() => syncNutritionPlan());

        return localPlan;
      }
    }

    // Fetch from server
    try {
      final plan = await _apiService.getCurrentNutritionPlan();
      if (plan != null) {
        await LocalDatabase.saveNutritionPlan(plan, userId);
      }
      return plan;
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  /// Get fitness plan (local first, then server)
  Future<WorkoutPlan?> getFitnessPlan(String userId, {bool forceServer = false}) async {
    // Try local first (unless forced to use server)
    if (!forceServer) {
      final localPlan = await LocalDatabase.getFitnessPlan(userId);
      if (localPlan != null) {
        _logger.d('Returning fitness plan from local storage');

        // Trigger background sync
        _syncInBackground(() => syncFitnessPlan());

        return localPlan;
      }
    }

    // Fetch from server
    try {
      final plan = await _apiService.getCurrentFitnessPlan();
      if (plan != null) {
        await LocalDatabase.saveFitnessPlan(plan, userId);
      }
      return plan;
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  /// Run a sync function in the background without blocking
  void _syncInBackground(Future<void> Function() syncFn) {
    Future.microtask(() async {
      try {
        await syncFn();
      } catch (e) {
        _logger.e('Background sync failed: $e');
      }
    });
  }

  void _setStatus(SyncStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// Check if there are pending workouts that need syncing
  Future<bool> hasPendingWorkouts() async {
    final pendingSessions = await _workoutCache.getPendingSessions();
    return pendingSessions.isNotEmpty;
  }

  /// Sync pending workouts before logout (blocking)
  Future<bool> syncBeforeLogout() async {
    _logger.i('Syncing pending workouts before logout');

    final pendingSessions = await _workoutCache.getPendingSessions();
    if (pendingSessions.isEmpty) {
      return true; // Nothing to sync
    }

    // Try to sync with a timeout
    try {
      await syncPendingWorkouts();
      return _workoutSyncStatus == SyncStatus.completed;
    } catch (e) {
      _logger.e('Failed to sync before logout: $e');
      return false;
    }
  }

  /// Clear all local data (for logout)
  Future<void> clearLocalData(String userId) async {
    await LocalDatabase.clearUserData(userId);
    _logger.d('Cleared local data for user $userId');
  }

  // === Workout Sync Methods ===

  /// Sync all pending workouts to backend
  Future<void> syncPendingWorkouts() async {
    if (_workoutSyncStatus == SyncStatus.syncing) {
      _logger.d('Workout sync already in progress, skipping');
      return;
    }

    _setWorkoutSyncStatus(SyncStatus.syncing);

    try {
      final pendingSessions = await _workoutCache.getPendingSessions();

      if (pendingSessions.isEmpty) {
        _logger.d('No pending workouts to sync');
        _setWorkoutSyncStatus(SyncStatus.completed);
        return;
      }

      _logger.i('Syncing ${pendingSessions.length} pending workouts');

      for (final session in pendingSessions) {
        await _syncWorkoutSession(session);
      }

      _setWorkoutSyncStatus(SyncStatus.completed);
      _logger.i('Successfully synced ${pendingSessions.length} workouts');
    } catch (e) {
      _logger.e('Workout sync failed: $e');
      _setWorkoutSyncStatus(SyncStatus.failed);
    }
  }

  /// Sync a single workout session to backend
  Future<void> _syncWorkoutSession(WorkoutSessionLocal session) async {
    try {
      _logger.d('Syncing workout session ${session.id}');

      // Update status to syncing
      await _workoutCache.updateSyncStatus(session.id, 'syncing');

      // Get all sets for this session
      final sets = await _workoutCache.getSessionSets(session.id);

      // Call backend batch sync endpoint
      final response = await _apiService.batchSyncWorkout(
        sessionId: session.id,
        workoutId: session.workoutId,
        workoutName: session.workoutName,
        startedAt: session.startedAt,
        completedAt: session.completedAt,
        status: session.status,
        totalVolume: session.totalVolume,
        durationSeconds: session.durationSeconds,
        notes: session.notes,
        sets: sets.map((s) => {
          'id': s.id,
          'exercise_id': s.exerciseId,
          'exercise_name': s.exerciseName,
          'set_number': s.setNumber,
          'weight_kg': s.weightKg,
          'reps': s.reps,
          'is_warmup': s.isWarmup,
          'rest_seconds': s.restSeconds,
          'completed_at': s.completedAt.toIso8601String(),
          'notes': s.notes,
        }).toList(),
      );

      // Mark PRs if backend detected any
      if (response['prs'] != null && (response['prs'] as List).isNotEmpty) {
        final prSetIds = (response['prs'] as List)
            .map((pr) => pr['set_id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toList();

        if (prSetIds.isNotEmpty) {
          await _workoutCache.markSetsAsPR(prSetIds);
        }
      }

      // Mark as synced
      await _workoutCache.updateSyncStatus(session.id, 'synced');
      _logger.i('Successfully synced workout ${session.id}');
    } catch (e) {
      _logger.e('Failed to sync workout ${session.id}: $e');

      // Mark as failed and increment attempts
      await _workoutCache.updateSyncStatus(session.id, 'failed');
      await _workoutCache.incrementSyncAttempts(session.id);

      // Don't rethrow - continue with other workouts
    }
  }

  /// Queue a workout for background sync
  Future<void> queueWorkoutSync(String sessionId) async {
    _logger.d('Queueing workout $sessionId for background sync');

    // Trigger sync in background
    _syncInBackground(() => syncPendingWorkouts());
  }

  /// Force sync now (for manual retry)
  Future<bool> syncWorkoutsNow() async {
    _logger.i('Manual workout sync triggered');
    await syncPendingWorkouts();
    return _workoutSyncStatus == SyncStatus.completed;
  }

  void _setWorkoutSyncStatus(SyncStatus newStatus) {
    _workoutSyncStatus = newStatus;
    _workoutSyncController.add(newStatus);
  }
}

/// Global sync service instance
final syncService = SyncService();
