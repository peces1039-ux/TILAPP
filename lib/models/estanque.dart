// Estanque Model
// Related: T015, FR-008 to FR-010, FR-017
// Represents a fish pond with multi-tenancy support

class Estanque {
  final int id; // INTEGER primary key
  final String userId; // FK to auth.users
  final String numero; // Must be unique within user_id scope (FR-017)
  final double capacidad; // Capacity in cubic meters
  final DateTime createdAt;
  final DateTime updatedAt;

  Estanque({
    required this.id,
    required this.userId,
    required this.numero,
    required this.capacidad,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Supabase JSON
  factory Estanque.fromJson(Map<String, dynamic> json) {
    return Estanque(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      numero: json['numero'] as String,
      capacidad: (json['capacidad'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'numero': numero,
      'capacidad': capacidad,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  Estanque copyWith({String? numero, double? capacidad, DateTime? updatedAt}) {
    return Estanque(
      id: id,
      userId: userId,
      numero: numero ?? this.numero,
      capacidad: capacidad ?? this.capacidad,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Display name for UI
  String get displayName => 'Estanque $numero';
}
