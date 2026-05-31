import 'package:flutter/material.dart';
import '../models/topic_model.dart';
import '../core/services/api_service.dart';

class TopicProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<TopicModel> _topics = [];
  bool _isLoading = false;

  List<TopicModel> get topics => _topics;
  bool get isLoading => _isLoading;

  TopicProvider() {
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    _isLoading = true;
    notifyListeners();
    _topics = await _apiService.getTopics();
    _isLoading = false;
    notifyListeners();
  }

  /// Lấy danh sách đề tài còn chỗ (dùng cho màn hình Chọn đề tài).
  Future<List<TopicModel>> getAvailableTopics({String? courseId}) async {
    return _apiService.getAvailableTopics(courseId: courseId);
  }

  /// Lấy TẤT CẢ đề tài của một môn học (cả còn trống lẫn đã đầy).
  /// Dùng cho màn hình Chọn đề tài để hiển thị "số đề tài có thể chọn / tổng số đề tài".
  Future<List<TopicModel>> getTopicsByCourse(String courseId) async {
    final all = await _apiService.getTopics();
    return all.where((t) => t.courseId == courseId).toList();
  }

  Future<void> addTopic(TopicModel topic) async {
    _isLoading = true;
    notifyListeners();
    bool success = await _apiService.createTopic(topic);
    if (success) {
      await fetchTopics(); // Reload from server to get correct ID and data
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTopic(TopicModel topic) async {
    _isLoading = true;
    notifyListeners();
    bool success = await _apiService.updateTopic(topic);
    if (success) {
      await fetchTopics();
    }
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> deleteTopic(String id) async {
    _isLoading = true;
    notifyListeners();
    bool success = await _apiService.deleteTopic(id);
    if (success) {
      _topics.removeWhere((t) => t.id == id);
    }
    _isLoading = false;
    notifyListeners();
  }
}
