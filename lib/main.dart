import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/models/notification_model.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/group_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/notification_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/topic_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/setting_provider.dart';
import 'package:ungdungdangkinhomvachondetai/routes/app_pages.dart';
import 'package:ungdungdangkinhomvachondetai/core/theme/app_theme.dart';
import 'package:ungdungdangkinhomvachondetai/screens/auth/login_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/home/home_screen.dart';

import 'package:ungdungdangkinhomvachondetai/providers/course_provider.dart';

import 'package:ungdungdangkinhomvachondetai/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => TopicProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SettingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final notificationProvider = context.read<NotificationProvider>();
        if (auth.user == null) {
          notificationProvider.stopPolling();
        } else {
          notificationProvider.startPolling(auth.user!.id);
        }
        return MaterialApp(
          title: 'Hệ thống Đăng ký Đề tài',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          // Nếu đã có user thì vào Home, ngược lại vào Login
          home: auth.user != null ? const HomeScreen() : const LoginScreen(),
          routes: AppPages.routes,
          builder: (context, child) =>
              NotificationToastHost(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

class NotificationToastHost extends StatefulWidget {
  final Widget child;

  const NotificationToastHost({super.key, required this.child});

  @override
  State<NotificationToastHost> createState() => _NotificationToastHostState();
}

class _NotificationToastHostState extends State<NotificationToastHost> {
  OverlayEntry? _entry;
  Timer? _hideTimer;
  int _shownToastVersion = 0;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notification = notificationProvider.latestIncomingNotification;
    final toastVersion = notificationProvider.toastVersion;

    if (notification != null && toastVersion != _shownToastVersion) {
      _shownToastVersion = toastVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showToast(notification);
      });
    }

    return widget.child;
  }

  void _showToast(NotificationModel notification) {
    _hideTimer?.cancel();
    _entry?.remove();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -28, end: 0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, offsetY, child) {
            return Transform.translate(
              offset: Offset(0, offsetY),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: _NotificationToast(notification: notification),
          ),
        ),
      ),
    );

    overlay.insert(_entry!);
    _hideTimer = Timer(const Duration(seconds: 4), () {
      _entry?.remove();
      _entry = null;
    });
  }
}

class _NotificationToast extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationToast({required this.notification});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notification.type);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(_iconFor(notification.type), color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'join_request':
        return Icons.person_add_alt_1_rounded;
      case 'join_approved':
      case 'topic_approved':
        return Icons.check_circle_rounded;
      case 'join_rejected':
      case 'topic_rejected':
        return Icons.cancel_rounded;
      case 'topic_registration':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'join_request':
        return Colors.orange;
      case 'join_approved':
      case 'topic_approved':
        return Colors.green;
      case 'join_rejected':
      case 'topic_rejected':
        return Colors.red;
      case 'topic_registration':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }
}
