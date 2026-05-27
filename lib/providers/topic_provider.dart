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

  Future<void> addTopic(TopicModel topic) async {
    _isLoading = true;
    notifyListeners();
    // Logic cho API sẽ được thêm sau
    _topics.add(topic);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTopic(TopicModel topic) async {
    _isLoading = true;
    notifyListeners();
    final index = _topics.indexWhere((t) => t.id == topic.id);
    if (index != -1) {
      _topics[index] = topic;
    }
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> deleteTopic(String id) async {
    _topics.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
