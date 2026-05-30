import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUpdatingProfile = true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final success = await context.read<AuthProvider>().updateUser(
        _nameController.text.trim(),
        _emailController.text.trim(),
      );
      if (mounted) {
        setState(() => _isUpdatingProfile = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Cập nhật thành công!' : 'Cập nhật thất bại.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      setState(() => _isChangingPassword = true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final result = await context.read<AuthProvider>().changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      
      if (mounted) {
        setState(() => _isChangingPassword = false);
        final bool success = result['success'] ?? false;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (success ? 'Đổi mật khẩu thành công!' : 'Đổi mật khẩu thất bại.')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: Center(child: Text('Không tìm thấy thông tin người dùng')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildPasswordSection(),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Đăng xuất', 
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              isOutlined: true,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user.name.isNotEmpty ? user.name[0] : 'U',
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final user = context.read<AuthProvider>().user!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Thông tin tài khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'MSSV / Staff ID',
                hint: 'ID định danh',
                prefixIcon: Icons.badge_outlined,
                controller: TextEditingController(text: user.identity),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Họ và tên',
                hint: 'Nhập họ và tên',
                prefixIcon: Icons.face_outlined,
                controller: _nameController,
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                hint: 'Nhập địa chỉ email',
                prefixIcon: Icons.alternate_email,
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  if (!value.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isUpdatingProfile 
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(text: 'Lưu thay đổi', onPressed: _updateProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Bảo mật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Mật khẩu cũ',
                hint: 'Nhập mật khẩu hiện tại',
                prefixIcon: Icons.lock_open,
                isPassword: true,
                controller: _oldPasswordController,
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu cũ' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Mật khẩu mới',
                hint: 'Ít nhất 6 ký tự',
                prefixIcon: Icons.vpn_key_outlined,
                isPassword: true,
                controller: _newPasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                  if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Xác nhận mật khẩu mới',
                hint: 'Nhập lại mật khẩu mới',
                prefixIcon: Icons.check_circle_outline,
                isPassword: true,
                controller: _confirmPasswordController,
                validator: (value) {
                  if (value != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isChangingPassword
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    text: 'Đổi mật khẩu', 
                    onPressed: _changePassword,
                    isOutlined: true,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
