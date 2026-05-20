import 'package:flutter/material.dart';

class ManageStudentsScreen extends StatelessWidget {
  const ManageStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Người dùng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _userTile('Nguyễn Văn A', 'sv01@gmail.com', 'Sinh viên', true),
          _userTile('Trần Thị B', 'gv01@gmail.com', 'Giảng viên', true),
          _userTile('Lê Văn C', 'sv99@gmail.com', 'Sinh viên', false),
          _userTile('Hoàng Thị D', 'gv02@gmail.com', 'Giảng viên', true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _userTile(String name, String email, String role, bool isActive) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(name[0])),
        title: Text(name),
        subtitle: Text('$email - $role'),
        trailing: Switch(value: isActive, onChanged: (val) {}),
      ),
    );
  }
}
