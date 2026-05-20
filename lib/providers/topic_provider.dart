import 'package:flutter/material.dart';
import '../models/topic_model.dart';

class TopicProvider with ChangeNotifier {
  List<TopicModel> _topics = [];
  bool _isLoading = false;

  List<TopicModel> get topics => _topics;
  bool get isLoading => _isLoading;

  TopicProvider() {
    _fetchMockTopics();
  }

  void _fetchMockTopics() {
    final now = DateTime.now();
    _topics = [
      TopicModel(
        id: 't1',
        title: 'Ứng dụng Flutter trong quản lý học tập',
        description: 'Xây dựng ứng dụng mobile hỗ trợ sinh viên quản lý thời khóa biểu, điểm số và bài tập về nhà bằng Flutter và Firebase.',
        maxGroups: 3,
        currentGroups: 2,
        lecturerId: 'gv01',
        startTime: now.subtract(const Duration(days: 5)),
        endTime: now.add(const Duration(days: 10)),
      ),
      TopicModel(
        id: 't2',
        title: 'Xây dựng hệ thống Chatbot AI hỗ trợ tuyển sinh',
        description: 'Phát triển Chatbot sử dụng NLP để giải đáp các thắc mắc của thí sinh về quy trình tuyển sinh và các ngành đào tạo.',
        maxGroups: 2,
        currentGroups: 0,
        lecturerId: 'gv01',
        startTime: now.add(const Duration(days: 2)), // Scheduled for future
        endTime: now.add(const Duration(days: 15)),
      ),
      TopicModel(
        id: 't3',
        title: 'Phát triển ví điện tử tích hợp thanh toán QR',
        description: 'Thiết kế giao diện và luồng thanh toán cho ứng dụng ví điện tử, hỗ trợ quét mã QR và quản lý giao dịch.',
        maxGroups: 5,
        currentGroups: 1,
        lecturerId: 'gv02',
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 20)),
      ),
      TopicModel(
        id: 't4',
        title: 'Hệ thống quản lý bãi xe thông minh',
        description: 'Sử dụng IoT và Mobile App để nhận diện biển số và quản lý vị trí đỗ xe trống trong thời gian thực.',
        maxGroups: 2,
        currentGroups: 2,
        lecturerId: 'gv02',
        startTime: now.subtract(const Duration(days: 10)),
        endTime: now.subtract(const Duration(days: 1)), // Already ended
      ),
    ];
    notifyListeners();
  }

  Future<void> addTopic(TopicModel topic) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _topics.add(topic);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTopic(TopicModel topic) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
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
