import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> login(String identity, String password) async {
    _isLoading = true;
    notifyListeners();

    _user = await _apiService.login(identity, password);

    _isLoading = false;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
