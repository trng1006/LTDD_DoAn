class TopicModel {
  final String id;
  final String title;
  final String description;
  final String lecturerId;
  final int maxGroups;
  final int currentGroups;

  TopicModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lecturerId,
    required this.maxGroups,
    this.currentGroups = 0,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      lecturerId: json['lecturerId'] ?? '',
      maxGroups: json['maxGroups'] ?? 1,
      currentGroups: json['currentGroups'] ?? 0,
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
    };
  }
}
