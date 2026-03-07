import '../../core/network/api_service.dart';
import '../models/notification.dart';

class NotificationRepository {
  static Future<ApiResponse<List<NotificationModel>>> getNotifications({
    bool unreadOnly = false,
  }) async {
    final response = await ApiService.get(
      '/notifications?unreadOnly=$unreadOnly'
    );
    
    if (response.success && response.data != null) {
      final List<dynamic> notificationsJson = response.data is List
          ? response.data as List
          : response.data!['data'] as List? ?? [];
      
      final notifications = notificationsJson
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(notifications);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch notifications');
  }

  static Future<ApiResponse<int>> getUnreadCount() async {
    final response = await ApiService.get('/notifications/unread-count');
    
    if (response.success && response.data != null) {
      final count = response.data!['unread_count'] as int;
      return ApiResponse.success(count);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to fetch unread count');
  }

  static Future<ApiResponse<void>> markAsRead(int notificationId) async {
    final response = await ApiService.put('/notifications/$notificationId/read', {});
    
    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to mark as read');
  }

  static Future<ApiResponse<void>> markAllAsRead() async {
    final response = await ApiService.put('/notifications/read-all', {});
    
    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to mark all as read');
  }

  static Future<ApiResponse<void>> deleteNotification(int notificationId) async {
    final response = await ApiService.delete('/notifications/$notificationId');
    
    if (response.success) {
      return ApiResponse.success(null, message: response.message);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to delete notification');
  }
}