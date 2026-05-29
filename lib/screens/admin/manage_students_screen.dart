import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/user_model.dart';

class ManageStudentsScreen extends StatelessWidget {
  const ManageStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final courseProvider = context.watch<CourseProvider>();
    
    final students = userProvider.users.where((u) => u.role == 'student').toList();
    final lecturers = userProvider.users.where((u) => u.role == 'lecturer').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Người dùng'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sinh viên'),
              Tab(text: 'Giảng viên'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(context, students, courseProvider, userProvider),
            _buildUserList(context, lecturers, courseProvider, userProvider),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<UserModel> users, CourseProvider courseProvider, UserProvider userProvider) {
    if (users.isEmpty) return const Center(child: Text('Không có người dùng nào.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(user.name[0])),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: user.role == 'student' 
              ? IconButton(
                  icon: const Icon(Icons.book_rounded, color: Colors.blue),
                  onPressed: () => _showEnrollmentDialog(context, user, courseProvider, userProvider),
                )
              : null,
            onTap: () {
              // Edit user profile
            },
          ),
        );
      },
    );
  }

  void _showEnrollmentDialog(BuildContext context, UserModel student, CourseProvider courseProvider, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final enrolledCourses = courseProvider.courses.where((c) => student.enrolledCourseIds.contains(c.id)).toList();
          final availableCourses = courseProvider.courses.where((c) => !student.enrolledCourseIds.contains(c.id)).toList();

          return AlertDialog(
            title: Text('Đăng ký môn học: ${student.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Môn đã đăng ký:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (enrolledCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Chưa đăng ký môn nào.', style: TextStyle(fontStyle: FontStyle.italic)),
                    )
                  else
                    ...enrolledCourses.map((c) => ListTile(
                      title: Text(c.name),
                      subtitle: Text(c.code),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          userProvider.unenrollUserFromCourse(student.id, c.id);
                          setStateDialog(() {});
                        },
                      ),
                    )),
                  const Divider(),
                  const Text('Môn có sẵn:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (availableCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Tất cả các môn đã được đăng ký.', style: TextStyle(fontStyle: FontStyle.italic)),
                    )
                  else
                    ...availableCourses.map((c) => ListTile(
                      title: Text(c.name),
                      subtitle: Text(c.code),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () {
                          userProvider.enrollUserInCourse(student.id, c.id);
                          setStateDialog(() {});
                        },
                      ),
                    )),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            ],
          );
        },
      ),
    );
  }
}
