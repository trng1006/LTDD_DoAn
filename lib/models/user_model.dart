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
    );
  }
}
