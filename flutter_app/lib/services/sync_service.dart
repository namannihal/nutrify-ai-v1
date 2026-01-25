import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'local_database.dart';
import 'api_service.dart';
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

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  Timer? _periodicSyncTimer;

  /// Initialize the sync service and start periodic syncing
  void initialize({Duration syncInterval = const Duration(minutes: 5)}) {
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
  }

  /// Sync all data (nutrition and fitness plans)
  Future<bool> syncAll() async {
    if (_status == SyncStatus.syncing) {
      _logger.d('Sync already in progress, skipping');
      return false;
    }

    _setStatus(SyncStatus.syncing);

    try {
      // Process any pending sync queue items first
      await _processSyncQueue();

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

  /// Clear all local data (for logout)
  Future<void> clearLocalData(String userId) async {
    await LocalDatabase.clearUserData(userId);
    _logger.d('Cleared local data for user $userId');
  }
}

/// Global sync service instance
final syncService = SyncService();
