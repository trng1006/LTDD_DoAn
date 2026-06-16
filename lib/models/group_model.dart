class GroupModel {
  final String id;
  final String name;
  final String description;
  final String courseId; // Added to associate group with a course
  final int maxMembers;
  final int minMembers;
  final List<String> memberIds;
  final List<String> pendingMemberIds;
  final List<String> invitedMemberIds; // Added for flowchart step 5
  final String leaderId;
  final String? topicId;
  final String status; // 'creating', 'pending_approval', 'approved'
  final bool isLocked; // Added for flowchart step 14

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.courseId,
    required this.maxMembers,
    this.minMembers = 2,
    required this.memberIds,
    required this.pendingMemberIds,
    this.invitedMemberIds = const [],
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
      courseId: json['courseId'] ?? '',
      maxMembers: json['maxMembers'] ?? 5,
      minMembers: json['minMembers'] ?? 2,
      memberIds: List<String>.from(json['memberIds'] ?? []),
      pendingMemberIds: List<String>.from(json['pendingMemberIds'] ?? []),
      invitedMemberIds: List<String>.from(json['invitedMemberIds'] ?? []),
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
      'courseId': courseId,
      'maxMembers': maxMembers,
      'minMembers': minMembers,
      'memberIds': memberIds,
      'pendingMemberIds': pendingMemberIds,
      'invitedMemberIds': invitedMemberIds,
      'leaderId': leaderId,
      'topicId': topicId,
      'status': status,
      'isLocked': isLocked,
    };
  }

  GroupModel copyWith({
    String? name,
    String? description,
    String? courseId,
    int? maxMembers,
    int? minMembers,
    List<String>? memberIds,
    List<String>? pendingMemberIds,
    List<String>? invitedMemberIds,
    String? topicId,
    String? status,
    bool? isLocked,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      maxMembers: maxMembers ?? this.maxMembers,
      minMembers: minMembers ?? this.minMembers,
      memberIds: memberIds ?? this.memberIds,
      pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,
      invitedMemberIds: invitedMemberIds ?? this.invitedMemberIds,
      leaderId: leaderId,
      topicId: topicId ?? this.topicId,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
