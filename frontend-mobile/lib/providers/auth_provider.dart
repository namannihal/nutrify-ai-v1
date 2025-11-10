import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? user;
  bool isLoading = true;
  bool get isAuthenticated => user != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      ApiClient().setToken(token);
      try {
        user = await ApiClient().getCurrentUser();
      } catch (_) {
        user = null;
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    final res = await ApiClient().login(email, password);
    await _saveToken(res['token']);
    user = UserModel.fromMap(res['user']);
    isLoading = false;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    isLoading = true;
    notifyListeners();
    final res = await ApiClient().register(name, email, password);
    await _saveToken(res['token']);
    user = UserModel.fromMap(res['user']);
    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ApiClient().clearToken();
    user = null;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    ApiClient().setToken(token);
  }
}
