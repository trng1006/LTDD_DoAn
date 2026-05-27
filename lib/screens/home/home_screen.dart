import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/group_provider.dart';
import 'package:ungdungdangkinhomvachondetai/core/constants/app_routes.dart';
import 'package:ungdungdangkinhomvachondetai/models/group_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final user = authProvider.user;
    if (user == null) return const Scaffold();

    final bool isStudent = user.role == 'student';
    final bool isLecturer = user.role == 'lecturer';
    final bool isAdmin = user.role == 'admin';
    
    final myGroup = groupProvider.groups.firstWhere(
      (g) => g.memberIds.contains(user.id), 
      orElse: () => GroupModel(id: '', name: '', description: '', maxMembers: 0, memberIds: [], pendingMemberIds: [], leaderId: '')
    );
    final bool hasGroup = myGroup.id.isNotEmpty;
    final bool isLeader = myGroup.leaderId == user.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ thống Đăng ký Đề tài'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, user),
            const SizedBox(height: 32),
            
            if (isStudent || isLecturer) ...[
              _buildSubjectSelector(context),
              const SizedBox(height: 24),
            ],

            Text(
              'Chức năng chính',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (isStudent) ...[
              if (!hasGroup) ...[
                _buildActionCard(
                  context,
                  'Tạo nhóm mới',
                  'Đăng ký làm Trưởng nhóm cho môn học',
                  Icons.group_add_rounded,
                  Colors.blue,
                  () => Navigator.pushNamed(context, AppRoutes.manageGroup),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hoặc gia nhập nhóm sẵn có',
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildAvailableGroups(context, groupProvider, user.id),
              ] else ...[
                _buildActionCard(
                  context,
                  'Nhóm của tôi',
                  'Quản lý thành viên (${myGroup.memberIds.length} TV)',
                  Icons.groups_rounded,
                  Colors.indigo,
                  () => Navigator.pushNamed(context, AppRoutes.manageGroup),
                ),
                if (isLeader)
                  _buildActionCard(
                    context,
                    'Đăng ký đề tài',
                    'Chọn đề tài từ danh sách giảng viên',
                    Icons.assignment_rounded,
                    Colors.orange,
                    () => Navigator.pushNamed(context, AppRoutes.topicList),
                  ),
              ],
            ],
            
            if (isLecturer) ...[
              _buildActionCard(
                context,
                'Quản lý đề tài',
                'Thêm mới và chỉnh sửa đề tài của bạn',
                Icons.book_rounded,
                Colors.teal,
                () => Navigator.pushNamed(context, AppRoutes.topicList),
              ),
              _buildActionCard(
                context,
                'Nhóm đăng ký',
                'Xem và phê duyệt các nhóm đã chọn đề tài',
                Icons.how_to_reg_rounded,
                Colors.purple,
                () => Navigator.pushNamed(context, AppRoutes.topicList),
              ),
              _buildActionCard(
                context,
                'Tổng quan môn học',
                'Xem thống kê các nhóm và đề tài',
                Icons.analytics_rounded,
                Colors.blueGrey,
                () => Navigator.pushNamed(context, AppRoutes.statistics),
              ),
            ],
            
            if (isAdmin) ...[
              _buildActionCard(
                context,
                'Toàn bộ đề tài',
                'Quản lý tất cả đề tài trong hệ thống',
                Icons.admin_panel_settings_rounded,
                Colors.redAccent,
                () => Navigator.pushNamed(context, AppRoutes.topicList),
              ),
              _buildActionCard(
                context,
                'Quản lý người dùng',
                'Danh sách sinh viên, giảng viên & admin',
                Icons.people_alt_rounded,
                Colors.blueAccent,
                () => Navigator.pushNamed(context, AppRoutes.manageUsers),
              ),
              _buildActionCard(
                context,
                'Cấu hình hệ thống',
                'Thiết lập thời gian và quy định chung',
                Icons.settings_suggest_rounded,
                Colors.grey,
                () => Navigator.pushNamed(context, AppRoutes.systemSettings),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.book_outlined, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Môn học hiện tại:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Phân tích thiết kế hệ thống', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Đổi môn')),
        ],
      ),
    );
  }

  Widget _buildAvailableGroups(BuildContext context, GroupProvider provider, String userId) {
    final availableGroups = provider.groups.where((g) => !g.memberIds.contains(userId) && g.memberIds.length < g.maxMembers).toList();
    
    if (availableGroups.isEmpty) return const Text('Không có nhóm nào đang tuyển.');

    return Column(
      children: availableGroups.map((group) {
        final bool isPending = group.pendingMemberIds.contains(userId);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(group.name),
            subtitle: Text('${group.memberIds.length}/${group.maxMembers} TV - Trưởng: ${group.leaderId}'),
            trailing: isPending 
              ? const Text('Đang chờ...', style: TextStyle(color: Colors.orange))
              : ElevatedButton(
                  onPressed: () {
                    provider.requestToJoin(group.id, userId);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu gia nhập!')));
                  }, 
                  child: const Text('Gia nhập')
                ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              user.name[0],
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chào mừng,', style: Theme.of(context).textTheme.bodyMedium),
                Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text(user.role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),

              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
