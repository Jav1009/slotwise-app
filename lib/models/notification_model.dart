// data/models/notification_model.dart
class NotificationModel {
  final int     id;
  final int?    bookingId;
  final String  message;
  final bool    isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.bookingId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id:        json['id'],
    bookingId: json['booking_id'],
    message:   json['message'],
    isRead:    json['is_read'] == 1 || json['is_read'] == true,
    createdAt: DateTime.parse(json['created_at']),
  );
}
