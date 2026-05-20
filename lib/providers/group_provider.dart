import 'package:flutter/material.dart';
import '../models/group_model.dart';

class GroupProvider with ChangeNotifier {
  List<GroupModel> _groups = [];
  bool _isLoading = false;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;

  GroupProvider() {
    _fetchMockGroups();
  }

  void _fetchMockGroups() {
    _groups = [
      GroupModel(
        id: 'g1',
        name: 'Nhóm 01 - Flutter App',
        description: 'Nhóm làm đề tài ứng dụng Flutter quản lý học tập',
        maxMembers: 5,
        memberIds: ['sv01', 's2', 's7'],
        pendingMemberIds: ['s5', 's6'],
        leaderId: 'sv01',
        status: 'pending_approval',
        topicId: 't1',
      ),
      GroupModel(
        id: 'g2',
        name: 'Nhóm 02 - AI Team',
        description: 'Nhóm làm đề tài Chatbot AI',
        maxMembers: 4,
        memberIds: ['s3', 's4', 's8'],
        pendingMemberIds: [],
        leaderId: 's3',
        status: 'approved',
        topicId: 't2',
        isLocked: true,
      ),
    ];
    notifyListeners();
  }

  Future<void> createGroup(String name, String description, int maxMembers, String leaderId) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    final newGroup = GroupModel(
      id: 'g${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      maxMembers: maxMembers,
      memberIds: [leaderId],
      pendingMemberIds: [],
      leaderId: leaderId,
      status: 'creating',
    );
    _groups.add(newGroup);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> requestToJoin(String groupId, String userId) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      if (!_groups[index].pendingMemberIds.contains(userId) && !_groups[index].memberIds.contains(userId)) {
        _groups[index].pendingMemberIds.add(userId);
        notifyListeners();
      }
    }
  }

  Future<void> acceptMember(String groupId, String userId) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index].pendingMemberIds.remove(userId);
      if (_groups[index].memberIds.length < _groups[index].maxMembers) {
        if (!_groups[index].memberIds.contains(userId)) {
          _groups[index].memberIds.add(userId);
        }
      }
      notifyListeners();
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index].memberIds.remove(userId);
      notifyListeners();
    }
  }

  Future<void> rejectMember(String groupId, String userId) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index].pendingMemberIds.remove(userId);
      notifyListeners();
    }
  }

  void updateGroupStatus(String groupId, String status, {bool? isLocked}) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(status: status, isLocked: isLocked);
      notifyListeners();
    }
  }

  void updateGroupSize(String groupId, int newSize) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(maxMembers: newSize);
      notifyListeners();
    }
  }
}
