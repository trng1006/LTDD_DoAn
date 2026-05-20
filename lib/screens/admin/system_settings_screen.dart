import 'package:flutter/material.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình hệ thống')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingSection('Thời gian đăng ký', [
            _settingTile('Ngày bắt đầu', '01/05/2026', Icons.calendar_today),
            _settingTile('Ngày kết thúc', '30/06/2026', Icons.calendar_month),
          ]),
          const SizedBox(height: 24),
          _settingSection('Quy định nhóm', [
            _settingTile('Số thành viên tối thiểu', '3 người', Icons.person),
            _settingTile('Số thành viên tối đa', '5 người', Icons.people),
          ]),
          const SizedBox(height: 24),
          _settingSection('Bảo mật', [
            _settingTile('Yêu cầu xác thực 2 lớp', 'Đã tắt', Icons.security),
            _settingTile('Thời gian phiên đăng nhập', '24 giờ', Icons.timer),
          ]),
        ],
      ),
    );
  }

  Widget _settingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
        const SizedBox(height: 8),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.grey)),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
      onTap: () {},
    );
  }
}
