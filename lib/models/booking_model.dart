// data/models/booking_model.dart
//
// Changes:
//   • Added: slotId, serviceId — needed for reschedule screen
//   • Added: userId, customerName, customerEmail — needed for staff/admin views
//   • Added: category — from service join
//   • displayDateTime: now formats as "Mar 12, 2026" (month name day, year)
//   • displayDate: new getter — date only, formatted
//   • Added: isMissed getter — slot has passed and status is still pending/confirmed
//   • Added: missed to status helpers
//   • category and notes now show meaningful fallback text (never 'null')
//   • All existing fields and getters unchanged
import 'package:intl/intl.dart';

class BookingModel {
  final int     id;
  final String  status;
  final String? notes;
  final int     serviceId;
  final String  serviceName;
  final double  price;
  final String? imageUrl;
  final String? category;
  final int     slotId;
  final String  slotDate;
  final String  startTime;
  final String  endTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Staff/admin view fields (null when fetched from /bookings/my)
  final int?    userId;
  final String? customerName;
  final String? customerEmail;

  BookingModel({
    required this.id,
    required this.status,
    this.notes,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    this.imageUrl,
    this.category,
    required this.slotId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.updatedAt,
    this.userId,
    this.customerName,
    this.customerEmail,
  });

  // ── Status helpers ─────────────────────────────────────────
  bool get isUpcoming  => status == 'pending' || status == 'confirmed';
  bool get isPast      => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isMissed     => status == 'missed';
  bool get canCancel   => isUpcoming;
  bool get canReschedule => status == 'pending' || status == 'confirmed';

  /// True when the slot's datetime has already passed and booking is still
  /// pending/confirmed — used by the client-side missed check.
  bool get isOverdue {
    if (!isUpcoming) return false;
    try {
      final timeParts = startTime.substring(0, 5).split(':');
      final dateParts = slotDate.split('-');
      final slotDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      return DateTime.now().isAfter(slotDateTime);
    } catch (_) {
      return false;
    }
  }

  // ── Display helpers ────────────────────────────────────────
  /// e.g. "Mar 12, 2026 at 09:20"
  String get displayDateTime {
    try {
      final d = DateFormat('yyyy-MM-dd').parse(slotDate);
      final formatted = DateFormat('MMM d, yyyy').format(d);
      return '$formatted at ${startTime.substring(0, 5)}';
    } catch (_) {
      return '$slotDate at ${startTime.substring(0, 5)}';
    }
  }
 
  /// e.g. "Mar 12, 2026"
  String get displayDate {
    try {
      final d = DateFormat('yyyy-MM-dd').parse(slotDate);
      return DateFormat('MMM d, yyyy').format(d);
    } catch (_) {
      return slotDate;
    }
  }
 
  /// e.g. "09:00 – 09:30"
  // String get displayDateTime => '$slotDate at ${startTime.substring(0,5)}';
  String get displayTime     => '${startTime.substring(0, 5)} – ${endTime.substring(0, 5)}';

   /// Category with null fallback
  String get displayCategory => (category != null && category!.isNotEmpty) ? category! : 'No category';
 
  /// Notes with null fallback
  String get displayNotes => (notes != null && notes!.isNotEmpty) ? notes! : 'No notes';

  // ── Deserialise ────────────────────────────────────────────
  // Handles both /bookings/my shape and /bookings (all) shape
  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id:          json['id'],
    status:      json['status'],
    notes:       json['notes'] as String?, // nullable — no notes is fine
    serviceId:   (json['service_id']  as int?) ?? 0,
    serviceName: json['service_name'] ?? 'Unknown service',
    price:       double.parse(json['price'].toString()),
    imageUrl:    json['image_url']    as String?, // nullable — service may have no image
    category:    json['category']     as String?,
    slotId:      (json['slot_id']     as int?) ?? 0,
    slotDate:    json['slot_date'].toString(),
    startTime:   json['start_time'].toString(),
    endTime:     json['end_time'].toString(),
    createdAt:   DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    updatedAt:     json['updated_at'] != null
                     ? DateTime.tryParse(json['updated_at'].toString())
                     : null,
    userId:        json['user_id']       as int?,
    customerName:  json['customer_name'] as String?,
    customerEmail: json['customer_email'] as String?,
  );
}