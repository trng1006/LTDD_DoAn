import 'package:flutter/material.dart';
import '../models/topic_model.dart';

class TopicProvider with ChangeNotifier {
  List<TopicModel> _topics = [];
  bool _isLoading = false;

  List<TopicModel> get topics => _topics;
  bool get isLoading => _isLoading;

  Future<void> fetchTopics() async {
    _isLoading = true;
    notifyListeners();

    // Mock fetching topics
    await Future.delayed(const Duration(seconds: 1));
    _topics = [
      TopicModel(
        id: '1',
        title: 'Mobile App Development',
        description: 'Build a Flutter app',
        lecturerId: 'lecturer1',
        maxGroups: 5,
      ),
      TopicModel(
        id: '2',
        title: 'Web Development',
        description: 'Build a React app',
        lecturerId: 'lecturer2',
        maxGroups: 3,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }
}
