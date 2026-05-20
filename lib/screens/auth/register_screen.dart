import 'package:flutter/material.dart';
import 'package:ungdungdangkinhomvachondetai/core/widgets/custom_button.dart';
import 'package:ungdungdangkinhomvachondetai/core/widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'student';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      // Mock register logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tạo tài khoản mới',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  'Điền đầy đủ thông tin để đăng ký hệ thống',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên',
                  prefixIcon: Icons.person_outline,
                  controller: _nameController,
                  validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập họ và tên' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  hint: 'Nhập email của bạn',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập email' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                ),
                const SizedBox(height: 24),
                const Text('Vai trò:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'student', label: Text('Sinh viên')),
                    ButtonSegment(value: 'lecturer', label: Text('Giảng viên')),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedRole = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 48),
                CustomButton(
                  text: 'Đăng ký',
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
