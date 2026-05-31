class UserModel {
  final String id;
  final String username;
  final String name;
  final String email;
  final String role; // student, lecturer, admin
  final String? identity; // MSSV or Staff ID
  final String? currentSemesterId;
  final List<String> enrolledCourseIds;
  final List<String> taughtCourseIds;
  final bool isActive; // Trạng thái hoạt động của người dùng
  UserModel({
    required this.id,
    this.username = '',
    required this.name,
    required this.email,
    required this.role,
    this.identity,
    this.currentSemesterId,
    this.enrolledCourseIds = const [],
    this.taughtCourseIds = const [],
    required this.isActive, // Trạng thái hoạt động của người dùng
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      identity: json['identity']?.toString(),
      currentSemesterId: json['currentSemesterId']?.toString(),
      enrolledCourseIds: List<String>.from(json['enrolledCourseIds'] ?? []),
      taughtCourseIds: List<String>.from(json['taughtCourseIds'] ?? []),
      isActive: json['isActive'] is bool ? json['isActive'] : (json['isActive'] == 1 || json['isActive'] == null),// Mặc định là true nếu không có trường này trong JSON hoặc nếu giá trị là 1
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'role': role,
      'identity': identity,
      'currentSemesterId': currentSemesterId,
      'enrolledCourseIds': enrolledCourseIds,
      'taughtCourseIds': taughtCourseIds,
      'isActive': isActive, // Trạng thái hoạt động của người dùng
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? role,
    String? identity,
    String? currentSemesterId,
    List<String>? enrolledCourseIds,
    List<String>? taughtCourseIds,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      identity: identity ?? this.identity,
      currentSemesterId: currentSemesterId ?? this.currentSemesterId,
      enrolledCourseIds: enrolledCourseIds ?? this.enrolledCourseIds,
      taughtCourseIds: taughtCourseIds ?? this.taughtCourseIds,
      isActive: isActive ?? this.isActive, // Trạng thái hoạt động của người dùng
    );
  }
}
