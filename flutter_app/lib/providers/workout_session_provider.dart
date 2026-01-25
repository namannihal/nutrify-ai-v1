import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/workout_session.dart';
import '../models/fitness.dart';
import '../services/api_service.dart';

final _logger = Logger();

/// UUID validation regex
final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool _isValidUuid(String value) => _uuidRegex.hasMatch(value);

/// Pending set to be synced with backend
class PendingSet {
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final double weightKg;
  final int reps;
  final bool isWarmup;
  final int restSeconds;
  final DateTime completedAt;

  PendingSet({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.isWarmup,
    required this.restSeconds,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'exercise_id': exerciseId,
    'exercise_name': exerciseName,
    'set_number': setNumber,
    'weight_kg': weightKg,
    'reps': reps,
    'is_warmup': isWarmup,
    'rest_seconds': restSeconds,
  };
}

/// State for the active workout session
class WorkoutSessionState {
  final WorkoutSession? activeSession;
  final List<ActiveExerciseProgress> exercises;
  final int currentExerciseIndex;
  final bool isLoading;
  final bool isSyncing;
  final String? error;

  // Rest timer state
  final int restTimeRemaining;
  final int restTimerDuration;
  final bool isRestTimerActive;

  // Elapsed workout time
  final int elapsedSeconds;

  // Pending sets to sync (local-first)
  final List<PendingSet> pendingSets;

  const WorkoutSessionState({
    this.activeSession,
    this.exercises = const [],
    this.currentExerciseIndex = 0,
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.restTimeRemaining = 0,
    this.restTimerDuration = 90,
    this.isRestTimerActive = false,
    this.elapsedSeconds = 0,
    this.pendingSets = const [],
  });

  WorkoutSessionState copyWith({
    WorkoutSession? activeSession,
    List<ActiveExerciseProgress>? exercises,
    int? currentExerciseIndex,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    int? restTimeRemaining,
    int? restTimerDuration,
    bool? isRestTimerActive,
    int? elapsedSeconds,
    List<PendingSet>? pendingSets,
  }) {
    return WorkoutSessionState(
      activeSession: activeSession ?? this.activeSession,
      exercises: exercises ?? this.exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      restTimerDuration: restTimerDuration ?? this.restTimerDuration,
      isRestTimerActive: isRestTimerActive ?? this.isRestTimerActive,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      pendingSets: pendingSets ?? this.pendingSets,
    );
  }

  bool get hasActiveSession => activeSession != null && activeSession!.isActive;

  ActiveExerciseProgress? get currentExercise =>
      exercises.isNotEmpty && currentExerciseIndex < exercises.length
          ? exercises[currentExerciseIndex]
          : null;

  int get totalVolume {
    int volume = 0;
    for (final exercise in exercises) {
      for (final set in exercise.completedSets) {
        if (!set.isWarmup) {
          volume += set.volume;
        }
      }
    }
    return volume;
  }

  int get totalSets {
    int sets = 0;
    for (final exercise in exercises) {
      sets += exercise.completedSets.where((s) => !s.isWarmup).length;
    }
    return sets;
  }

  int get prsThisSession {
    int prs = 0;
    for (final exercise in exercises) {
      prs += exercise.completedSets.where((s) => s.isPR).length;
    }
    return prs;
  }
}

/// Notifier for managing workout sessions with local-first approach
class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  final ApiService _apiService;
  Timer? _restTimer;
  Timer? _elapsedTimer;

  WorkoutSessionNotifier(this._apiService) : super(const WorkoutSessionState());

