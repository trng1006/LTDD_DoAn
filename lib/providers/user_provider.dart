import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../core/services/api_service.dart';

class UserProvider with ChangeNotifier {
  final String _baseUrl = ApiService.baseUrl;
  
  bool isLoading = false;

  List<UserModel> _users = [];

  List<UserModel> get users => _users;

  Future<void> fetchUsers() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _users = data.map((json) => UserModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Lỗi fetchUsers: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addUser({
    required String id,
    required String username,
    required String name,
    required String email,
    required String password,
    required String role,
    required String identity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'username': username.isEmpty ? id : username,
          'name': name,
          'email': email,
          'password': password.isEmpty ? '123' : password,
          'role': role,
          'identity': identity,
          'enrolledCourseIds': [],
          'taughtCourseIds': [],
          'currentSemesterId': role == 'student' ? 's6' : null,
        }),
      );

      if (response.statusCode == 200) {
        final newUser = UserModel(
          id: id,
          username: username.isEmpty ? id : username,
          name: name,
          email: email,
          role: role,
          identity: identity,
          enrolledCourseIds: [],
          taughtCourseIds: [],
          currentSemesterId: role == 'student' ? 's6' : null,
        );
        
        _users.add(newUser);
        notifyListeners();
        return null;
      } else {
        final errorData = jsonDecode(response.body);
        return errorData['detail'] ?? 'Có lỗi xảy ra khi tạo tài khoản.';
      }
    } catch (e) {
      return 'Không thể kết nối tới máy chủ: $e';
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/users/$userId'));
      if (response.statusCode == 200) {
        _users.removeWhere((u) => u.id == userId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi khi thực hiện xóa người dùng: $e');
      return false;
    }
  }

  // --- HÀM MỚI BỔ SUNG: Cập nhật Học kỳ cho Sinh viên ---
  Future<bool> updateStudentSemester(String userId, String? semesterId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;

    final user = _users[index];

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': user.id,
          'username': user.username,
          'name': user.name,
          'email': user.email,
          'role': user.role,
          'identity': user.identity,
          'enrolledCourseIds': user.enrolledCourseIds,
          'taughtCourseIds': user.taughtCourseIds,
          'currentSemesterId': semesterId, // Cập nhật học kỳ ở đây
        }),
      );

      if (response.statusCode == 200) {
        _users[index] = user.copyWith(currentSemesterId: semesterId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi khi cập nhật học kỳ cho sinh viên: $e');
      return false;
    }
  }

  Future<bool> enrollUserInCourse(String userId, String courseId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;

    final user = _users[index];
    if (user.enrolledCourseIds.contains(courseId)) return true;

    final updatedCourses = [...user.enrolledCourseIds, courseId];

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': user.id,
          'username': user.username,
          'name': user.name,
          'email': user.email,
          'role': user.role,
          'identity': user.identity,
          'enrolledCourseIds': updatedCourses,
          'taughtCourseIds': user.taughtCourseIds,
          'currentSemesterId': user.currentSemesterId,
        }),
      );

      if (response.statusCode == 200) {
        _users[index] = user.copyWith(enrolledCourseIds: updatedCourses);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi khi đăng ký môn học: $e');
      return false;
    }
  }

  Future<bool> unenrollUserFromCourse(String userId, String courseId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;

    final user = _users[index];
    if (!user.enrolledCourseIds.contains(courseId)) return true;

    final updatedCourses = user.enrolledCourseIds.where((id) => id != courseId).toList();

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': user.id,
          'username': user.username,
          'name': user.name,
          'email': user.email,
          'role': user.role,
          'identity': user.identity,
          'enrolledCourseIds': updatedCourses,
          'taughtCourseIds': user.taughtCourseIds,
          'currentSemesterId': user.currentSemesterId,
        }),
      );

      if (response.statusCode == 200) {
        _users[index] = user.copyWith(enrolledCourseIds: updatedCourses);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi khi hủy đăng ký môn học: $e');
      return false;
    }
  }
}