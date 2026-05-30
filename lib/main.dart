import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/group_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/topic_provider.dart';
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
        return MaterialApp(
          title: 'Hệ thống Đăng ký Đề tài',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          // Nếu đã có user thì vào Home, ngược lại vào Login
          home: auth.user != null ? const HomeScreen() : const LoginScreen(),
          routes: AppPages.routes,
        );
      },
    );
  }
}
