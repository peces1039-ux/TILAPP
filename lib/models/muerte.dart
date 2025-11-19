// Muerte Model
// Related: T018, FR-020 to FR-022
// Represents a fish death record in a siembra

class Muerte {
  final String id; // UUID
  final String userId; // FK to auth.users
  final String siembraId; // FK to siembras
  final DateTime fecha; // Death date
  final int cantidad; // Number of fish that died
  final String? observaciones; // Optional notes
  final DateTime createdAt;

  Muerte({
    required this.id,
    required this.userId,
    required this.siembraId,
    required this.fecha,
    required this.cantidad,
    this.observaciones,
    required this.createdAt,
  });

  // Create from Supabase JSON
  factory Muerte.fromJson(Map<String, dynamic> json) {
    return Muerte(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      siembraId: json['siembra_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      cantidad: json['cantidad'] as int,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'siembra_id': siembraId,
      'fecha': fecha.toIso8601String().split('T')[0], // Date only
      'cantidad': cantidad,
      if (observaciones != null) 'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  Muerte copyWith({DateTime? fecha, int? cantidad, String? observaciones}) {
    return Muerte(
      id: id,
      userId: userId,
      siembraId: siembraId,
      fecha: fecha ?? this.fecha,
      cantidad: cantidad ?? this.cantidad,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt,
    );
  }

  // Check if has observations
  bool get hasObservaciones =>
      observaciones != null && observaciones!.isNotEmpty;
}
