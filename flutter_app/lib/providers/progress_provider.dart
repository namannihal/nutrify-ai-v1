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

  Future<void> addProgressEntry(ProgressEntry entry) async {
    try {
      final newEntry = await _apiService.createProgressEntry(entry);
      state = state.copyWith(
        entries: [...state.entries, newEntry],
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