import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/semester_model.dart';

class CourseProvider with ChangeNotifier {
  final List<SemesterModel> _semesters = [
    SemesterModel(id: 's6', name: 'Học kỳ 6', isActive: true),
  ];

  final List<CourseModel> _courses = [
    CourseModel(id: 'c1', name: 'Deep learning', code: '0101101956', semesterId: 's6'),
    CourseModel(id: 'c2', name: 'Thực hành deep learning', code: '0101101957', semesterId: 's6'),
    CourseModel(id: 'c3', name: 'Lập trình di động', code: '0101101969', semesterId: 's6'),
    CourseModel(id: 'c4', name: 'Khai phá dữ liệu', code: '0101101970', semesterId: 's6'),
    CourseModel(id: 'c5', name: 'Quản trị hệ thống mạng', code: '0101101973', semesterId: 's6'),
    CourseModel(id: 'c6', name: 'Thực hành quản trị hệ thống mạng', code: '0101101974', semesterId: 's6'),
    CourseModel(id: 'c7', name: 'Phân tích thiết kế hệ thống', code: '0101101976', semesterId: 's6'),
    CourseModel(id: 'c8', name: 'Thực hành phân tích thiết kế hệ thống', code: '0101101977', semesterId: 's6'),
    CourseModel(id: 'c9', name: 'Công nghệ Java', code: '0101101980', semesterId: 's6'),
  ];

  List<CourseModel> get courses => _courses;
  List<SemesterModel> get semesters => _semesters;

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- Lớp/môn đang được chọn (dùng cho chức năng Đổi lớp) ---
  String? _selectedCourseId;
  String? get selectedCourseId => _selectedCourseId;

  CourseModel? get selectedCourse =>
      _selectedCourseId == null ? null : getCourseById(_selectedCourseId!);

  void selectCourse(String courseId) {
    if (_selectedCourseId == courseId) return;
    _selectedCourseId = courseId;
    notifyListeners();
  }

  /// Đặt lớp mặc định (lớp đầu tiên SV đang học) nếu chưa chọn lớp nào.
  void ensureDefaultCourse(List<String> enrolledCourseIds) {
    if (_selectedCourseId != null) return;
    if (enrolledCourseIds.isNotEmpty) {
      _selectedCourseId = enrolledCourseIds.first;
    }
  }

  void addCourse(CourseModel course) {
    _courses.add(course);
    notifyListeners();
  }

  CourseModel? getCourseById(String id) {
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CourseModel> getCoursesBySemester(String semesterId) {
    return _courses.where((c) => c.semesterId == semesterId).toList();
  }

  SemesterModel? getSemesterById(String id) {
    try {
      return _semesters.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
