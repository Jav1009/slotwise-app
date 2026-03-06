// data/models/slot_model.dart
class SlotModel {
  final int    id;
  final int    serviceId;
  final String slotDate;
  final String startTime;
  final String endTime;
  final bool   isAvailable;

  SlotModel({
    required this.id,
    required this.serviceId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  // Display label for ChoiceChip e.g. "09:00 – 09:30"
  String get displayTime => '$startTime – $endTime';

  factory SlotModel.fromJson(Map<String, dynamic> json) => SlotModel(
    id:          json['id'],
    serviceId:   json['service_id'],
    slotDate:    json['slot_date'].toString(),
    startTime:   json['start_time'].toString().substring(0, 5), // "HH:MM"
    endTime:     json['end_time'].toString().substring(0, 5),
    isAvailable: json['is_available'] == 1 || json['is_available'] == true,
  );
}
