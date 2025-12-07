import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';

// Auth state
class AuthState {
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
  bool get hasCompletedOnboarding => profile?.onboardingCompleted == true;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(const AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    if (await _apiService.isLoggedIn) {
      await _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final user = await _apiService.getCurrentUser();
      state = state.copyWith(user: user);

      // Try to load profile
      try {
        final profile = await _apiService.getUserProfile();
        state = state.copyWith(profile: profile, isLoading: false);
      } catch (e) {
        // Profile might not exist yet (404)
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final name = '$firstName $lastName';
      final authResponse = await _apiService.register(email, password, name);
      state = state.copyWith(user: authResponse.user);
      
      await _loadUserProfile();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final authResponse = await _apiService.login(email, password);
      state = state.copyWith(user: authResponse.user);
      
      await _loadUserProfile();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // For now, we'll use a placeholder implementation
      // TODO: Implement actual Google Sign-In
      final authResponse = await _apiService.googleSignIn();
      state = state.copyWith(user: authResponse.user);
      
      await _loadUserProfile();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = const AuthState();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _apiService.getUserProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      // Profile might not exist yet
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedProfile = await _apiService.updateUserProfile(profileData);
      state = state.copyWith(profile: updatedProfile, isLoading: false);
      
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider definitions
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});

