import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Import các Provider trong dự án của bạn
import '../../providers/user_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/topic_provider.dart';
import '../../providers/course_provider.dart'; // THÊM DÒNG NÀY

// Import các màn hình để điều hướng
import 'manage_students_screen.dart';
import 'statistics_screen.dart';
import 'system_settings_screen.dart';
import 'manage_courses_screen.dart'; // THÊM DÒNG NÀY

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu động từ các Provider thực tế trong project của bạn
    final userProvider = context.watch<UserProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final topicProvider = context.watch<TopicProvider>();
    final courseProvider = context.watch<CourseProvider>(); // THÊM DÒNG NÀY

    // Tính toán số lượng thực tế
    final totalStudents = userProvider.users.where((u) => u.role == 'student').length;
    final totalTopics = topicProvider.topics.length; 
    final totalGroups = groupProvider.groups.length; 
    final totalCourses = courseProvider.courses.length; // THÊM DÒNG NÀY
    
    // Giả định các nhóm hoặc đề tài có thuộc tính status == 'pending'
    final pendingApprovals = groupProvider.groups.where((g) => g.status == 'pending').length; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SystemSettingsScreen()),
            ),
          )
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildStatCard(
            context, 
            'Sinh viên & GV', 
            '$totalStudents', 
            Icons.people,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageStudentsScreen())),
          ),
          // THÊM THẺ MỚI: QUẢN LÝ MÔN HỌC & HỌC KỲ
          _buildStatCard(
            context, 
            'Môn học', 
            '$totalCourses', 
            Icons.menu_book_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageCoursesScreen())),
          ),
          _buildStatCard(
            context, 
            'Đề tài', 
            '$totalTopics', 
            Icons.book,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen())), 
          ),
          _buildStatCard(
            context, 
            'Nhóm', 
            '$totalGroups', 
            Icons.group,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen())),
          ),
          _buildStatCard(
            context, 
            'Chờ duyệt', 
            '$pendingApprovals', 
            Icons.pending_actions,
            () {
              _showPendingApprovalsDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String count, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell( 
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showPendingApprovalsDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng điều hướng duyệt yêu cầu đang được xử lý!'))
    );
  }
}