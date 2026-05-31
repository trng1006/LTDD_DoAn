import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../core/services/api_service.dart';

class GroupProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<GroupModel> _groups = [];
  bool _isLoading = false;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;

  /// Nhóm mà [userId] đang tham gia (member hoặc pending) trong [courseId], nếu có.
  GroupModel? groupOfUserInCourse(String userId, String courseId) {
    for (final g in _groups) {
      if (g.courseId == courseId &&
          (g.memberIds.contains(userId) || g.pendingMemberIds.contains(userId))) {
        return g;
      }
    }
    return null;
  }

  /// Nhóm mà [userId] làm TRƯỞNG NHÓM trong [courseId], nếu có.
  /// Dùng cho màn Chọn đề tài: chỉ trưởng nhóm mới đăng ký, và phải đúng nhóm của môn đó.
  GroupModel? leaderGroupInCourse(String userId, String courseId) {
    for (final g in _groups) {
      if (g.courseId == courseId && g.leaderId == userId) {
        return g;
      }
    }
    return null;
  }

  /// Kiểm tra [userId] đã thuộc nhóm nào (bất kỳ môn) chưa.
  bool isInAnyGroup(String userId) {
    return _groups.any((g) =>
        g.memberIds.contains(userId) || g.pendingMemberIds.contains(userId));
  }

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

  /// Tìm nhóm theo môn học và/hoặc từ khoá (dùng cho màn hình Tham gia nhóm).
  /// Trả về danh sách trực tiếp, không ghi đè state của trang chủ.
  Future<List<GroupModel>> searchGroups({String? courseId, String? search}) async {
    return _apiService.getGroups(courseId: courseId, search: search);
  }

  /// Tạo nhóm. Trả về null nếu thành công, hoặc thông báo lỗi từ backend.
  Future<String?> createGroup(String name, String description, String courseId, int maxMembers, String leaderId, String? topicId) async {
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
    
    final result = await _apiService.createGroup(newGroup);
    final error = result['error'];
    if (error == null) {
      await fetchGroups();
    }
    
    _isLoading = false;
    notifyListeners();
    return error;
  }

  /// Gửi yêu cầu gia nhập. Trả về null nếu thành công, hoặc thông báo lỗi.
  Future<String?> requestToJoin(String groupId, String userId) async {
    final error = await _apiService.joinGroup(groupId, userId);
    if (error == null) {
      await fetchGroups();
    }
    return error;
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

  /// Trưởng nhóm đăng ký đề tài. Trả về null nếu thành công, hoặc thông báo lỗi.
  Future<String?> registerTopic(String groupId, String topicId, String leaderId) async {
    final error = await _apiService.registerTopic(groupId, topicId, leaderId);
    if (error == null) {
      await fetchGroups();
    }
    return error;
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
