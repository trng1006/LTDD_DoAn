import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _notifTile(
            'Hệ thống',
            'Chúc mừng! Đề tài của nhóm bạn đã được giảng viên phê duyệt.',
            '10 phút trước',
            Icons.check_circle,
            Colors.green,
          ),
          _notifTile(
            'Giảng viên',
            'Giảng viên đã phản hồi yêu cầu của bạn: Vui lòng bổ sung mô tả chi tiết.',
            '2 giờ trước',
            Icons.message,
            Colors.blue,
          ),
          _notifTile(
            'Nhóm',
            'Sinh viên sv05 đã gửi yêu cầu gia nhập nhóm của bạn.',
            'Hôm qua',
            Icons.person_add,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _notifTile(String title, String body, String time, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
