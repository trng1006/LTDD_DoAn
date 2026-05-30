class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // student, lecturer, admin
  final String identity; // MSSV or Staff ID

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.identity = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      identity: json['identity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'identity': identity,
    };
  }
}
