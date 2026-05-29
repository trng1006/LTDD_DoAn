import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/auth_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/group_provider.dart';
import 'package:ungdungdangkinhomvachondetai/providers/topic_provider.dart';
import 'package:ungdungdangkinhomvachondetai/routes/app_pages.dart';
import 'package:ungdungdangkinhomvachondetai/core/theme/app_theme.dart';

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
    return MaterialApp(
      title: 'Hệ thống Đăng ký Đề tài',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: AppPages.routes,
    );
  }
}
