import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Các biến chứa dữ liệu thực tế nhận về từ API
  int _totalGroups = 0;
  int _groupsWithTopic = 0;
  int _totalTopics = 0;
  int _unregisteredTopics = 0;
  List<Map<String, dynamic>> _topTopics = [];

  @override
  void initState() {
    super.initState();
    _fetchStatisticsData();
  }

  // Hàm thực hiện gọi API từ Backend
  Future<void> _fetchStatisticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/admin/statistics'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalGroups = data['totalGroups'] ?? 0;
          _groupsWithTopic = data['groupsWithTopic'] ?? 0;
          _totalTopics = data['totalTopics'] ?? 0;
          _unregisteredTopics = data['unregisteredTopics'] ?? 0;
          _topTopics = List<Map<String, dynamic>>.from(data['topTopics'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể đồng bộ dữ liệu thống kê từ hệ thống API.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối máy chủ backend: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê hệ thống'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
            onPressed: _fetchStatisticsData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchStatisticsData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        )
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchStatisticsData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng hiển thị số liệu về Nhóm học tập
                        Row(
                          children: [
                            _statCard('Tổng số nhóm', '$_totalGroups', Colors.blue),
                            _statCard('Đã chốt đề tài', '$_groupsWithTopic', Colors.green),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Hàng hiển thị số liệu về Đề tài nghiên cứu
                        Row(
                          children: [
                            _statCard('Tổng số đề tài', '$_totalTopics', Colors.orange),
                            _statCard('Chưa có ai chọn', '$_unregisteredTopics', Colors.red),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Top Đề tài được quan tâm nhiều nhất', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        
                        // Kiểm tra nếu hệ thống chưa có ai đăng ký đề tài
                        _topTopics.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 30),
                                  child: Text('Chưa có dữ liệu đăng ký đề tài nào.', style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _topTopics.length,
                                itemBuilder: (context, index) {
                                  final item = _topTopics[index];
                                  return _topicStat(
                                    item['name'] ?? 'Không có tiêu đề', 
                                    item['count'] ?? 0,
                                    index + 1, // Thứ hạng
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
      // Đổi màu nền của Card theo màu sắc của từng loại số liệu
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topicStat(String name, int count, int rank) {
    // Đổi màu sắc Avatar biểu tượng theo thứ hạng top 1, 2, 3
    Color rankColor = Colors.grey;
    if (rank == 1) rankColor = Colors.amber;
    if (rank == 2) rankColor = Colors.blueGrey;
    if (rank == 3) rankColor = Colors.brown;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rankColor.withValues(alpha: 0.2),
          child: Text('$rank', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count nhóm', 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
      ),
    );
  }
}