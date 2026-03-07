import 'package:flutter/material.dart';
import '../data/models/notification.dart';
import '../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  List<NotificationModel> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await NotificationRepository.getNotifications(
        unreadOnly: unreadOnly
      );
      
      if (response.success) {
        _notifications = response.data!;
        _updateUnreadCount();
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await NotificationRepository.getUnreadCount();
      if (response.success) {
        _unreadCount = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch unread count error: $e');
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await NotificationRepository.markAsRead(notificationId);
      
      if (response.success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _updateUnreadCount();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Mark as read error: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await NotificationRepository.markAllAsRead();
      
      if (response.success) {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Mark all as read error: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await NotificationRepository.deleteNotification(notificationId);
      
      if (response.success) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _updateUnreadCount();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete notification error: $e');
      return false;
    }
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}