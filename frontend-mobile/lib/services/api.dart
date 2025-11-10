import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile/models/user.dart';

// Update API_BASE_URL as appropriate for your environment.
const API_BASE_URL = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');

class ApiClient {
  String? _token;

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal();

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Uri _uri(String path) => Uri.parse('$API_BASE_URL$path');

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('API POST ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(_uri(path), headers: _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('API GET ${res.statusCode}: ${res.body}');
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    return _post('/auth/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    return _post('/auth/register', {'name': name, 'email': email, 'password': password});
  }

  Future<UserModel> getCurrentUser() async {
    final data = await _get('/users/me/basic');
    return UserModel.fromMap(data);
  }

  // Nutrition / Fitness / AI endpoints (examples)
  Future<Map<String, dynamic>> generateNutrition() async {
    return _post('/nutrition/generate');
  }

  Future<Map<String, dynamic>> generateWorkout() async {
    return _post('/fitness/generate');
  }

  Future<Map<String, dynamic>> chatWithAI(String message) async {
    return _post('/ai/chat', {'message': message});
  }
}
