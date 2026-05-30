import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/course_model.dart';
import '../models/semester_model.dart';

class CourseProvider with ChangeNotifier {
  final String _baseUrl = kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

  // --- Dữ liệu tạm thời (Fallback) ---
  List<SemesterModel> _semesters = [
    SemesterModel(id: 's6', name: 'Học kỳ 6', isActive: true),
  ];

  List<CourseModel> _courses = [
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

  bool isLoading = false;

  List<CourseModel> get courses => _courses;
  List<SemesterModel> get semesters => _semesters;

  // ========================================================
  // CÁC TRẠNG THÁI & HÀM HỖ TRỢ HIỂN THỊ (CHO HOME SCREEN)
  // ========================================================
  
  String? _selectedCourseId;
  String? get selectedCourseId => _selectedCourseId;

  CourseModel? get selectedCourse =>
      _selectedCourseId == null ? null : getCourseById(_selectedCourseId!);

  void selectCourse(String courseId) {
    if (_selectedCourseId == courseId) return;
    _selectedCourseId = courseId;
    notifyListeners();
  }

  void ensureDefaultCourse(List<String> enrolledCourseIds) {
    if (_selectedCourseId != null) return;
    if (enrolledCourseIds.isNotEmpty) {
      _selectedCourseId = enrolledCourseIds.first;
    }
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

  SemesterModel? getSemesterById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return _semesters.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  String getSemesterName(String? id) {
    final semester = getSemesterById(id);
    return semester != null ? semester.name : 'Chưa phân bổ';
  }

  // ========================================================
  // CÁC HÀM GIAO TIẾP VỚI API BACKEND (CHO QUẢN LÝ ADMIN)
  // ========================================================

  Future<void> fetchAllData() async {
    isLoading = true;
    notifyListeners();
    try {
      await Future.wait([fetchSemesters(), fetchCourses()]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSemesters() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/semesters'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _semesters = data.map((json) => SemesterModel(
          id: json['id'],
          name: json['name'],
          isActive: json['isActive'],
        )).toList();
      }
    } catch (e) {
      debugPrint("Lỗi fetchSemesters: $e");
    }
  }

  Future<void> fetchCourses() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/courses'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _courses = data.map((json) => CourseModel(
          id: json['id'],
          name: json['name'],
          code: json['code'],
          semesterId: json['semesterId'],
        )).toList();
      }
    } catch (e) {
      debugPrint("Lỗi fetchCourses: $e");
    }
  }

  Future<bool> addSemester(String id, String name, bool isActive) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/semesters'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'name': name, 'isActive': isActive}),
    );
    if (response.statusCode == 200) {
      await fetchSemesters();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> setSemesterActive(String id) async {
    final response = await http.put(Uri.parse('$_baseUrl/semesters/$id/toggle-active'));
    if (response.statusCode == 200) {
      await fetchSemesters();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> addCourse(String id, String name, String code, String? semesterId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/courses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'name': name, 'code': code, 'semesterId': semesterId}),
    );
    if (response.statusCode == 200) {
      await fetchCourses();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteCourse(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/courses/$id'));
    if (response.statusCode == 200) {
      _courses.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }
}