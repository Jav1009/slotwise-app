// data/models/service_model.dart
class ServiceModel {
  final int    id;
  final String name;
  final String? description;
  final int    durationMinutes;
  final double price;
  final String? imageUrl;
  final bool   isActive;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.imageUrl,
    required this.isActive,
  });

  String get formattedPrice => 'JMD \$${price.toStringAsFixed(2)}';
  String get formattedDuration => '${durationMinutes} min';

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id:              json['id'],
    name:            json['name'],
    description:     json['description'],
    durationMinutes: json['duration_minutes'],
    price:           double.parse(json['price'].toString()),
    imageUrl:        json['image_url'],
    isActive:        json['is_active'] == 1 || json['is_active'] == true,
  );
}