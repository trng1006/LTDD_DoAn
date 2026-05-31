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

  Future<void> fetchTopics({String? lecturerId}) async {
    _isLoading = true;
    notifyListeners();
    _topics = await _apiService.getTopics(lecturerId: lecturerId);
    _isLoading = false;
    notifyListeners();
  }

  /// Lấy danh sách đề tài còn chỗ (dùng cho màn hình Chọn đề tài).
  Future<List<TopicModel>> getAvailableTopics({String? courseId}) async {
    return _apiService.getAvailableTopics(courseId: courseId);
  }

  Future<bool> addTopic(TopicModel topic, {String? lecturerId}) async {
    _isLoading = true;
    notifyListeners();
    bool success = await _apiService.createTopic(topic);
    if (success) {
      await fetchTopics(lecturerId: lecturerId);
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateTopic(TopicModel topic, {String? lecturerId}) async {
    _isLoading = true;
    notifyListeners();
    bool success = await _apiService.updateTopic(topic);
    if (success) {
      await fetchTopics(lecturerId: lecturerId);
    }
    _isLoading = false;
    notifyListeners();
    return success;
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
