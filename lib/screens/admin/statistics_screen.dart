import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê hệ thống')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statCard('Tổng số nhóm', '24', Colors.blue),
                _statCard('Đã chốt đề tài', '18', Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statCard('Tổng số đề tài', '45', Colors.orange),
                _statCard('Chưa đăng ký', '6', Colors.red),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Top Đề tài được quan tâm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _topicStat('Ứng dụng Flutter trong quản lý học tập', 8),
            _topicStat('Xây dựng hệ thống Chatbot AI', 6),
            _topicStat('Phát triển ví điện tử trên Mobile', 5),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
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

  Widget _topicStat(String name, int count) {
    return ListTile(
      leading: const Icon(Icons.star, color: Colors.amber),
      title: Text(name),
      trailing: Text('$count nhóm', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
