import 'package:flutter/material.dart';
import 'package:ungdungdangkinhomvachondetai/core/widgets/custom_button.dart';
import 'package:ungdungdangkinhomvachondetai/core/widgets/custom_textfield.dart';

class JoinGroupScreen extends StatelessWidget {
  const JoinGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Tham gia nhóm')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CustomTextField(label: 'Mã nhóm', hint: 'Nhập mã nhóm để tham gia', controller: controller),
            const SizedBox(height: 32),
            CustomButton(text: 'Tham gia', onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu tham gia!')));
            }),
          ],
        ),
      ),
    );
  }
}
