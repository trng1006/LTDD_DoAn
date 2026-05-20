import 'user_model.dart';

class StudentModel extends UserModel {
  final String studentId;
  final String classId;
  final String? groupId;

  StudentModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    required this.studentId,
    required this.classId,
    this.groupId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'student',
      studentId: json['studentId'] ?? '',
      classId: json['classId'] ?? '',
      groupId: json['groupId'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'studentId': studentId,
      'classId': classId,
      'groupId': groupId,
    });
    return map;
  }
}
