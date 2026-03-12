// data/models/service_model.dart
//
// Changes:
//   • Added: category — for filter chips on home screen
//
// FIX:
//   • category: required String → String? (nullable)
//     Old services in DB have category = null.
//     'null as String' throws a TypeError that silently kills the entire
//     list parse — zero services show in the UI with no visible error.
//   • formattedPrice: now comma-separated (JMD $50,000.00)

import 'package:intl/intl.dart';

class ServiceModel {
  final int    id;
  final String name;
  final String? description;
  final int    durationMinutes;
  final double price;
  final String? imageUrl;
  final String? category;
  final bool   isActive;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.isActive,
  });

  // ── Display helpers ───────────────────────────────────────
  static final _fmt = NumberFormat('#,##0.00', 'en_US');

  /// JMD $1,000.00 / JMD $50,000.00 / JMD $1,000,000.00
  String get formattedPrice => 'JMD \$${_fmt.format(price)}';
  String get formattedDuration => '${durationMinutes} min';

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id:              json['id'],
    name:            json['name'],
    description:     json['description'],
    durationMinutes: json['duration_minutes'],
    price:           double.parse(json['price'].toString()),
    imageUrl:        json['image_url'],
    category:        json['category']        as String?,
    isActive:        json['is_active'] == 1 || json['is_active'] == true,
  );
}