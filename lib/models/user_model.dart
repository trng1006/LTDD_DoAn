class UserModel {
  final String id;
  final String username; // Added username
  final String email;
  final String name;
  final String role; // student, lecturer, admin
  final List<String> enrolledCourseIds; 
  final List<String> taughtCourseIds; 
  final String? currentSemesterId; 

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    this.enrolledCourseIds = const [],
    this.taughtCourseIds = const [],
    this.currentSemesterId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? json['id'] ?? '', // Fallback to id if username missing
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      enrolledCourseIds: List<String>.from(json['enrolledCourseIds'] ?? []),
      taughtCourseIds: List<String>.from(json['taughtCourseIds'] ?? []),
      currentSemesterId: json['currentSemesterId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'role': role,
      'enrolledCourseIds': enrolledCourseIds,
      'taughtCourseIds': taughtCourseIds,
      'currentSemesterId': currentSemesterId,
    };
  }
}
