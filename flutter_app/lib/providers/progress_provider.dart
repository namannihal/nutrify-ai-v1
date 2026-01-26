import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress.dart';
import '../services/api_service.dart';

// Progress State
class ProgressState {
  final bool isLoading;
  final List<ProgressEntry> entries;
  final String? error;

  const ProgressState({
    this.isLoading = false,
    this.entries = const [],
    this.error,
  });

  ProgressState copyWith({
    bool? isLoading,
    List<ProgressEntry>? entries,
    String? error,
  }) {
    return ProgressState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      error: error,
    );
  }
}

// Progress Notifier
class ProgressNotifier extends StateNotifier<ProgressState> {
  final ApiService _apiService;

  ProgressNotifier(this._apiService) : super(const ProgressState());

  Future<void> loadProgressEntries() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final entries = await _apiService.getProgressEntries();
      state = state.copyWith(
        isLoading: false,
        entries: entries,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addProgressEntry(ProgressEntryCreate entry) async {
    try {
      final newEntry = await _apiService.createProgressEntry(entry);
      // Insert new entry at the beginning and sort by date (newest first)
      final updatedEntries = [newEntry, ...state.entries];
      updatedEntries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
      state = state.copyWith(
        entries: updatedEntries,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateProgressEntry(ProgressEntry entry) async {
    try {
      final updatedEntry = await _apiService.updateProgressEntry(entry.id, entry);
      final updatedEntries = state.entries.map((e) {
        return e.id == updatedEntry.id ? updatedEntry : e;
      }).toList();
      
      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addWaterIntake(int ml) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Find today's entry
      final todayEntry = state.entries.cast<ProgressEntry?>().firstWhere(
        (e) => e?.entryDate == today,
        orElse: () => null,
      );
      
      if (todayEntry != null) {
        // Update existing entry
        final newIntake = (todayEntry.waterIntakeMl ?? 0) + ml;
        final updatedEntry = ProgressEntry(
          id: todayEntry.id,
          userId: todayEntry.userId,
          entryDate: todayEntry.entryDate,
          weight: todayEntry.weight,
          bodyFatPercentage: todayEntry.bodyFatPercentage,
          muscleMass: todayEntry.muscleMass,
          measurements: todayEntry.measurements,
          moodScore: todayEntry.moodScore,
          energyScore: todayEntry.energyScore,
          stressScore: todayEntry.stressScore,
          sleepHours: todayEntry.sleepHours,
          sleepQuality: todayEntry.sleepQuality,
          waterIntakeMl: newIntake,
          adherenceScore: todayEntry.adherenceScore,
          notes: todayEntry.notes,
          photos: todayEntry.photos,
          createdAt: todayEntry.createdAt,
        );
        await updateProgressEntry(updatedEntry);
      } else {
        // Create new entry with just water intake
        final newEntry = ProgressEntryCreate(
          entryDate: today,
          waterIntakeMl: ml,
        );
        await addProgressEntry(newEntry);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteProgressEntry(String entryId) async {
    try {
      await _apiService.deleteProgressEntry(entryId);
      final updatedEntries = state.entries.where((e) => e.id != entryId).toList();
      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Provider
final progressNotifierProvider = StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProgressNotifier(apiService);
});