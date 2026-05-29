import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final List<UserModel> _users = [
    UserModel(id: 'sv01', username: 'sv01', name: 'Lê Văn Cường', email: 'cuonglv@student.edu.vn', role: 'student', currentSemesterId: 's6', enrolledCourseIds: ['c1', 'c3', 'c7']),
    UserModel(id: 'sv02', username: 'sv02', name: 'Phạm Minh Hoàng', email: 'hoangpm@student.edu.vn', role: 'student', currentSemesterId: 's6', enrolledCourseIds: ['c1', 'c2', 'c3']),
    UserModel(id: 'gv01', username: 'gv01', name: 'TS. Nguyễn Văn A', email: 'nva@fit.edu.vn', role: 'lecturer', taughtCourseIds: ['c3', 'c7', 'c8']),
    UserModel(id: 'gv02', username: 'gv02', name: 'ThS. Trần Thị B', email: 'ttb@fit.edu.vn', role: 'lecturer', taughtCourseIds: ['c1', 'c2']),
    UserModel(id: 'admin', username: 'admin', name: 'Quản trị viên', email: 'admin@gmail.com', role: 'admin'),
  ];

  List<UserModel> get users => _users;

  void enrollUserInCourse(String userId, String courseId) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _users[index];
      if (!user.enrolledCourseIds.contains(courseId)) {
        _users[index] = UserModel(
          id: user.id,
          username: user.username,
          name: user.name,
          email: user.email,
          role: user.role,
          currentSemesterId: user.currentSemesterId,
          enrolledCourseIds: [...user.enrolledCourseIds, courseId],
          taughtCourseIds: user.taughtCourseIds,
        );
        notifyListeners();
      }
    }
  }

  void unenrollUserFromCourse(String userId, String courseId) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _users[index];
      _users[index] = UserModel(
        id: user.id,
        username: user.username,
        name: user.name,
        email: user.email,
        role: user.role,
        currentSemesterId: user.currentSemesterId,
        enrolledCourseIds: user.enrolledCourseIds.where((id) => id != courseId).toList(),
        taughtCourseIds: user.taughtCourseIds,
      );
      notifyListeners();
    }
  }
}
