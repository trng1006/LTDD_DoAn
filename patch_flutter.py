import re

# 1. Update group_model.dart
path_model = "lib/models/group_model.dart"
with open(path_model, "r") as f:
    content = f.read()

content = content.replace("final List<String> pendingMemberIds;", "final List<String> pendingMemberIds;\n  final List<String> invitedMemberIds;")
content = content.replace("required this.pendingMemberIds,", "required this.pendingMemberIds,\n    this.invitedMemberIds = const [],")
content = content.replace("pendingMemberIds: List<String>.from(json['pendingMemberIds'] ?? []),", "pendingMemberIds: List<String>.from(json['pendingMemberIds'] ?? []),\n      invitedMemberIds: List<String>.from(json['invitedMemberIds'] ?? []),")
content = content.replace("'pendingMemberIds': pendingMemberIds,", "'pendingMemberIds': pendingMemberIds,\n      'invitedMemberIds': invitedMemberIds,")
content = content.replace("List<String>? pendingMemberIds,", "List<String>? pendingMemberIds,\n    List<String>? invitedMemberIds,")
content = content.replace("pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,", "pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,\n      invitedMemberIds: invitedMemberIds ?? this.invitedMemberIds,")
with open(path_model, "w") as f:
    f.write(content)

# 2. Update api_service.dart
path_api = "lib/core/services/api_service.dart"
with open(path_api, "r") as f:
    content = f.read()

new_api_methods = """
  Future<bool> inviteMember(String groupId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/invite-member'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Invite Member Error: $e');
      return false;
    }
  }

  Future<bool> acceptInvite(String groupId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/accept-invite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Accept Invite Error: $e');
      return false;
    }
  }

  Future<bool> rejectInvite(String groupId, String userId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/reject-invite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'reason': reason}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Reject Invite Error: $e');
      return false;
    }
  }
"""
# Insert before "Future<bool> approveMember"
content = content.replace("Future<bool> approveMember", new_api_methods + "\n  Future<bool> approveMember")
with open(path_api, "w") as f:
    f.write(content)

# 3. Update group_provider.dart
path_provider = "lib/providers/group_provider.dart"
with open(path_provider, "r") as f:
    content = f.read()

content = content.replace(
    "g.memberIds.contains(userId) || g.pendingMemberIds.contains(userId)",
    "g.memberIds.contains(userId) || g.pendingMemberIds.contains(userId) || g.invitedMemberIds.contains(userId)"
)

new_provider_methods = """
  Future<bool> inviteMember(String groupId, String userId) async {
    final success = await _apiService.inviteMember(groupId, userId);
    if (success) {
      await fetchGroups();
    }
    return success;
  }

  Future<bool> acceptInvite(String groupId, String userId) async {
    final success = await _apiService.acceptInvite(groupId, userId);
    if (success) {
      await fetchGroups();
    }
    return success;
  }

  Future<bool> rejectInvite(String groupId, String userId, String reason) async {
    final success = await _apiService.rejectInvite(groupId, userId, reason);
    if (success) {
      await fetchGroups();
    }
    return success;
  }
"""
content = content.replace("Future<bool> acceptMember", new_provider_methods + "\n  Future<bool> acceptMember")
with open(path_provider, "w") as f:
    f.write(content)

