class UserModel {
  final String id;
  final String username;
  final String name;
  final String email;
  final String role;
  final String? identity; 
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

  // Hàm chuyển từ Map (JSON) sang UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      identity: json['identity'], 
      currentSemesterId: json['currentSemesterId'],
      enrolledCourseIds: List<String>.from(json['enrolledCourseIds'] ?? []),
      taughtCourseIds: List<String>.from(json['taughtCourseIds'] ?? []),
    );
  }

  // Hàm chuyển từ UserModel sang Map (JSON)
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
}