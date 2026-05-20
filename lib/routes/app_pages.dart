// Final check - SplashScreen removed.
import 'package:flutter/material.dart';
import 'package:ungdungdangkinhomvachondetai/core/constants/app_routes.dart';
import 'package:ungdungdangkinhomvachondetai/screens/auth/login_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/auth/register_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/home/home_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/group/manage_group_screen.dart';

export 'package:ungdungdangkinhomvachondetai/core/constants/app_routes.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    AppRoutes.login: (context) => const LoginScreen(),
    AppRoutes.register: (context) => const RegisterScreen(),
    AppRoutes.home: (context) => const HomeScreen(),
    AppRoutes.manageGroup: (context) => const ManageGroupScreen(),
  };
}
