import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../core/widgets/app_dialog.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/user_model.dart';

class CreateGroupScreen extends StatefulWidget {
  final String? initialCourseId;
  const CreateGroupScreen({super.key, this.initialCourseId});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _maxMembers = 5;
  int _minMembers = 2;
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.initialCourseId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _createGroup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCourseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn môn học')));
        return;
      }
      final groupProvider = context.read<GroupProvider>();
      final userId = context.read<AuthProvider>().user?.id ?? '';

      // Chặn sớm ở client: nếu SV đã ở nhóm nào trong môn này thì hiện popup.
      if (groupProvider.groupOfUserInCourse(userId, _selectedCourseId!) != null) {
        showAlreadyInGroupDialog(context);
        return;
      }

      final error = await groupProvider.createGroup(
        _nameController.text.trim(),
        _descController.text.trim(),
        _selectedCourseId!,
        _maxMembers,
        userId,
        null, // topicId is null when creating a new group
        minMembers: _minMembers,
      );

      if (!mounted) return;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo nhóm thành công!')));
        Navigator.pop(context);
      } else {
        // Backend từ chối (vd: đã ở nhóm khác) -> hiện popup.
        showAlreadyInGroupDialog(context, message: error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<GroupProvider>().isLoading;
    final user = context.watch<AuthProvider>().user;
    final courses = context.watch<CourseProvider>().courses;
    
    // Only show courses the student is enrolled in
    final enrolledCourses = courses.where((c) => user?.enrolledCourseIds.contains(c.id) ?? false).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo nhóm mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedCourseId,
                decoration: const InputDecoration(
                  labelText: 'Môn học',
                  border: OutlineInputBorder(),
                ),
                items: enrolledCourses.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourseId = value;
                  });
                },
                validator: (value) => value == null ? 'Vui lòng chọn môn học' : null,
              ),
              const SizedBox(height: 16),
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
              Text('Số lượng thành viên tối thiểu: $_minMembers', style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _minMembers.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _minMembers.toString(),
                onChanged: (value) {
                  setState(() {
                    _minMembers = value.toInt();
                    if (_minMembers > _maxMembers) _maxMembers = _minMembers;
                  });
                },
              ),
              const SizedBox(height: 16),
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
                    if (_maxMembers < _minMembers) _minMembers = _maxMembers;
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
