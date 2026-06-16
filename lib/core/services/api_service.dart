import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../models/topic_model.dart';
import '../../models/group_model.dart';
import '../../models/notification_model.dart';

class ApiService {
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Tự động chọn địa chỉ backend theo nền tảng đang chạy:
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:8000';
    }
  }

  // --- Auth & Users ---
  Future<UserModel?> login(String identity, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identity': identity, 'password': password}),
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Login Error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String identity,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': identity,
          'name': name,
          'email': email,
          'password': password,
          'role': 'student',
          'identity': identity,
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': UserModel.fromJson(responseData)};
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      debugPrint('Register Error: $e');
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ'};
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update User Error: $e');
      return false;
    }
  }

  Future<List<UserModel>> getUsers({String? role}) async {
    try {
      final url = role != null ? '$baseUrl/users?role=$role' : '$baseUrl/users';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((u) => UserModel.fromJson(u)).toList();
      }
    } catch (e) {
      debugPrint('Get Users Error: $e');
    }
    return [];
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete User Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final url = '$baseUrl/change-password';
      final body = jsonEncode({
        'user_id': userId,
        'old_password': oldPassword,
        'new_password': newPassword,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Đổi mật khẩu thành công',
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Đổi mật khẩu thất bại',
        };
      }
    } catch (e) {
      debugPrint('Change Password Error: $e');
      return {'success': false, 'message': 'Lỗi kết nối máy chủ'};
    }
  }

  // --- Topics ---
  Future<List<TopicModel>> getTopics({String? lecturerId}) async {
    try {
      final url = lecturerId != null
          ? '$baseUrl/topics?lecturer_id=$lecturerId'
          : '$baseUrl/topics';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((t) => TopicModel.fromJson(t)).toList();
      }
    } catch (e) {
      debugPrint('Get Topics Error: $e');
    }
    return [];
  }

  Future<TopicModel?> getTopicById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/topics/$id'));
      if (response.statusCode == 200) {
        return TopicModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Get Topic By Id Error: $e');
    }
    return null;
  }

  Future<bool> createTopic(TopicModel topic) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/topics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(topic.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Create Topic Error: $e');
      return false;
    }
  }

  Future<bool> updateTopic(TopicModel topic) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/topics/${topic.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(topic.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Topic Error: $e');
      return false;
    }
  }

  Future<bool> deleteTopic(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/topics/$id'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete Topic Error: $e');
      return false;
    }
  }

  /// Danh sách đề tài còn chỗ để nhóm đăng ký.
  Future<List<TopicModel>> getAvailableTopics({String? courseId}) async {
    try {
      final params = <String, String>{};
      if (courseId != null && courseId.isNotEmpty) {
        params['course_id'] = courseId;
      }
      final uri = Uri.parse(
        '$baseUrl/topics/available',
      ).replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((t) => TopicModel.fromJson(t)).toList();
      }
    } catch (e) {
      debugPrint('Get Available Topics Error: $e');
    }
    return [];
  }

  /// Trưởng nhóm đăng ký đề tài cho nhóm.
  /// Trả về null nếu thành công, hoặc chuỗi thông báo lỗi từ backend.
  Future<String?> registerTopic(
    String groupId,
    String topicId,
    String leaderId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/register-topic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'topicId': topicId, 'leaderId': leaderId}),
      );
      if (response.statusCode == 200) return null;
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return body['detail']?.toString() ?? 'Đăng ký đề tài thất bại.';
      } catch (_) {
        return 'Đăng ký đề tài thất bại.';
      }
    } catch (e) {
      debugPrint('Register Topic Error: $e');
      return 'Không thể kết nối tới máy chủ.';
    }
  }

  // --- Groups ---
  Future<List<GroupModel>> getGroups({
    String? courseId,
    String? search,
    String? topicId,
    String? lecturerId,
    String? status,
  }) async {
    try {
      final params = <String, String>{};
      if (courseId != null && courseId.isNotEmpty) {
        params['course_id'] = courseId;
      }
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (topicId != null && topicId.isNotEmpty) params['topic_id'] = topicId;
      if (lecturerId != null && lecturerId.isNotEmpty) {
        params['lecturer_id'] = lecturerId;
      }
      if (status != null && status.isNotEmpty) params['status'] = status;
      final uri = Uri.parse(
        '$baseUrl/groups',
      ).replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((g) => GroupModel.fromJson(g)).toList();
      }
    } catch (e) {
      debugPrint('Get Groups Error: $e');
    }
    return [];
  }

  Future<GroupModel?> getGroupById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/groups/$id'));
      if (response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Get Group By Id Error: $e');
    }
    return null;
  }

  /// Tạo nhóm. Trả về Map: { 'error': String? , 'id': String? }.
  /// error == null nghĩa là thành công.
  Future<Map<String, String?>> createGroup(GroupModel group) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(group.toJson()),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return {'error': null, 'id': body['id']?.toString()};
      }
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'error': body['detail']?.toString() ?? 'Tạo nhóm thất bại.',
          'id': null,
        };
      } catch (_) {
        return {'error': 'Tạo nhóm thất bại.', 'id': null};
      }
    } catch (e) {
      debugPrint('Create Group Error: $e');
      return {'error': 'Không thể kết nối tới máy chủ.', 'id': null};
    }
  }

  Future<bool> updateGroup(GroupModel group) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/groups/${group.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(group.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Group Error: $e');
      return false;
    }
  }

  Future<bool> deleteGroup(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/groups/$id'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete Group Error: $e');
      return false;
    }
  }

  /// Gửi yêu cầu gia nhập nhóm.
  /// Trả về null nếu thành công, hoặc chuỗi thông báo lỗi từ backend nếu thất bại.
  Future<String?> joinGroup(String groupId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      if (response.statusCode == 200) return null;
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return body['detail']?.toString() ?? 'Gửi yêu cầu thất bại.';
      } catch (_) {
        return 'Gửi yêu cầu thất bại.';
      }
    } catch (e) {
      debugPrint('Join Group Error: $e');
      return 'Không thể kết nối tới máy chủ.';
    }
  }

  
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

  Future<bool> approveMember(String groupId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/approve-member'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Approve Member Error: $e');
      return false;
    }
  }

  Future<bool> removeMember(String groupId, String userId, {String? reason}) async {
    try {
      final uri = Uri.parse('$baseUrl/groups/$groupId/members/$userId').replace(
        queryParameters: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
      );
      final response = await http.delete(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Remove Member Error: $e');
      return false;
    }
  }

  Future<String?> approveTopicRegistration(
    String groupId,
    String lecturerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/approve-topic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lecturer_id': lecturerId}),
      );
      if (response.statusCode == 200) return null;
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return body['detail']?.toString() ?? 'Duyet de tai that bai.';
      } catch (_) {
        return 'Duyet de tai that bai.';
      }
    } catch (e) {
      debugPrint('Approve Topic Error: $e');
      return 'Khong the ket noi toi may chu.';
    }
  }

  Future<String?> rejectTopicRegistration(
    String groupId,
    String lecturerId, {
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{'lecturer_id': lecturerId};
      if (reason != null && reason.isNotEmpty) body['reason'] = reason;
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/reject-topic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) return null;
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['detail']?.toString() ?? 'Tu choi de tai that bai.';
      } catch (_) {
        return 'Tu choi de tai that bai.';
      }
    } catch (e) {
      debugPrint('Reject Topic Error: $e');
      return 'Khong the ket noi toi may chu.';
    }
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/notifications',
      ).replace(queryParameters: {'user_id': userId});
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((n) => NotificationModel.fromJson(n)).toList();
      }
    } catch (e) {
      debugPrint('Get Notifications Error: $e');
    }
    return [];
  }

  Future<bool> markNotificationRead(String id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Mark Notification Read Error: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsRead(String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Mark All Notifications Read Error: $e');
      return false;
    }
  }
}
