import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/course_provider.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Các biến trạng thái phục vụ Tìm kiếm và Sắp xếp
  String _searchQuery = '';
  String _sortBy = 'name_asc'; // Các giá trị: 'name_asc', 'name_desc', 'identity_asc'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
      context.read<CourseProvider>().fetchAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final courseProvider = context.watch<CourseProvider>();
    
    // Tách danh sách gốc
    final students = userProvider.users.where((u) => u.role == 'student').toList();
    final lecturers = userProvider.users.where((u) => u.role == 'lecturer').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            // BỔ SUNG: Hiển thị số lượng sinh viên hiện tại ngay trên Tab tuyển chọn
            Tab(
              icon: const Icon(Icons.school), 
              text: 'Sinh viên (${students.length})',
            ),
            // BỔ SUNG: Hiển thị số lượng giảng viên hiện tại
            Tab(
              icon: const Icon(Icons.person), 
              text: 'Giảng viên (${lecturers.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => userProvider.fetchUsers(),
          ),
        ],
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(context, students, courseProvider, userProvider),
                _buildUserList(context, lecturers, courseProvider, userProvider),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context, userProvider),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<UserModel> users, CourseProvider courseProvider, UserProvider userProvider) {
    // 1. Thực hiện TÌM KIẾM dựa trên từ khóa (Tên, Email hoặc Mã số)
    final filteredUsers = users.where((u) {
      final query = _searchQuery.toLowerCase();
      final matchName = u.name.toLowerCase().contains(query);
      final matchEmail = u.email.toLowerCase().contains(query);
      final matchIdentity = (u.identity ?? '').toLowerCase().contains(query);
      return matchName || matchEmail || matchIdentity;
    }).toList();

    // 2. Thực hiện SẮP XẾP theo tiêu chí đã chọn
    if (_sortBy == 'name_asc') {
      filteredUsers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'name_desc') {
      filteredUsers.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (_sortBy == 'identity_asc') {
      filteredUsers.sort((a, b) => (a.identity ?? '').compareTo(b.identity ?? ''));
    }

    return Column(
      children: [
        // BỔ SUNG: Thanh công cụ Tìm kiếm và Bộ Sắp xếp ở trên đầu danh sách
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              // Ô tìm kiếm thông tin
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tên, email, mã số...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Nút Menu lựa chọn kiểu Sắp xếp
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Colors.blue),
                  tooltip: 'Sắp xếp danh sách',
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'name_asc', 
                      child: Row(children: [Icon(Icons.sort_by_alpha), SizedBox(width: 8), Text('Tên: A -> Z')]),
                    ),
                    const PopupMenuItem(
                      value: 'name_desc', 
                      child: Row(children: [Icon(Icons.sort_by_alpha), SizedBox(width: 8), Text('Tên: Z -> A')]),
                    ),
                    const PopupMenuItem(
                      value: 'identity_asc', 
                      child: Row(children: [Icon(Icons.pin), SizedBox(width: 8), Text('Mã số tăng dần')]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Hiển thị danh sách kết quả sau khi lọc và xếp
        Expanded(
          child: filteredUsers.isEmpty
              ? const Center(child: Text('Không tìm thấy thành viên nào phù hợp.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.role == 'student' ? Colors.blue.shade100 : Colors.orange.shade100,
                          child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${user.email}'),
                            Text('Mã số: ${user.identity ?? "Chưa cập nhật"}', style: const TextStyle(color: Colors.grey)),
                            if (user.role == 'student')
                              Padding(
                                padding: const EdgeInsets.top(4.0),
                                child: Text(
                                  'Học kỳ hiện tại: ${courseProvider.getSemesterName(user.currentSemesterId)}',
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (user.role == 'student')
                              IconButton(
                                icon: const Icon(Icons.calendar_month, color: Colors.blue),
                                tooltip: 'Xếp Học kỳ cho sinh viên',
                                onPressed: () => _showSemesterDialog(context, user, courseProvider, userProvider),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                              tooltip: 'Xóa tài khoản',
                              onPressed: () => _showDeleteConfirmDialog(context, user, userProvider),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, UserModel user, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc chắn muốn xóa thành viên "${user.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await userProvider.deleteUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã xóa thành công!' : 'Xóa thất bại.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, UserProvider userProvider) {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController();
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final identityController = TextEditingController();
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Thêm thành viên mới'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Vai trò'),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                        DropdownMenuItem(value: 'lecturer', child: Text('Giảng viên')),
                      ],
                      onChanged: (val) => setStateDialog(() => selectedRole = val!),
                    ),
                    TextFormField(controller: idController, decoration: const InputDecoration(labelText: 'Mã ID (sv01, gv01)')),
                    TextFormField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
                    TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ và tên')),
                    TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                    TextFormField(controller: identityController, decoration: InputDecoration(labelText: selectedRole == 'student' ? 'MSSV' : 'MSGV')),
                    TextFormField(controller: passwordController, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final error = await userProvider.addUser(
                    id: idController.text.trim(),
                    username: usernameController.text.trim(),
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    role: selectedRole,
                    identity: identityController.text.trim(),
                  );
                  if (context.mounted) {
                    if (error == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thành công!'), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
// --- MỚI: Chọn học kỳ thay vì chọn môn học cho sinh viên ---
  void _showSemesterDialog(BuildContext context, UserModel student, CourseProvider courseProvider, UserProvider userProvider) {
    String? selectedSemesterId = student.currentSemesterId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Chọn Học kỳ cho: ${student.name}'),
          content: DropdownButtonFormField<String>(
            value: courseProvider.semesters.any((s) => s.id == selectedSemesterId) ? selectedSemesterId : null,
            decoration: const InputDecoration(
              labelText: 'Học kỳ phân bổ',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Chưa phân bổ / Trống'),
              ),
              ...courseProvider.semesters.map(
                (s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name)),
              ),
            ],
            onChanged: (val) => setStateDialog(() => selectedSemesterId = val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await userProvider.updateStudentSemester(student.id, selectedSemesterId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Cập nhật học kỳ thành công!' : 'Cập nhật thất bại.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Lưu lại'),
            ),
          ],
        ),
      ),
    );
  }
}