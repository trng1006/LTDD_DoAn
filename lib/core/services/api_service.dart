import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../models/topic_model.dart';
import '../../models/group_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // IP mặc định cho Android Emulator kết nối tới localhost

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
}
