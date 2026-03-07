class Slot {
  final int id;
  final int serviceId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  Slot({
    required this.id,
    required this.serviceId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['id'] as int,
      serviceId: json['service_id'] as int,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'date': _formatDate(date),
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get displayDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get displayTime {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  String get displayStartTime {
    return _formatTime(startTime);
  }

  String get displayEndTime {
    return _formatTime(endTime);
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
      date.year,
      date.month,
      date.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );
  }

  bool get isInPast {
    return dateTime.isBefore(DateTime.now());
  }

  Slot copyWith({
    int? id,
    int? serviceId,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) {
    return Slot(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  String toString() {
    return 'Slot(id: $id, date: $displayDate, time: $displayTime, available: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Slot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}