  @override
  void dispose() {
    _restTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  /// Start a new workout session
  Future<bool> startWorkout(Workout workout) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.d('Starting workout: id=${workout.id}, name=${workout.name}');
      _logger.d('Workout exercises count: ${workout.exercises.length}');

      // Only send workout_id if it's a valid UUID (not a quick start placeholder)
      final bool isValidUuid = _isValidUuid(workout.id);

      // Start session on backend (single API call)
      final session = await _apiService.startWorkoutSession(
        workoutId: isValidUuid ? workout.id : null,
        workoutName: workout.name,
      );
      _logger.d('Session started successfully: ${session.id}');

      // Initialize exercise progress from workout (no API calls here!)
      final exercises = workout.exercises.map((e) {
        return ActiveExerciseProgress(
          exerciseId: e.id,
          name: e.name,
          targetSets: e.sets ?? 3,
          targetReps: e.reps,
          restSeconds: e.restTimeSeconds ?? 90,
        );
      }).toList();

      state = state.copyWith(
        activeSession: session,
        exercises: exercises,
        currentExerciseIndex: 0,
        isLoading: false,
        elapsedSeconds: 0,
        pendingSets: [],
      );

      // Start elapsed timer
      _startElapsedTimer();

      // Load exercise history in background (non-blocking)
      _loadExerciseHistoryInBackground(exercises);

      return true;
    } catch (e) {
      _logger.e('Failed to start workout: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load exercise history in background without blocking UI
  Future<void> _loadExerciseHistoryInBackground(List<ActiveExerciseProgress> exercises) async {
    for (int i = 0; i < exercises.length; i++) {
      // Check if state is still valid (session not abandoned)
      if (state.activeSession == null) return;

      try {
        final history = await _apiService.getExerciseHistory(exercises[i].name);
        if (history.entries.isNotEmpty && state.exercises.length > i) {
          final updatedExercises = List<ActiveExerciseProgress>.from(state.exercises);
          updatedExercises[i] = updatedExercises[i].copyWith(
            previousSession: history.entries.take(5).toList(),
          );
          state = state.copyWith(exercises: updatedExercises);
        }
      } catch (e) {
        _logger.d('No history for ${exercises[i].name}');
      }

      // Small delay between calls to not overwhelm the server
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Start a custom workout (not from a plan)
  Future<bool> startCustomWorkout(String workoutName, List<Exercise> exercises) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final session = await _apiService.startWorkoutSession(
        workoutName: workoutName,
      );

      final exerciseProgress = exercises.map((e) {
        return ActiveExerciseProgress(
          exerciseId: e.id,
          name: e.name,
          targetSets: e.sets ?? 3,
          targetReps: e.reps,
          restSeconds: e.restTimeSeconds ?? 90,
        );
      }).toList();

      state = state.copyWith(
        activeSession: session,
        exercises: exerciseProgress,
        currentExerciseIndex: 0,
        isLoading: false,
        elapsedSeconds: 0,
        pendingSets: [],
      );

      _startElapsedTimer();

      return true;
    } catch (e) {
      _logger.e('Failed to start custom workout: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Log a completed set - LOCAL FIRST, no network call
  bool logSet({
    required int exerciseIndex,
    double weightKg = 0,
    int reps = 0,
    int? durationSeconds,
    bool isWarmup = false,
    int? customRestSeconds, // Custom rest time from user setting
  }) {
    if (state.activeSession == null) return false;

    try {
      final exercise = state.exercises[exerciseIndex];
      final setNumber = exercise.completedSets.length + 1;
      final restSeconds = customRestSeconds ?? exercise.restSeconds ?? 90;

      // Create local set immediately (no network)
      final completedSet = CompletedSetLocal(
        setNumber: setNumber,
        weightKg: weightKg,
        reps: reps,
        durationSeconds: durationSeconds,
        isWarmup: isWarmup,
        isPR: false, // Will be determined by backend on sync
      );

      // Add to pending sets for later sync
      final pendingSet = PendingSet(
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.name,
        setNumber: setNumber,
        weightKg: weightKg,
        reps: reps,
        isWarmup: isWarmup,
        restSeconds: restSeconds,
        completedAt: DateTime.now(),
      );

      // Update exercise progress immediately
      final updatedExercises = List<ActiveExerciseProgress>.from(state.exercises);
      updatedExercises[exerciseIndex] = exercise.copyWith(
        completedSets: [...exercise.completedSets, completedSet],
      );

      state = state.copyWith(
        exercises: updatedExercises,
        pendingSets: [...state.pendingSets, pendingSet],
      );

      // Start rest timer if not a warmup
      if (!isWarmup) {
        startRestTimer(restSeconds);
      }

      return true;
    } catch (e) {
      _logger.e('Failed to log set locally: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add a new exercise to the current workout
  void addExercise(ActiveExerciseProgress exercise) {
    if (state.activeSession == null) return;

    state = state.copyWith(
      exercises: [...state.exercises, exercise],
    );
  }

  /// Delete a completed set from an exercise
  void deleteSet({
    required int exerciseIndex,
    required int setIndex,
  }) {
    if (state.activeSession == null) return;
    if (exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex >= exercise.completedSets.length) return;

    // Remove the set from completed sets
    final updatedSets = List<CompletedSetLocal>.from(exercise.completedSets);
    final removedSet = updatedSets.removeAt(setIndex);

    // Renumber remaining sets
    final renumberedSets = updatedSets.asMap().entries.map((entry) {
      return entry.value.copyWith(setNumber: entry.key + 1);
    }).toList();

    // Update exercise
    final updatedExercises = List<ActiveExerciseProgress>.from(state.exercises);
    updatedExercises[exerciseIndex] = exercise.copyWith(
      completedSets: renumberedSets,
    );

    // Remove from pending sets if it hasn't been synced yet
    final updatedPendingSets = state.pendingSets.where((pending) {
      return !(pending.exerciseId == exercise.exerciseId &&
          pending.setNumber == removedSet.setNumber);
    }).toList();

    state = state.copyWith(
      exercises: updatedExercises,
      pendingSets: updatedPendingSets,
    );

    _logger.d('Deleted set ${setIndex + 1} from ${exercise.name}');
  }

  /// Start the rest timer
  void startRestTimer(int seconds) {
    _restTimer?.cancel();

    state = state.copyWith(
      restTimeRemaining: seconds,
      restTimerDuration: seconds,
      isRestTimerActive: true,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.restTimeRemaining > 0) {
        state = state.copyWith(restTimeRemaining: state.restTimeRemaining - 1);
      } else {
        timer.cancel();
        state = state.copyWith(isRestTimerActive: false);
      }
    });
  }

  /// Skip the rest timer
  void skipRestTimer() {
    _restTimer?.cancel();
    state = state.copyWith(
      restTimeRemaining: 0,
      isRestTimerActive: false,
    );
  }

  /// Add 30 seconds to rest timer
  void addRestTime(int seconds) {
    if (state.isRestTimerActive) {
      state = state.copyWith(
        restTimeRemaining: state.restTimeRemaining + seconds,
      );
    }
  }

  /// Set the current exercise index
  void setCurrentExercise(int index) {
    if (index >= 0 && index < state.exercises.length) {
      state = state.copyWith(currentExerciseIndex: index);
    }
  }

  /// Move to the next exercise
  void nextExercise() {
    if (state.currentExerciseIndex < state.exercises.length - 1) {
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex + 1);
    }
  }

  /// Move to the previous exercise
  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex - 1);
    }
  }

  /// Add an extra set to an exercise
  void addExtraSet(int exerciseIndex) {
    if (exerciseIndex >= 0 && exerciseIndex < state.exercises.length) {
      final updatedExercises = List<ActiveExerciseProgress>.from(state.exercises);
      updatedExercises[exerciseIndex] = state.exercises[exerciseIndex].copyWith(
        targetSets: state.exercises[exerciseIndex].targetSets + 1,
      );
      state = state.copyWith(exercises: updatedExercises);
    }
  }

  /// Complete the workout session - syncs all pending sets
  Future<WorkoutSessionSummary?> finishWorkout({String? notes}) async {
    if (state.activeSession == null) return null;

    try {
      state = state.copyWith(isLoading: true, isSyncing: true, error: null);

      // Sync all pending sets to backend
      final syncedPRs = <String>[];
      for (final pendingSet in state.pendingSets) {
        try {
          final backendSet = await _apiService.logWorkoutSet(
            sessionId: state.activeSession!.id,
            exerciseId: pendingSet.exerciseId,
            exerciseName: pendingSet.exerciseName,
            setNumber: pendingSet.setNumber,
            weightKg: pendingSet.weightKg,
            reps: pendingSet.reps,
            isWarmup: pendingSet.isWarmup,
            restSeconds: pendingSet.restSeconds,
          );
          if (backendSet.isPR) {
            syncedPRs.add(pendingSet.exerciseName);
          }
        } catch (e) {
          _logger.w('Failed to sync set: $e');
          // Continue syncing other sets
        }
      }

      // Complete the session
      final summary = await _apiService.completeWorkoutSession(
        sessionId: state.activeSession!.id,
        notes: notes,
      );

      _restTimer?.cancel();
      _elapsedTimer?.cancel();

      state = const WorkoutSessionState(); // Reset state

      return summary;
    } catch (e) {
      _logger.e('Failed to finish workout: $e');
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Abandon the workout session
  Future<bool> abandonWorkout() async {
    if (state.activeSession == null) return false;

    try {
      await _apiService.abandonWorkoutSession(state.activeSession!.id);

      _restTimer?.cancel();
      _elapsedTimer?.cancel();

      state = const WorkoutSessionState(); // Reset state

      return true;
    } catch (e) {
      _logger.e('Failed to abandon workout: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Check and restore active session on app start
  Future<void> checkForActiveSession() async {
    try {
      final session = await _apiService.getActiveWorkoutSession();
      if (session != null && session.isActive) {
        // Restore session
        state = state.copyWith(
          activeSession: session,
          elapsedSeconds: session.durationSeconds,
        );
        _startElapsedTimer();
      }
    } catch (e) {
      _logger.d('No active session found');
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  /// Format elapsed time as MM:SS or HH:MM:SS
  String get formattedElapsedTime {
    final hours = state.elapsedSeconds ~/ 3600;
    final minutes = (state.elapsedSeconds % 3600) ~/ 60;
    final seconds = state.elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format rest time as M:SS
  String get formattedRestTime {
    final minutes = state.restTimeRemaining ~/ 60;
    final seconds = state.restTimeRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Provider for workout session state
final workoutSessionProvider = StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return WorkoutSessionNotifier(apiService);
});

/// Provider for workout history
final workoutHistoryProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getWorkoutSessionHistory();
});

/// Provider for personal records
final personalRecordsProvider = FutureProvider<List<PersonalRecord>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getPersonalRecords();
});

/// Provider for exercise history
final exerciseHistoryProvider = FutureProvider.family<ExerciseHistory, String>((ref, exerciseName) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getExerciseHistory(exerciseName);
});
