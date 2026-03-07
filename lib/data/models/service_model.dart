// lib/data/models/service_model.dart
// Service data model

// lib/data/models/service_model.dart
class ServiceModel {
  final int id;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
  });

  String get formattedDuration {
    if (durationMinutes >= 60) {
      final hours   = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
    return '$durationMinutes ${durationMinutes == 1 ? 'minute' : 'minutes'}';
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id:              json['id'] as int,
      name:            json['name'] as String,
      description:     json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int,
      // ✅ FIXED: price comes back as String ("500.00") from MySQL DECIMAL column.
      // double.parse() handles both String and num safely.
      price:           double.parse(json['price'].toString()),
      imageUrl:        json['image_url'] as String?,
      isActive:        json['is_active'] == 1 || json['is_active'] == true,
      createdAt:       json['created_at'] != null
                         ? DateTime.parse(json['created_at'] as String)
                         : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':               id,
      'name':             name,
      'description':      description,
      'duration_minutes': durationMinutes,
      'price':            price,
      'image_url':        imageUrl,
      'is_active':        isActive,
      'created_at':       createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'ServiceModel(id: $id, name: $name, price: $formattedPrice)';
}