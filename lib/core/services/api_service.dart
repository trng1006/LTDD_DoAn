import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../models/topic_model.dart';
import '../../models/group_model.dart';

class ApiService {
  // Tự động nhận diện môi trường để đặt Base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
        return 'http://localhost:8000';
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

  Future<Map<String, dynamic>> register(String name, String email, String password, String identity) async {
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
          'identity': identity
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': UserModel.fromJson(responseData)};
      } else {
        return {'success': false, 'message': responseData['detail'] ?? 'Đăng ký thất bại'};
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

  Future<Map<String, dynamic>> changePassword(String userId, String oldPassword, String newPassword) async {
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
        return {'success': true, 'message': responseData['message'] ?? 'Đổi mật khẩu thành công'};
      } else {
        return {'success': false, 'message': responseData['detail'] ?? 'Đổi mật khẩu thất bại'};
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

  // --- Groups ---
  Future<List<GroupModel>> getGroups({String? topicId}) async {
    try {
      final url = topicId != null 
          ? '$baseUrl/groups?topic_id=$topicId' 
          : '$baseUrl/groups';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
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

  Future<bool> createGroup(GroupModel group) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(group.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Create Group Error: $e');
      return false;
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

  Future<bool> joinGroup(String groupId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Join Group Error: $e');
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

  Future<bool> removeMember(String groupId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/groups/$groupId/members/$userId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Remove Member Error: $e');
      return false;
    }
  }
}
