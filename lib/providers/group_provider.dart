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

  Future<void> createGroup(String name, String description, int maxMembers, String leaderId) async {
    _isLoading = true;
    notifyListeners();
    
    // In a real app, call API here
    final newGroup = GroupModel(
      id: 'g${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      maxMembers: maxMembers,
      memberIds: [leaderId],
      pendingMemberIds: [],
      leaderId: leaderId,
    );
    _groups.add(newGroup);
    
    _isLoading = false;
    notifyListeners();
  }

  void requestToJoin(String groupId, String userId) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _groups[index];
      if (!group.pendingMemberIds.contains(userId) && !group.memberIds.contains(userId)) {
        _groups[index] = group.copyWith(
          pendingMemberIds: [...group.pendingMemberIds, userId],
        );
        notifyListeners();
      }
    }
  }

  void acceptMember(String groupId, String userId) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _groups[index];
      final newPending = group.pendingMemberIds.where((id) => id != userId).toList();
      if (!group.memberIds.contains(userId)) {
        _groups[index] = group.copyWith(
          memberIds: [...group.memberIds, userId],
          pendingMemberIds: newPending,
        );
        notifyListeners();
      }
    }
  }

  void rejectMember(String groupId, String userId) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _groups[index];
      _groups[index] = group.copyWith(
        pendingMemberIds: group.pendingMemberIds.where((id) => id != userId).toList(),
      );
      notifyListeners();
    }
  }

  void removeMember(String groupId, String userId) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _groups[index];
      _groups[index] = group.copyWith(
        memberIds: group.memberIds.where((id) => id != userId).toList(),
      );
      notifyListeners();
    }
  }

  void updateGroupSize(String groupId, int size) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(maxMembers: size);
      notifyListeners();
    }
  }

  void updateGroupStatus(String groupId, String status, {bool? isLocked}) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(
        status: status,
        isLocked: isLocked,
      );
      notifyListeners();
    }
  }

  Future<void> updateGroup(GroupModel group) async {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
      notifyListeners();
    }
  }
}
