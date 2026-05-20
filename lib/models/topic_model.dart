class TopicModel {
  final String id;
  final String title;
  final String description;
  final String lecturerId;
  final int maxGroups;
  final int currentGroups;
  final DateTime startTime; // Added for scheduling
  final DateTime endTime;   // Added for deadline

  TopicModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lecturerId,
    required this.maxGroups,
    this.currentGroups = 0,
    required this.startTime,
    required this.endTime,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      lecturerId: json['lecturerId'] ?? '',
      maxGroups: json['maxGroups'] ?? 1,
      currentGroups: json['currentGroups'] ?? 0,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : DateTime.now().add(const Duration(days: 30)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lecturerId': lecturerId,
      'maxGroups': maxGroups,
      'currentGroups': currentGroups,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  TopicModel copyWith({
    String? title,
    String? description,
    int? maxGroups,
    int? currentGroups,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TopicModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      lecturerId: lecturerId,
      maxGroups: maxGroups ?? this.maxGroups,
      currentGroups: currentGroups ?? this.currentGroups,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
