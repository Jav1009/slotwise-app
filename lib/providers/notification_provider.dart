// features/profile/providers/notification_provider.dart
//
// Changes:
//   • fetchNotifications: reads res.data['data'] (new consistent response shape)
//   • markAsRead / markAllRead: unchanged

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
      // Accept both { data: [...] } and legacy plain array
      final list = (res.data is Map ? res.data['data'] : res.data) as List;
      _notifications = list
          .map((j) => NotificationModel.fromJson(j))
          .toList();
    } catch (_) {}
    _isLoading = false; notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.put('${ApiConstants.notifications}/$id/read', {});
      // Optimistic update — flip locally first, then re-fetch
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _notifications[idx] = NotificationModel(
          id:        _notifications[idx].id,
          bookingId: _notifications[idx].bookingId,
          message:   _notifications[idx].message,
          isRead:    true,
          createdAt: _notifications[idx].createdAt,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.put(ApiConstants.notificationsAll, {});
      _notifications = _notifications.map((n) => NotificationModel(
        id:        n.id,
        bookingId: n.bookingId,
        message:   n.message,
        isRead:    true,
        createdAt: n.createdAt,
      )).toList();
      notifyListeners();
    } catch (_) {}
  }
}