// lib/models/user_model.dart
//
// Changes from previous version:
//   • Removed: uid field (backend no longer uses Supabase/Firebase uid)
//   • Replaced: name → firstName + lastName
//   • Added: isStaff getter
//   • Updated: isAdmin getter
//   • Role constants added for safe comparisons throughout the app

class UserModel {
  // ── Role constants ─────────────────────────────────────────
  // Use these instead of raw strings to avoid typos:
  //   if (user.role == UserModel.roleCustomer)  ✅
  //   if (user.role == 'customer/user')              ⚠️  prone to typos
  static const String roleCustomer = 'user';
  static const String roleStaff    = 'staff';
  static const String roleAdmin    = 'admin';

  // ── Fields ─────────────────────────────────────────────────
  final int     id;
  final String  firstName;
  final String  lastName;
  final String  email;
  final String  role;           // 'customer/user' | 'staff' | 'admin'
  final String? profilePictureUrl;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.profilePictureUrl,
  });

  // ── Convenience getters ─────────────────────────────────────
  String get fullName => '$firstName $lastName';

  bool get isCustomer => role == roleCustomer;
  bool get isStaff    => role == roleStaff;
  bool get isAdmin    => role == roleAdmin;

  /// Staff OR Admin — use this to check business-side access
  bool get isStaffOrAdmin => isStaff || isAdmin;

  // ── Deserialisation ─────────────────────────────────────────
  // Backend returns: { id, firstName, lastName, email, role, profilePictureUrl? }
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:                 json['id']                as int,
    firstName:          json['firstName']         as String,
    lastName:           json['lastName']          as String,
    email:              json['email']             as String,
    role:               (json['role'] as String?) ?? roleCustomer,
    profilePictureUrl:  json['profilePictureUrl'] as String?,
  );

  // ── Serialisation (for local storage / cache if needed) ─────
  Map<String, dynamic> toJson() => {
    'id':                id,
    'firstName':         firstName,
    'lastName':          lastName,
    'email':             email,
    'role':              role,
    'profilePictureUrl': profilePictureUrl,
  };

  // ── Copy with ───────────────────────────────────────────────
  UserModel copyWith({
    int?    id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? profilePictureUrl,
  }) => UserModel(
    id:                id                ?? this.id,
    firstName:         firstName         ?? this.firstName,
    lastName:          lastName          ?? this.lastName,
    email:             email             ?? this.email,
    role:              role              ?? this.role,
    profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
  );
}