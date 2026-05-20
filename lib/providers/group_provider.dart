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
        name: 'Nhóm 01 - Lập trình di động',
        description: 'Nhóm làm đề tài ứng dụng Flutter',
        maxMembers: 5,
        memberIds: ['1', 's2'],
        leaderId: '1',
      ),
      GroupModel(
        id: 'g2',
        name: 'Nhóm 02 - Trí tuệ nhân tạo',
        description: 'Nhóm làm đề tài AI',
        maxMembers: 4,
        memberIds: ['s3', 's4'],
        leaderId: 's3',
      ),
    ];
    notifyListeners();
  }

  Future<void> createGroup(String name, String description, int maxMembers, String leaderId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Mock network delay
    final newGroup = GroupModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      maxMembers: maxMembers,
      memberIds: [leaderId],
      leaderId: leaderId,
    );

    _groups.add(newGroup);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> joinGroup(String groupId, String userId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1 && _groups[index].memberIds.length < _groups[index].maxMembers) {
      _groups[index].memberIds.add(userId);
    }
    
    _isLoading = false;
    notifyListeners();
  }
}
