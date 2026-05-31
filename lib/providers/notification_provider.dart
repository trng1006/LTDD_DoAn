import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Duration pollingInterval;

  NotificationProvider({this.pollingInterval = const Duration(seconds: 5)});

  List<NotificationModel> _notifications = [];
  final Set<String> _knownNotificationIds = {};
  Timer? _timer;
  String? _activeUserId;
  bool _isLoading = false;
  bool _hasFetchedOnce = false;
  NotificationModel? _latestIncomingNotification;
  int _toastVersion = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  NotificationModel? get latestIncomingNotification =>
      _latestIncomingNotification;
  int get toastVersion => _toastVersion;

  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();
    final fetchedNotifications = await _apiService.getNotifications(userId);
    final fetchedIds = fetchedNotifications
        .map((notification) => notification.id)
        .toSet();

    if (_hasFetchedOnce) {
      final newNotifications = fetchedNotifications
          .where(
            (notification) => !_knownNotificationIds.contains(notification.id),
          )
          .toList();
      if (newNotifications.isNotEmpty) {
        _latestIncomingNotification = newNotifications.first;
        _toastVersion++;
      }
    }

    _notifications = fetchedNotifications;
    _knownNotificationIds
      ..clear()
      ..addAll(fetchedIds);
    _hasFetchedOnce = true;
    _isLoading = false;
    notifyListeners();
  }

  void startPolling(String userId) {
    if (_activeUserId == userId && _timer?.isActive == true) return;
    stopPolling();
    _activeUserId = userId;
    Future.microtask(() => fetchNotifications(userId));
    _timer = Timer.periodic(pollingInterval, (_) => fetchNotifications(userId));
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _activeUserId = null;
    _knownNotificationIds.clear();
    _hasFetchedOnce = false;
    _latestIncomingNotification = null;
    _toastVersion = 0;
  }

  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    final success = await _apiService.markNotificationRead(notification.id);
    if (!success) return;
    notification.isRead = true;
    notifyListeners();
  }

  Future<void> markAllAsRead(String userId) async {
    final success = await _apiService.markAllNotificationsRead(userId);
    if (!success) return;
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
