import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      _user = UserModel.fromJson(jsonDecode(userStr));
      notifyListeners();
    }
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  Future<bool> login(String identity, String password) async {
    _isLoading = true;
    notifyListeners();

    _user = await _apiService.login(identity, password);
    if (_user != null) {
      await _saveUser(_user!);
    }

    _isLoading = false;
    notifyListeners();
    return _user != null;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> register(String name, String email, String password, String identity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.register(name, email, password, identity);
    if (result['success']) {
      _user = result['user'];
      await _saveUser(_user!);
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return result['success'];
  }

  Future<bool> updateUser(String name, String email) async {
    if (_user == null) return false;
    
    final updatedUser = _user!.copyWith(
      name: name,
      email: email,
    );

    final success = await _apiService.updateUser(updatedUser);
    if (success) {
      _user = updatedUser;
      await _saveUser(_user!);
      notifyListeners();
    }
    return success;
  }

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    if (_user == null) return {'success': false, 'message': 'Chưa đăng nhập'};
    return await _apiService.changePassword(_user!.id, oldPassword, newPassword);
  }

  Future<void> logout() async {
    _user = null;
    await _clearUser();
    notifyListeners();
  }
}
