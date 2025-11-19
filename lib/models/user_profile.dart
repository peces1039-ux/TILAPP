// User Profile Model
// Related: T014, FR-026 to FR-031, FR-056
// Represents a user profile with role and soft-delete support

class UserProfile {
  final String id; // UUID from auth.users
  final String email;
  final String nombre;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? deletedAt; // Soft-delete support

  UserProfile({
    required this.id,
    required this.email,
    required this.nombre,
    required this.role,
    required this.createdAt,
    this.deletedAt,
  });

  // Create from Supabase JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      nombre: json['nombre'] as String,
      role: UserRole.fromString(json['role'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  // Check if account is soft-deleted
  bool get isDeleted => deletedAt != null;

  // Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  // Copy with method for updates
  UserProfile copyWith({
    String? email,
    String? nombre,
    UserRole? role,
    DateTime? deletedAt,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      role: role ?? this.role,
      createdAt: createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

// User Role Enum
enum UserRole {
  admin('admin'),
  user('user');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
        return UserRole.user;
      default:
        throw ArgumentError('Invalid user role: $role');
    }
  }

  @override
  String toString() => value;
}
