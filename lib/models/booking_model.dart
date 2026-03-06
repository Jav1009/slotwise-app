// data/models/booking_model.dart
class BookingModel {
  final int     id;
  final String  status;
  final String? notes;
  final String  serviceName;
  final double  price;
  final String? imageUrl;
  final String  slotDate;
  final String  startTime;
  final String  endTime;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.status,
    this.notes,
    required this.serviceName,
    required this.price,
    this.imageUrl,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  bool get isUpcoming  => status == 'pending' || status == 'confirmed';
  bool get isPast      => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canCancel   => isUpcoming;

  String get displayDateTime => '$slotDate at ${startTime.substring(0,5)}';

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id:          json['id'],
    status:      json['status'],
    notes:       json['notes'],
    serviceName: json['service_name'],
    price:       double.parse(json['price'].toString()),
    imageUrl:    json['image_url'],
    slotDate:    json['slot_date'].toString(),
    startTime:   json['start_time'].toString(),
    endTime:     json['end_time'].toString(),
    createdAt:   DateTime.parse(json['created_at']),
  );
}