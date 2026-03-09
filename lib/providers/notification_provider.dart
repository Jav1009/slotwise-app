// features/profile/providers/notification_provider.dart
import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/notification_model.dart';
import 'package:slot_wise_booking/services/api_service.dart';
import '../core/constants/api_constants.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool    _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int  get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading   => _isLoading;

  final _api = ApiService();

  Future<void> fetchNotifications() async {
    _isLoading = true; notifyListeners();
    try {
      final res   = await _api.get(ApiConstants.notifications);
      _notifications = (res.data as List)
          .map((j) => NotificationModel.fromJson(j))
          .toList();
    } catch (_) {}
    _isLoading = false; notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    await _api.put('${ApiConstants.notifications}/$id/read', {});
    await fetchNotifications();
  }

  Future<void> markAllRead() async {
    await _api.put(ApiConstants.notificationsAll, {});
    await fetchNotifications();
  }
}