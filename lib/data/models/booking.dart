class Booking {
  final int id;
  final int userId;
  final int serviceId;
  final int slotId;
  final String status;
  final String? notes;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  
  // Joined fields
  final String serviceName;
  final double servicePrice;
  final int serviceDuration;
  final DateTime slotDate;
  final String slotStartTime;
  final String slotEndTime;
  final String? userName;
  final String? userEmail;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.slotId,
    required this.status,
    this.notes,
    this.cancelledAt,
    required this.createdAt,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDuration,
    required this.slotDate,
    required this.slotStartTime,
    required this.slotEndTime,
    this.userName,
    this.userEmail,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      serviceId: json['service_id'] as int,
      slotId: json['slot_id'] as int,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      cancelledAt: json['cancelled_at'] != null 
          ? DateTime.parse(json['cancelled_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      serviceName: json['service_name'] as String,
      servicePrice: (json['price'] as num).toDouble(),
      serviceDuration: json['duration_minutes'] as int,
      slotDate: DateTime.parse(json['date'] as String),
      slotStartTime: json['start_time'] as String,
      slotEndTime: json['end_time'] as String,
      userName: json['user_name'] as String?,
      userEmail: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_id': serviceId,
      'slot_id': slotId,
      'status': status,
      'notes': notes,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayDateTime {
    return '${_formatDate(slotDate)} at ${_formatTime(slotStartTime)}';
  }

  String get displayDate {
    return _formatDate(slotDate);
  }

  String get displayTime {
    return '${_formatTime(slotStartTime)} - ${_formatTime(slotEndTime)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  DateTime get dateTime {
    return DateTime(
      slotDate.year,
      slotDate.month,
      slotDate.day,
      int.parse(slotStartTime.split(':')[0]),
      int.parse(slotStartTime.split(':')[1]),
    );
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFF39C12); // Orange
      case 'confirmed':
        return const Color(0xFF2ECC71); // Green
      case 'completed':
        return const Color(0xFF3498DB); // Blue
      case 'cancelled':
        return const Color(0xFFE74C3C); // Red
      default:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  
  bool get isUpcoming {
    if (isCancelled || isCompleted) return false;
    return dateTime.isAfter(DateTime.now());
  }

  bool get isPast {
    return dateTime.isBefore(DateTime.now());
  }

  bool get canCancel {
    return (isPending || isConfirmed) && dateTime.isAfter(DateTime.now());
  }

  String get formattedPrice => '\$${servicePrice.toStringAsFixed(2)}';
  
  String get formattedDuration {
    if (serviceDuration < 60) {
      return '$serviceDuration min';
    }
    final hours = serviceDuration ~/ 60;
    final minutes = serviceDuration % 60;
    if (minutes == 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    }
    return '$hours hour${hours > 1 ? 's' : ''} $minutes min';
  }

  Booking copyWith({
    int? id,
    int? userId,
    int? serviceId,
    int? slotId,
    String? status,
    String? notes,
    DateTime? cancelledAt,
    DateTime? createdAt,
    String? serviceName,
    double? servicePrice,
    int? serviceDuration,
    DateTime? slotDate,
    String? slotStartTime,
    String? slotEndTime,
    String? userName,
    String? userEmail,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      slotId: slotId ?? this.slotId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      serviceName: serviceName ?? this.serviceName,
      servicePrice: servicePrice ?? this.servicePrice,
      serviceDuration: serviceDuration ?? this.serviceDuration,
      slotDate: slotDate ?? this.slotDate,
      slotStartTime: slotStartTime ?? this.slotStartTime,
      slotEndTime: slotEndTime ?? this.slotEndTime,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  @override
  String toString() {
    return 'Booking(id: $id, service: $serviceName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}