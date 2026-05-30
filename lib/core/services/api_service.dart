import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../models/topic_model.dart';
import '../../models/group_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000'; // IP mặc định cho Android Emulator

  // --- Auth ---
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

  // --- Topics ---
  Future<List<TopicModel>> getTopics() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/topics'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((t) => TopicModel.fromJson(t)).toList();
      }
    } catch (e) {
      debugPrint('Get Topics Error: $e');
    }
    return [];
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
  Future<List<GroupModel>> getGroups() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/groups'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((g) => GroupModel.fromJson(g)).toList();
      }
    } catch (e) {
      debugPrint('Get Groups Error: $e');
    }
    return [];
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
