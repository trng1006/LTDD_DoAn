import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> login(String identity, String password) async {
    _isLoading = true;
    notifyListeners();

    // Mock API delay
    await Future.delayed(const Duration(seconds: 1));

    final String idLower = identity.trim().toLowerCase();

    // Support both ID (username) and Email login
    if ((idLower == 'sv01' || idLower == 'sv01@gmail.com') && password == '123') {
      _user = UserModel(
        id: 'sv01',
        email: 'sv01@gmail.com',
        name: 'Sinh Viên 01 (Nhóm trưởng)',
        role: 'student',
      );
    } else if ((idLower == 'gv01' || idLower == 'gv01@gmail.com') && password == '123') {
      _user = UserModel(
        id: 'gv01',
        email: 'gv01@gmail.com',
        name: 'Giảng Viên 01',
        role: 'lecturer',
      );
    } else if ((idLower == 'admin' || idLower == 'admin@gmail.com') && password == '123') {
      _user = UserModel(
        id: 'admin',
        email: 'admin@gmail.com',
        name: 'Quản trị viên',
        role: 'admin',
      );
    } else if (idLower.startsWith('sv') && password == '123') {
      _user = UserModel(
        id: idLower.contains('@') ? idLower.split('@')[0] : idLower,
        email: idLower.contains('@') ? idLower : '$idLower@gmail.com',
        name: 'Sinh viên ${idLower.contains('@') ? idLower.split('@')[0] : idLower}',
        role: 'student',
      );
    } else {
      // For demo, any other login is rejected or guest
      _user = null; // Changed to null to force correct login
    }

    _isLoading = false;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
