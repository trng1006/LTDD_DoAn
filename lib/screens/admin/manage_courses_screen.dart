import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchAllData();
    });
  }

  void _showAddSemesterDialog(BuildContext context, CourseProvider provider) {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Học kỳ mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(
                labelText: 'Mã học kỳ (VD: s7)',
              ),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên học kỳ (VD: Học kỳ 7)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                final success = await provider.addSemester(
                  idCtrl.text.trim(),
                  nameCtrl.text.trim(),
                  false,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Thêm thành công!' : 'Thêm thất bại!',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context, CourseProvider provider) {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String? selectedSemesterId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Thêm Môn học mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mã ID hệ thống (VD: c10)',
                  ),
                ),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mã môn học (VD: 01011)',
                  ),
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên môn học'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Thuộc học kỳ'),
                  value: selectedSemesterId,
                  items: provider.semesters
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setStateDialog(() => selectedSemesterId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (idCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                  final success = await provider.addCourse(
                    idCtrl.text.trim(),
                    nameCtrl.text.trim(),
                    codeCtrl.text.trim(),
                    selectedSemesterId,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'Thêm thành công!' : 'Thêm thất bại!',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Đào tạo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Học kỳ'),
              Tab(text: 'Môn học'),
            ],
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // TAB HỌC KỲ
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.semesters.length,
                    itemBuilder: (context, index) {
                      final sem = provider.semesters[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            sem.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Trạng thái: ${sem.isActive ? "Đang mở" : "Đã đóng"}',
                          ),
                          trailing: Switch(
                            value: sem.isActive,
                            onChanged: (val) {
                              if (val)
                                provider.setSemesterActive(
                                  sem.id,
                                ); // Chỉ cho phép bật
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  // TAB MÔN HỌC
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.courses.length,
                    itemBuilder: (context, index) {
                      final course = provider.courses[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.book, color: Colors.blue),
                          title: Text(
                            course.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mã môn: ${course.code}'),
                              Text(
                                'Học kỳ: ${provider.getSemesterName(course.semesterId)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => provider.deleteCourse(course.id),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
        floatingActionButton: Builder(
          builder: (ctx) {
            return FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                final tabIndex = DefaultTabController.of(ctx).index;
                if (tabIndex == 0) {
                  _showAddSemesterDialog(context, provider);
                } else {
                  _showAddCourseDialog(context, provider);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
