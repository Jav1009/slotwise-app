// data/models/user_model.dart
//
// WHAT CHANGED FROM PREVIOUS VERSION:
//   uid field: kept for backward compatibility but made nullable with default ''
//   Added: firstName + lastName getters (split from name field)
//   fromJson: now handles BOTH { firstName, lastName } AND { name } from backend
//
// WHY: The backend authController.js was updated to use password_hash (bcrypt).
//   The backend response returns { firstName, lastName } separately.
//   But older code used a single 'name' field — fromJson handles both cases.
//
// uid is kept as a field (empty string by default) because other files in the
// project may reference user.uid. It's no longer used for auth purposes —
// authentication is now handled entirely by bcrypt + JWT.

class UserModel {
  final int    id;
  final String uid;  // Legacy field — no longer used for auth, kept for compatibility
  final String name;  // Full name: "firstName lastName"
  final String email;
  final String role;
  final String? profilePictureUrl;

  UserModel({
    required this.id,
    this.uid = '',  // Default empty — uid column exists in DB but not used for auth
    required this.name,
    required this.email,
    required this.role,
    this.profilePictureUrl,
  });

  // Convenience getters
  bool   get isAdmin    => role == 'admin';
  String get firstName  => name.split(' ').first;
  String get lastName   => name.contains(' ') ? name.split(' ').sublist(1).join(' ') : '';
  String get initials   {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both { firstName, lastName } and { name } formats
    // Backend authController returns firstName + lastName after the password_hash update
    // Older code/responses may return a single name field — we handle both
    String fullName;
    if (json.containsKey('firstName') || json.containsKey('first_name')) {
      final first = json['firstName'] ?? json['first_name'] ?? '';
      final last  = json['lastName']  ?? json['last_name']  ?? '';
      fullName = last.isNotEmpty ? '$first $last' : first;
    } else {
      fullName = json['name'] ?? '';
    }

    return UserModel(
      id:                json['id'],
      uid:               json['uid'] ?? '',
      name:              fullName,
      email:             json['email'],
      role:              json['role'] ?? 'user',
      profilePictureUrl: json['profile_picture_url'] ?? json['profilePictureUrl'],
    );
  }

  // Useful for debugging
  @override
  String toString() => 'UserModel(id: $id, name: $name, role: $role)';
}