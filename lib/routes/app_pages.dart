import 'package:flutter/material.dart';
import 'package:ungdungdangkinhomvachondetai/core/constants/app_routes.dart';
import 'package:ungdungdangkinhomvachondetai/screens/auth/login_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/auth/register_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/auth/forgot_password_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/home/home_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/group/manage_group_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/group/join_group_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/topic/topic_list_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/admin/admin_dashboard_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/notification/notification_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/admin/manage_students_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/admin/statistics_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/admin/system_settings_screen.dart';
import 'package:ungdungdangkinhomvachondetai/screens/profile/profile_screen.dart';

export 'package:ungdungdangkinhomvachondetai/core/constants/app_routes.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    AppRoutes.login: (context) => const LoginScreen(),
    AppRoutes.register: (context) => const RegisterScreen(),
    AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
    AppRoutes.home: (context) => const HomeScreen(),
    AppRoutes.manageGroup: (context) => const ManageGroupScreen(),
    AppRoutes.joinGroup: (context) => const JoinGroupScreen(),
    AppRoutes.topicList: (context) => const TopicListScreen(),
    AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),
    AppRoutes.notifications: (context) => const NotificationScreen(),
    AppRoutes.manageUsers: (context) => const ManageStudentsScreen(),
    AppRoutes.statistics: (context) => const StatisticsScreen(),
    AppRoutes.systemSettings: (context) => const SystemSettingsScreen(),
    AppRoutes.profile: (context) => const ProfileScreen(),
  };
}
