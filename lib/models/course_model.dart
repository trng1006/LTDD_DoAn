class CourseModel {
  final String id;
  final String name;
  final String code; // e.g., COMP101
  final String semesterId; // Linked to SemesterModel

  CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.semesterId,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      semesterId: json['semesterId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'semesterId': semesterId,
    };
  }
}
