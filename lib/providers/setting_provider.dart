import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SettingProvider extends ChangeNotifier {
  final String _baseUrl = kIsWeb ? 'http://localhost:8000' : 'http://127.0.0.1';

  String registrationStart = '01/05/2026';
  String registrationEnd = '30/06/2026';
  int minMembers = 3;
  int maxMembers = 5;
  bool isLoading = false;

  // Lấy dữ liệu từ API
  Future<void> fetchSettings() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/settings'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        registrationStart = data['registration_start'] ?? registrationStart;
        registrationEnd = data['registration_end'] ?? registrationEnd;
        minMembers = int.tryParse(data['min_members'] ?? '') ?? minMembers;
        maxMembers = int.tryParse(data['max_members'] ?? '') ?? maxMembers;
      }
    } catch (e) {
      debugPrint('Lỗi fetchSettings: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật dữ liệu qua API
  Future<bool> updateSettings({
    required String start,
    required String end,
    required int min,
    required int max,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'registration_start': start,
          'registration_end': end,
          'min_members': min,
          'max_members': max,
        }),
      );
      if (response.statusCode == 200) {
        registrationStart = start;
        registrationEnd = end;
        minMembers = min;
        maxMembers = max;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi updateSettings: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}