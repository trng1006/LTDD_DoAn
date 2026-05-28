import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _maxMembers = 5;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _createGroup() async {
    if (_formKey.currentState!.validate()) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      await context.read<GroupProvider>().createGroup(
        _nameController.text.trim(),
        _descController.text.trim(),
        _maxMembers,
        userId,
        null, // topicId is null when creating a new group
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo nhóm thành công!')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<GroupProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo nhóm mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Tên nhóm',
                hint: 'Ví dụ: Nhóm 01 - Trí tuệ nhân tạo',
                controller: _nameController,
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên nhóm' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Mô tả ngắn',
                hint: 'Nhập mô tả về nhóm...',
                controller: _descController,
              ),
              const SizedBox(height: 24),
              Text('Số lượng thành viên tối đa: $_maxMembers', style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _maxMembers.toDouble(),
                min: 2,
                max: 10,
                divisions: 8,
                label: _maxMembers.toString(),
                onChanged: (value) {
                  setState(() {
                    _maxMembers = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Tạo nhóm',
                isLoading: isLoading,
                onPressed: _createGroup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
