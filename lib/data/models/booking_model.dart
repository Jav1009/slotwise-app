// lib/data/models/booking_model.dart
// Booking data model

import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class BookingModel {
  final int id;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String? notes;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  // Service details
  final String serviceName;
  final int? durationMinutes;
  final double price;

  // Slot details
  final DateTime date;
  final String startTime;
  final String endTime;

  BookingModel({
    required this.id,
    required this.status,
    this.notes,
    required this.createdAt,
    this.cancelledAt,
    required this.serviceName,
    this.durationMinutes,
    required this.price,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  // Status display text
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending Confirmation';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  // Status color
  Color get statusColor {
    switch (status) {
      case 'pending':
        return AppColors.pending;
      case 'confirmed':
        return AppColors.confirmed;
      case 'cancelled':
        return AppColors.cancelled;
      case 'completed':
        return AppColors.completed;
      default:
        return AppColors.textSecondary;
    }
  }

  // Check if booking is in the future
  bool get isFuture {
    final now = DateTime.now();
    final bookingDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );
    return bookingDateTime.isAfter(now);
  }

  // Check if booking can be cancelled
  bool get canBeCancelled {
    return (status == 'pending' || status == 'confirmed') && isFuture;
  }

  // Format date as "Monday, Jan 15, 2026"
  String get formattedDate {
    return DateFormat('EEEE, MMM d, y').format(date);
  }

  // Format time range
  String get formattedTimeRange {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    return '$start - $end';
  }

  // Format price
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  // Helper to format time
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
      return time24;
    }
  }

  // From JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      serviceName: json['service_name'] as String,
      durationMinutes: json['duration_minutes'] as int?,
      price: double.parse(json['price'].toString()),
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'service_name': serviceName,
      'duration_minutes': durationMinutes,
      'price': price,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, service: $serviceName, status: $status)';
  }
}
