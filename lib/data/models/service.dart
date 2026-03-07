class Service {
  final int id;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.imageUrl,
    required this.isActive,
    this.createdAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'duration_minutes': durationMinutes,
      'price': price,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (minutes == 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    }
    return '$hours hour${hours > 1 ? 's' : ''} $minutes min';
  }

  Service copyWith({
    int? id,
    String? name,
    String? description,
    int? durationMinutes,
    double? price,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Service(id: $id, name: $name, price: $formattedPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Service && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}