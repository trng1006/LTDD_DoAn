import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  // Biến kiểm tra nền tảng để tự động chuyển đổi giữa localhost (Web) và 10.0.2.2 (Máy ảo Android)
  final String _baseUrl = kIsWeb ? 'http://localhost:8000' : 'http://127.0.0.1';
  
  bool isLoading = false;

  // Giữ lại dữ liệu mẫu (hardcode) làm fallback tạm thời. 
  // Thực tế bạn có thể chuyển thành mảng rỗng [] và dùng hàm fetchUsers() để lấy từ Backend
  List<UserModel> _users = [
    UserModel(id: 'sv01', username: 'sv01', name: 'Lê Văn Cường', email: 'cuonglv@student.edu.vn', role: 'student', currentSemesterId: 's6', enrolledCourseIds: ['c1', 'c3', 'c7']),
    UserModel(id: 'sv02', username: 'sv02', name: 'Phạm Minh Hoàng', email: 'hoangpm@student.edu.vn', role: 'student', currentSemesterId: 's6', enrolledCourseIds: ['c1', 'c2', 'c3']),
    UserModel(id: 'gv01', username: 'gv01', name: 'TS. Nguyễn Văn A', email: 'nva@fit.edu.vn', role: 'lecturer', taughtCourseIds: ['c3', 'c7', 'c8']),
    UserModel(id: 'gv02', username: 'gv02', name: 'ThS. Trần Thị B', email: 'ttb@fit.edu.vn', role: 'lecturer', taughtCourseIds: ['c1', 'c2']),
    UserModel(id: 'admin', username: 'admin', name: 'Quản trị viên', email: 'admin@gmail.com', role: 'admin'),
  ];

  List<UserModel> get users => _users;

  // =======================================================
  // CÁC HÀM TƯƠNG TÁC VỚI API BACKEND (FASTAPI + MYSQL)
  // =======================================================

  /// Hàm lấy danh sách User từ MySQL (Có thể gọi ở initState của giao diện)
  Future<void> fetchUsers() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _users = data.map((json) => UserModel(
          id: json['id'],
          username: json['username'] ?? json['id'],
          name: json['name'],
          email: json['email'],
          role: json['role'],
          identity: json['identity'],
          currentSemesterId: json['currentSemesterId'],
          enrolledCourseIds: List<String>.from(json['enrolledCourseIds'] ?? []),
          taughtCourseIds: List<String>.from(json['taughtCourseIds'] ?? []),
        )).toList();
      }
    } catch (e) {
      debugPrint('Lỗi fetchUsers: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Hàm thêm một User mới
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
        // Cập nhật lại UI ngay lập tức mà không cần gọi API fetch lại danh sách
        final newUser = UserModel(
          id: id,
          username: username.isEmpty ? id : username,
          name: name,
          email: email,
          role: role,
          identity: identity,
          enrolledCourseIds: [],
          taughtCourseIds: [],
          currentSemesterId: role == 'student' ? 's6' : '',
        );
        
        _users.add(newUser);
        notifyListeners();
        return null; // Return null nghĩa là thành công
      } else {
        final errorData = jsonDecode(response.body);
        return errorData['detail'] ?? 'Có lỗi xảy ra khi tạo tài khoản.';
      }
    } catch (e) {
      return 'Không thể kết nối tới máy chủ: $e';
    }
  }

  /// Hàm xóa User
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

  // =======================================================
  // CÁC HÀM XỬ LÝ NỘI BỘ (ĐĂNG KÝ MÔN HỌC)
  // =======================================================

/// Đăng ký môn học cho Sinh viên và đồng bộ lên Backend MySQL
  Future<bool> enrollUserInCourse(String userId, String courseId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;

    final user = _users[index];
    // Nếu môn học đã được đăng ký rồi thì không cần gửi request lại
    if (user.enrolledCourseIds.contains(courseId)) return true;

    // Tạo danh sách môn học mới sau khi thêm
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
        // Cập nhật trạng thái cục bộ tại UI sau khi server xử lý thành công
        _users[index] = UserModel(
          id: user.id,
          username: user.username,
          name: user.name,
          email: user.email,
          role: user.role,
          identity: user.identity,
          currentSemesterId: user.currentSemesterId,
          enrolledCourseIds: updatedCourses,
          taughtCourseIds: user.taughtCourseIds,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi khi đăng ký môn học: $e');
      return false;
    }
  }

  /// Hủy đăng ký môn học của Sinh viên và đồng bộ lên Backend MySQL
  Future<bool> unenrollUserFromCourse(String userId, String courseId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;

    final user = _users[index];
    if (!user.enrolledCourseIds.contains(courseId)) return true;

    // Lọc bỏ môn học muốn hủy ra khỏi danh sách
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
        // Cập nhật trạng thái cục bộ tại UI sau khi server xử lý thành công
        _users[index] = UserModel(
          id: user.id,
          username: user.username,
          name: user.name,
          email: user.email,
          role: user.role,
          identity: user.identity,
          currentSemesterId: user.currentSemesterId,
          enrolledCourseIds: updatedCourses,
          taughtCourseIds: user.taughtCourseIds,
        );
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