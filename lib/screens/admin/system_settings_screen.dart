import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/setting_provider.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi API lấy dữ liệu ngay khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingProvider>().fetchSettings();
    });
  }

  // Hàm hiển thị DatePicker để chọn ngày cấu hình thời gian đồ án
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final provider = context.read<SettingProvider>();
    DateTime initialDate = DateTime.now();
    try {
      initialDate = DateTime.parse(isStartDate ? provider.registrationStart : provider.registrationEnd);
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      String formattedDate = picked.toIso8601String().split('T')[0];
      
      String start = isStartDate ? formattedDate : provider.registrationStart;
      String end = isStartDate ? provider.registrationEnd : formattedDate;

      _saveConfig(start, end, provider.minMembers, provider.maxMembers);
    }
  }

  // Hàm hiển thị Dialog nhập số để đổi số lượng thành viên
  void _showNumberInputDialog(BuildContext context, String title, bool isMinMember) {
    final provider = context.read<SettingProvider>();
    final controller = TextEditingController(
      text: (isMinMember ? provider.minMembers : provider.maxMembers).toString()
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Nhập số lượng"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              int? value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                int min = isMinMember ? value : provider.minMembers;
                int max = isMinMember ? provider.maxMembers : value;
                
                if (min <= max) {
                  Navigator.pop(context);
                  _saveConfig(provider.registrationStart, provider.registrationEnd, min, max);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Số tối thiểu không được lớn hơn số tối đa!"))
                  );
                }
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // Hàm gọi xuống provider để đồng bộ dữ liệu lên server
  void _saveConfig(String start, String end, int min, int max) async {
    final success = await context.read<SettingProvider>().updateSettings(
      start: start,
      end: end,
      min: min,
      max: max,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Cập nhật thành công!" : "Cập nhật thất bại. Vui lòng thử lại."))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingProvider = context.watch<SettingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình hệ thống')),
      body: settingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _settingSection('Thời gian đăng ký đề tài', [
                  _settingTile(
                    'Ngày bắt đầu', 
                    settingProvider.registrationStart, 
                    Icons.calendar_today,
                    () => _selectDate(context, true)
                  ),
                  _settingTile(
                    'Ngày kết thúc', 
                    settingProvider.registrationEnd, 
                    Icons.calendar_month,
                    () => _selectDate(context, false)
                  ),
                ]),
                const SizedBox(height: 24),
                _settingSection('Quy định thành viên nhóm', [
                  _settingTile(
                    'Số thành viên tối thiểu', 
                    '${settingProvider.minMembers} người', 
                    Icons.person,
                    () => _showNumberInputDialog(context, "Sửa thành viên tối thiểu", true)
                  ),
                  _settingTile(
                    'Số thành viên tối đa', 
                    '${settingProvider.maxMembers} người', 
                    Icons.people,
                    () => _showNumberInputDialog(context, "Sửa thành viên tối đa", false)
                  ),
                ]),
                const SizedBox(height: 24),
                _settingSection('Bảo mật & Hệ thống', [
                  _settingTile('Yêu cầu xác thực 2 lớp', 'Đã tắt', Icons.security, () {}),
                  _settingTile('Thời gian phiên đăng nhập', '24 giờ', Icons.timer, () {}),
                ]),
              ],
            ),
    );
  }

  Widget _settingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}