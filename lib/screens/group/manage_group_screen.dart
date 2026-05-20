import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/group_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/screens/group/create_group_screen.dart';

class ManageGroupScreen extends StatelessWidget {
  const ManageGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final user = context.read<AuthProvider>().user;
    
    final myGroups = groupProvider.groups.where((g) => g.memberIds.contains(user?.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm của tôi'),
      ),
      body: myGroups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Bạn chưa tham gia nhóm nào', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo nhóm mới'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myGroups.length,
              itemBuilder: (context, index) {
                final group = myGroups[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(group.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(group.description),
                        const SizedBox(height: 4),
                        Text('Thành viên: ${group.memberIds.length}/${group.maxMembers}', 
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to group detail
                    },
                  ),
                );
              },
            ),
      floatingActionButton: myGroups.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
