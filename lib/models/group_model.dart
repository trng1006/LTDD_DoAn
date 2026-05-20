class GroupModel {
  final String id;
  final String name;
  final String description;
  final int maxMembers;
  final List<String> memberIds;
  final List<String> pendingMemberIds; // Added for flowchart step 5
  final String leaderId;
  final String? topicId;
  final String status; // 'creating', 'pending_approval', 'approved'
  final bool isLocked; // Added for flowchart step 14

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.maxMembers,
    required this.memberIds,
    required this.pendingMemberIds,
    required this.leaderId,
    this.topicId,
    this.status = 'creating',
    this.isLocked = false,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      maxMembers: json['maxMembers'] ?? 5,
      memberIds: List<String>.from(json['memberIds'] ?? []),
      pendingMemberIds: List<String>.from(json['pendingMemberIds'] ?? []),
      leaderId: json['leaderId'] ?? '',
      topicId: json['topicId'],
      status: json['status'] ?? 'creating',
      isLocked: json['isLocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'maxMembers': maxMembers,
      'memberIds': memberIds,
      'pendingMemberIds': pendingMemberIds,
      'leaderId': leaderId,
      'topicId': topicId,
      'status': status,
      'isLocked': isLocked,
    };
  }

  GroupModel copyWith({
    String? name,
    String? description,
    int? maxMembers,
    List<String>? memberIds,
    List<String>? pendingMemberIds,
    String? topicId,
    String? status,
    bool? isLocked,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      maxMembers: maxMembers ?? this.maxMembers,
      memberIds: memberIds ?? this.memberIds,
      pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,
      leaderId: leaderId,
      topicId: topicId ?? this.topicId,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
