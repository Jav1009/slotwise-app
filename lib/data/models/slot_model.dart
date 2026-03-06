// lib/data/models/slot_model.dart
// Time slot data model

import 'package:intl/intl.dart';

class SlotModel {
  final int id;
  final int serviceId;
  final DateTime date;
  final String startTime; // HH:mm:ss format
  final String endTime;   // HH:mm:ss format
  final bool isAvailable;
  final String? serviceName;
  final int? durationMinutes;
  
  SlotModel({
    required this.id,
    required this.serviceId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.serviceName,
    this.durationMinutes,
  });
  
  // Format time as "9:00 AM - 10:00 AM"
  String get formattedTimeRange {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    return '$start - $end';
  }
  
  // Format date as "Monday, Jan 15"
  String get formattedDate {
    return DateFormat('EEEE, MMM d').format(date);
  }
  
  // Format start time only
  String get formattedStartTime => _formatTime(startTime);
  
  // Format end time only
  String get formattedEndTime => _formatTime(endTime);
  
  // Helper to format time from HH:mm:ss to 12-hour format
  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      
      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time24; // Return original if parsing fails
    }
  }
  
  // From JSON
  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] as int,
      serviceId: json['service_id'] as int,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAvailable: json['is_available'] as bool,
      serviceName: json['service_name'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
    );
  }
  
  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
      'service_name': serviceName,
      'duration_minutes': durationMinutes,
    };
  }
  
  @override
  String toString() {
    return 'SlotModel(id: $id, date: $formattedDate, time: $formattedTimeRange)';
  }
}