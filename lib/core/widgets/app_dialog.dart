import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Popup cảnh báo dùng chung cho ứng dụng.
Future<void> showAppAlertDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = LucideIcons.triangleAlert,
  Color color = const Color(0xFFF59E0B),
  String buttonText = 'Đã hiểu',
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Popup chuyên dụng: sinh viên đã tham gia một nhóm.
Future<void> showAlreadyInGroupDialog(BuildContext context, {String? message}) {
  return showAppAlertDialog(
    context,
    title: 'Bạn đã tham gia nhóm',
    message: message ??
        'Mỗi sinh viên chỉ được tham gia 1 nhóm cho mỗi môn học. '
            'Bạn cần rời nhóm hiện tại trước khi tạo hoặc tham gia nhóm khác.',
    icon: LucideIcons.userX,
  );
}
