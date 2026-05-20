class GroupModel {
  final String id;
  final String name;
  final String description;
  final int maxMembers;
  final List<String> memberIds;
  final String leaderId;
  final String? topicId;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.maxMembers,
    required this.memberIds,
    required this.leaderId,
    this.topicId,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      maxMembers: json['maxMembers'] ?? 5,
      memberIds: List<String>.from(json['memberIds'] ?? []),
      leaderId: json['leaderId'] ?? '',
      topicId: json['topicId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'maxMembers': maxMembers,
      'memberIds': memberIds,
      'leaderId': leaderId,
      'topicId': topicId,
    };
  }
}
