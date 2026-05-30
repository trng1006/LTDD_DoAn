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

  Future<void> fetchGroups({String? courseId}) async {
    _isLoading = true;
    notifyListeners();
    _groups = await _apiService.getGroups(courseId: courseId);
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> createGroup(
    String name,
    String description,
    String courseId,
    int maxMembers,
    String leaderId,
    String? topicId, {
    int minMembers = 2,
  }) async {
    _isLoading = true;
    notifyListeners();

    final newGroup = GroupModel(
      id: '',
      name: name,
      description: description,
      maxMembers: maxMembers,
      minMembers: minMembers,
      memberIds: [leaderId],
      pendingMemberIds: [],
      leaderId: leaderId,
      topicId: topicId,
      courseId: courseId,
    );

    final result = await _apiService.createGroup(newGroup);
    _isLoading = false;
    notifyListeners();

    if (result['error'] == null) {
      await fetchGroups(courseId: courseId);
      return null;
    }
    return result['error'];
  }

  Future<String?> requestToJoin(String groupId, String userId) async {
    final error = await _apiService.joinGroup(groupId, userId);
    if (error == null) {
      await fetchGroups();
    }
    return error;
  }

  Future<void> acceptMember(String groupId, String userId) async {
    bool success = await _apiService.approveMember(groupId, userId);
    if (success) await fetchGroups();
  }

  Future<void> rejectMember(String groupId, String userId) async {
    bool success = await _apiService.removeMember(groupId, userId);
    if (success) await fetchGroups();
  }

  Future<void> removeMember(String groupId, String userId) async {
    bool success = await _apiService.removeMember(groupId, userId);
    if (success) await fetchGroups();
  }

  Future<void> updateGroupStatus(String groupId, String status, {bool? isLocked}) async {
    final group = _groups.firstWhere((g) => g.id == groupId);
    final updatedGroup = group.copyWith(status: status, isLocked: isLocked);
    bool success = await _apiService.updateGroup(updatedGroup);
    if (success) await fetchGroups();
  }

  Future<void> updateGroupSize(String groupId, int size) async {
    final group = _groups.firstWhere((g) => g.id == groupId);
    final updatedGroup = group.copyWith(maxMembers: size);
    bool success = await _apiService.updateGroup(updatedGroup);
    if (success) await fetchGroups();
  }

  Future<void> updateGroup(GroupModel group) async {
    bool success = await _apiService.updateGroup(group);
    if (success) await fetchGroups();
  }

  GroupModel? groupOfUserInCourse(String userId, String courseId) {
    try {
      return _groups.firstWhere((g) => g.courseId == courseId && g.memberIds.contains(userId));
    } catch (_) {
      return null;
    }
  }

  bool isInAnyGroup(String userId) {
    return _groups.any((g) => g.memberIds.contains(userId));
  }

  Future<List<GroupModel>> searchGroups({String? search, String? courseId}) async {
    _isLoading = true;
    notifyListeners();
    final results = await _apiService.getGroups(
      search: search,
      courseId: courseId,
    );
    _groups = results;
    _isLoading = false;
    notifyListeners();
    return results;
  }

  Future<String?> registerTopic(String groupId, String topicId, String leaderId) async {
    return await _apiService.registerTopic(groupId, topicId, leaderId);
  }
}