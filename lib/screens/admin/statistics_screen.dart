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
                        // Metrics Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: [
                            _statCard(
                              'Tổng số nhóm',
                              '$_totalGroups',
                              [const Color(0xFF64B5F6), const Color(0xFF1E88E5)],
                              Icons.groups_rounded,
                            ),
                            _statCard(
                              'Đã chốt đề tài',
                              '$_groupsWithTopic',
                              [const Color(0xFF81C784), const Color(0xFF388E3C)],
                              Icons.assignment_turned_in_rounded,
                            ),
                            _statCard(
                              'Tổng số đề tài',
                              '$_totalTopics',
                              [const Color(0xFFFFB74D), const Color(0xFFF57C00)],
                              Icons.topic_rounded,
                            ),
                            _statCard(
                              'Chưa có ai chọn',
                              '$_unregisteredTopics',
                              [const Color(0xFFE57373), const Color(0xFFD32F2F)],
                              Icons.warning_amber_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Icon(Icons.leaderboard_rounded, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Đề tài được quan tâm nhất',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
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

  Widget _statCard(String title, String value, List<Color> colors, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 80,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicStat(String name, int count, int rank) {
    Color rankColor;
    IconData? rankIcon;
    
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.workspace_premium;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = Colors.grey.shade400;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: rankColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: rankIcon != null 
              ? Icon(rankIcon, color: rankColor, size: 24)
              : Text(
                  '$rank',
                  style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF2D3142),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _totalGroups > 0 ? (count / _totalGroups).clamp(0.0, 1.0) : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count nhóm',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}