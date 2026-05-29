import 'package:flutter/material.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tạo tài khoản mới',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Tên đăng nhập',
                  hint: 'Ví dụ: nguyenvana123',
                  prefixIcon: Icons.account_circle_outlined,
                  controller: _usernameController,
                  validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                ),
                const SizedBox(height: 16),
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
                  hint: 'example@gmail.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
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
                const SizedBox(height: 48),
                CustomButton(text: 'Đăng ký', onPressed: _register),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
