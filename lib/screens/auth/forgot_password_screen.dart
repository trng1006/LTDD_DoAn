import 'package:flutter/material.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Nhập email để nhận hướng dẫn khôi phục mật khẩu.'),
            const SizedBox(height: 24),
            CustomTextField(label: 'Email', hint: 'email@gmail.com', controller: controller),
            const SizedBox(height: 32),
            CustomButton(text: 'Gửi yêu cầu', onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi mã reset!')));
            }),
          ],
        ),
      ),
    );
  }
}
