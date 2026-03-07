import 'package:flutter/material.dart';

class NotificationModel {
  final int id;
  final int userId;
  final int? bookingId;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? bookingStatus;

  NotificationModel({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.bookingStatus,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      bookingId: json['booking_id'] as int?,
      message: json['message'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
      bookingStatus: json['booking_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'booking_id': bookingId,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  IconData get icon {
    switch (type) {
      case 'welcome':
        return Icons.waving_hand;
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'new_booking':
        return Icons.event_available;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'welcome':
        return Colors.blue;
      case 'booking_confirmed':
        return Colors.green;
      case 'booking_cancelled':
        return Colors.red;
      case 'new_booking':
        return Colors.orange;
      case 'reminder':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color get backgroundColor {
    if (isRead) {
      return Colors.transparent;
    }
    switch (type) {
      case 'welcome':
        return Colors.blue.withOpacity(0.1);
      case 'booking_confirmed':
        return Colors.green.withOpacity(0.1);
      case 'booking_cancelled':
        return Colors.red.withOpacity(0.1);
      case 'new_booking':
        return Colors.orange.withOpacity(0.1);
      case 'reminder':
        return Colors.purple.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  String get typeText {
    switch (type) {
      case 'welcome':
        return 'Welcome';
      case 'booking_confirmed':
        return 'Booking Confirmed';
      case 'booking_cancelled':
        return 'Booking Cancelled';
      case 'new_booking':
        return 'New Booking';
      case 'reminder':
        return 'Reminder';
      default:
        return type.split('_').map((word) => 
          word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    int? bookingId,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? bookingStatus,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      bookingStatus: bookingStatus ?? this.bookingStatus,
    );
  }

  @override
  String toString() {
    return 'Notification(id: $id, type: $type, read: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}