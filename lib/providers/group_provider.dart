import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../core/services/api_service.dart';

class GroupProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<GroupModel> _groups = [];
  bool _isLoading = false;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;

  GroupProvider() {
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    _isLoading = true;
    notifyListeners();
    _groups = await _apiService.getGroups();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createGroup(String name, String description, String courseId, int maxMembers, String leaderId, String? topicId) async {
    _isLoading = true;
    notifyListeners();
    
    final newGroup = GroupModel(
      id: '', // Will be assigned by backend
      name: name,
      description: description,
      courseId: courseId,
      maxMembers: maxMembers,
      memberIds: [leaderId],
      pendingMemberIds: [],
      leaderId: leaderId,
      topicId: topicId,
    );
    
    bool success = await _apiService.createGroup(newGroup);
    if (success) {
      await fetchGroups();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> requestToJoin(String groupId, String userId) async {
    bool success = await _apiService.joinGroup(groupId, userId);
    if (success) {
      await fetchGroups();
    }
  }

  Future<void> acceptMember(String groupId, String userId) async {
    bool success = await _apiService.approveMember(groupId, userId);
    if (success) {
      await fetchGroups();
    }
  }

  Future<void> rejectMember(String groupId, String userId) async {
    // In our backend, rejecting a join request is same as removing the pending member
    bool success = await _apiService.removeMember(groupId, userId);
    if (success) {
      await fetchGroups();
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    bool success = await _apiService.removeMember(groupId, userId);
    if (success) {
      await fetchGroups();
    }
  }

  Future<void> updateGroupStatus(String groupId, String status, {bool? isLocked}) async {
    final group = _groups.firstWhere((g) => g.id == groupId);
    final updatedGroup = group.copyWith(status: status, isLocked: isLocked);
    
    bool success = await _apiService.updateGroup(updatedGroup);
    if (success) {
      await fetchGroups();
    }
  }

  Future<void> updateGroupSize(String groupId, int size) async {
    final group = _groups.firstWhere((g) => g.id == groupId);
    final updatedGroup = group.copyWith(maxMembers: size);
    
    bool success = await _apiService.updateGroup(updatedGroup);
    if (success) {
      await fetchGroups();
    }
  }

  Future<void> updateGroup(GroupModel group) async {
    bool success = await _apiService.updateGroup(group);
    if (success) {
      await fetchGroups();
    }
  }
}
