import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/core/constants/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      // Should not happen, but just in case
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Xin chào, ${user.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vai trò: ${user.role == 'student' ? 'Sinh viên' : user.role == 'lecturer' ? 'Giảng viên' : 'Admin'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            if (user.role == 'student') ...[
              _buildActionCard(context, 'Nhóm của tôi', Icons.group, () {
                Navigator.pushNamed(context, AppRoutes.manageGroup);
              }),
              _buildActionCard(context, 'Đăng ký đề tài', Icons.library_books, () {}),
            ] else if (user.role == 'lecturer') ...[
              _buildActionCard(context, 'Quản lý đề tài', Icons.list_alt, () {}),
              _buildActionCard(context, 'Duyệt đăng ký', Icons.check_circle_outline, () {}),
            ] else ...[
              _buildActionCard(context, 'Quản lý người dùng', Icons.manage_accounts, () {}),
              _buildActionCard(context, 'Thống kê', Icons.bar_chart, () {}),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
