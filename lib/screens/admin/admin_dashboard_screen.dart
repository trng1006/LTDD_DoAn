import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/services/api_service.dart';

// Import các màn hình để điều hướng
import 'manage_students_screen.dart';
import 'statistics_screen.dart';
import 'system_settings_screen.dart';
import 'manage_courses_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  int _totalStudents = 0;
  int _totalLecturers = 0;
  int _totalTopics = 0;
  int _totalGroups = 0;
  int _totalCourses = 0;
  int _pendingApprovals = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/admin/dashboard-stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalStudents = data['students'] ?? 0;
          _totalLecturers = data['lecturers'] ?? 0;
          _totalTopics = data['topics'] ?? 0;
          _totalGroups = data['totalGroups'] ?? 0;
          _totalCourses = data['courses'] ?? 0;
          _pendingApprovals = data['pendingApprovals'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi fetchDashboardStats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardStats,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SystemSettingsScreen()),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardStats,
              child: GridView.count(
                padding: const EdgeInsets.all(24),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    context, 
                    'Sinh viên & GV', 
                    '${_totalStudents + _totalLecturers}', 
                    Icons.people,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageStudentsScreen())).then((_) => _fetchDashboardStats()),
                  ),
                  _buildStatCard(
                    context, 
                    'Môn học', 
                    '$_totalCourses', 
                    Icons.menu_book_rounded,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageCoursesScreen())).then((_) => _fetchDashboardStats()),
                  ),
                  _buildStatCard(
                    context, 
                    'Đề tài', 
                    '$_totalTopics', 
                    Icons.book,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen())).then((_) => _fetchDashboardStats()), 
                  ),
                  _buildStatCard(
                    context, 
                    'Nhóm', 
                    '$_totalGroups', 
                    Icons.group,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen())).then((_) => _fetchDashboardStats()),
                  ),
                  _buildStatCard(
                    context, 
                    'Chờ duyệt', 
                    '$_pendingApprovals', 
                    Icons.pending_actions,
                    () {
                      _showPendingApprovalsDialog(context);
                    },
                  ),
                ],
              ),
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
