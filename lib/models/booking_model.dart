// data/models/booking_model.dart
//
// Changes:
//   • Added: slotId, serviceId — needed for reschedule screen
//   • Added: userId, customerName, customerEmail — needed for staff/admin views
//   • Added: category — from service join
//   • All existing fields and getters unchanged
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
  bool get canCancel   => isUpcoming;
  bool get canReschedule => status == 'pending' || status == 'confirmed';

  // ── Display helpers ────────────────────────────────────────
  String get displayDateTime => '$slotDate at ${startTime.substring(0,5)}';
  String get displayTime     => '${startTime.substring(0, 5)} – ${endTime.substring(0, 5)}';

  // ── Deserialise ────────────────────────────────────────────
  // Handles both /bookings/my shape and /bookings (all) shape
  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id:          json['id'],
    status:      json['status'],
    notes:       json['notes'],
    serviceId:   (json['service_id']  as int?) ?? 0,
    serviceName: json['service_name'],
    price:       double.parse(json['price'].toString()),
    imageUrl:    json['image_url'],
    category:    json['category']     as String?,
    slotId:      (json['slot_id']     as int?) ?? 0,
    slotDate:    json['slot_date'].toString(),
    startTime:   json['start_time'].toString(),
    endTime:     json['end_time'].toString(),
    createdAt:   DateTime.parse(json['created_at']),
    updatedAt:     json['updated_at'] != null
                     ? DateTime.tryParse(json['updated_at'].toString())
                     : null,
    userId:        json['user_id']       as int?,
    customerName:  json['customer_name'] as String?,
    customerEmail: json['customer_email'] as String?,
  );
}