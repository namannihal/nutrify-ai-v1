import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/user.dart';
import '../models/nutrition.dart';
import '../models/fitness.dart';
import '../models/progress.dart';
import '../models/ai.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api/v1';
  static const String _storageKeyToken = 'auth_token';
  static const String _storageKeyRefreshToken = 'refresh_token';
  
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  
  String? _cachedToken;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> get _token async {
    _cachedToken ??= await _storage.read(key: _storageKeyToken);
    return _cachedToken;
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _storageKeyToken, value: token);
    _cachedToken = token;
  }

  Future<void> _setToken(String? token) async {
    if (token != null) {
      await _storage.write(key: _storageKeyToken, value: token);
      _cachedToken = token;
    } else {
      await _storage.delete(key: _storageKeyToken);
      _cachedToken = null;
    }
  }

  Future<void> _setRefreshToken(String? refreshToken) async {
    if (refreshToken != null) {
      await _storage.write(key: _storageKeyRefreshToken, value: refreshToken);
    } else {
      await _storage.delete(key: _storageKeyRefreshToken);
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, String>> get _authHeaders async {
    final token = await _token;
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<T> _makeRequest<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final headers = requiresAuth ? await _authHeaders : _headers;

      _logger.d('$method $endpoint');

      http.Response response;
      switch (method.toLowerCase()) {
        case 'get':
          response = await _client.get(url, headers: headers);
          break;
        case 'post':
          response = await _client.post(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'put':
          response = await _client.put(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'delete':
          response = await _client.delete(url, headers: headers);
          break;
        default:
          throw ArgumentError('Unsupported method: $method');
      }

      _logger.d('Response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 401) {
        // Token expired, try to refresh
        await _refreshToken();
        throw ApiException('Please log in again', 401);
      }

      if (response.statusCode >= 400) {
        final errorData = json.decode(response.body);
        throw ApiException(
          errorData['detail'] ?? 'Request failed',
          response.statusCode,
        );
      }

      if (response.body.isEmpty) {
        return null as T;
      }

      final responseData = json.decode(response.body);
      
      if (fromJson != null) {
        return fromJson(responseData);
      }
      
      return responseData as T;
    } on SocketException {
      throw ApiException('Network connection failed');
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e');
    }
  }

  Future<void> _refreshToken() async {
    final refreshToken = await _storage.read(key: _storageKeyRefreshToken);
    if (refreshToken == null) {
      throw ApiException('No refresh token available');
    }

    // TODO: Implement refresh token logic based on your backend
    // For now, just clear tokens to force re-login
    await logout();
  }

  // Authentication methods
  Future<AuthResponse> login(String email, String password) async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    final authResponse = AuthResponse.fromJson(response);
    await _setToken(authResponse.token);
    await _setRefreshToken(authResponse.refreshToken);
    
    return authResponse;
  }

  Future<AuthResponse> googleSignIn() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/auth/google',
      body: {},
      requiresAuth: false,
    );

    final authResponse = AuthResponse.fromJson(response);
    await _setToken(authResponse.token);
    await _setRefreshToken(authResponse.refreshToken);
    
    return authResponse;
  }

  Future<AuthResponse> register(String email, String password, String name) async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'name': name,
      },
      requiresAuth: false,
    );

    final authResponse = AuthResponse.fromJson(response);
    await _setToken(authResponse.token);
    await _setRefreshToken(authResponse.refreshToken);
    
    return authResponse;
  }

  Future<void> logout() async {
    await _setToken(null);
    await _setRefreshToken(null);
  }

  Future<bool> get isLoggedIn async {
    final token = await _token;
    return token != null;
  }

  // User methods
  Future<User> getCurrentUser() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/users/me/basic',
    );
    return User.fromJson(response);
  }

  Future<UserProfile> getUserProfile() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/users/me',
    );
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateUserProfile(Map<String, dynamic> profileData) async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'PUT',
      '/users/me',
      body: profileData,
    );
    return UserProfile.fromJson(response);
  }

  // Nutrition methods
  Future<NutritionPlan> getCurrentNutritionPlan() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/nutrition/current-plan',
    );
    return NutritionPlan.fromJson(response);
  }

  Future<NutritionPlan> generateNutritionPlan() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/nutrition/generate',
    );
    return NutritionPlan.fromJson(response);
  }

  Future<void> logMeal({
    required String mealType,
    required List<Map<String, dynamic>> foods,
    required String date,
  }) async {
    await _makeRequest(
      'POST',
      '/nutrition/log-meal',
      body: {
        'meal_type': mealType,
        'foods': foods,
        'date': date,
      },
    );
  }

  // Fitness methods
  Future<WorkoutPlan> getCurrentWorkoutPlan() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/fitness/current-plan',
    );
    return WorkoutPlan.fromJson(response);
  }

  Future<WorkoutPlan> generateWorkoutPlan() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/fitness/generate',
    );
    return WorkoutPlan.fromJson(response);
  }

  Future<void> logWorkout({
    required String workoutId,
    required List<Map<String, dynamic>> exercisesCompleted,
    required int duration,
    required String date,
  }) async {
    await _makeRequest(
      'POST',
      '/fitness/log-workout',
      body: {
        'workout_id': workoutId,
        'exercises_completed': exercisesCompleted,
        'duration': duration,
        'date': date,
      },
    );
  }

  // Progress methods
  Future<List<ProgressEntry>> getProgressHistory({int days = 30}) async {
    final response = await _makeRequest<List<dynamic>>(
      'GET',
      '/progress?days=$days',
    );
    return response.map((json) => ProgressEntry.fromJson(json)).toList();
  }

  Future<ProgressEntry> logProgress(ProgressEntry progressData) async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/progress',
      body: progressData.toJson(),
    );
    return ProgressEntry.fromJson(response);
  }

  Future<List<ProgressEntry>> getProgressEntries({int limit = 30}) async {
    final response = await _makeRequest<List<dynamic>>(
      'GET',
      '/progress?limit=$limit',
    );
    return response.map((json) => ProgressEntry.fromJson(json)).toList();
  }

  Future<ProgressEntry> createProgressEntry(ProgressEntry progressData) async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/progress',
      body: progressData.toJson(),
    );
    return ProgressEntry.fromJson(response);
  }

  Future<ProgressEntry> updateProgressEntry(String id, ProgressEntry progressData) async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'PUT',
      '/progress/$id',
      body: progressData.toJson(),
    );
    return ProgressEntry.fromJson(response);
  }

  Future<void> deleteProgressEntry(String id) async {
    await _makeRequest(
      'DELETE',
      '/progress/$id',
    );
  }

  // AI methods
  Future<List<AIInsight>> getAIInsights({int limit = 10}) async {
    final response = await _makeRequest<List<dynamic>>(
      'GET',
      '/ai/insights?limit=$limit',
    );
    return response.map((json) => AIInsight.fromJson(json)).toList();
  }

  Future<List<AIInsight>> requestAIAnalysis() async {
    final response = await _makeRequest<List<dynamic>>(
      'POST',
      '/ai/analyze',
    );
    return response.map((json) => AIInsight.fromJson(json)).toList();
  }

  Future<ChatResponse> chatWithAI(String message) async {
    final response = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/ai/chat',
      body: {'message': message},
    );
    return ChatResponse.fromJson(response);
  }
}

// Provider for API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});