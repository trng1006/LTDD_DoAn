import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Mock login logic
    await Future.delayed(const Duration(seconds: 2));
    _user = UserModel(id: '1', email: email, name: 'Test User', role: 'student');

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }
}
