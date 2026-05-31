class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String userId;
  final String type;
  final Map<String, dynamic> data;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.userId,
    this.type = 'general',
    this.data = const {},
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      userId: json['userId'] ?? '',
      type: json['type']?.toString() ?? 'general',
      data: Map<String, dynamic>.from(json['data'] ?? const {}),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'type': type,
      'data': data,
      'isRead': isRead,
    };
  }
}
