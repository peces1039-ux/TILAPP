// Siembra Model
// Related: T016, FR-011 to FR-015
// Represents a fish seeding/stocking event in an estanque

class Siembra {
  final String id; // UUID
  final String userId; // FK to auth.users
  final int idEstanque; // FK to estanques (INTEGER)
  final String especie; // Fish species
  final DateTime fechaSiembra; // Seeding date
  final int cantidadInicial; // Initial fish count
  final int cantidadMuertes; // Total deaths accumulated
  final bool cosechada; // Harvest status
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? nombreEstanque; // Optional: estanque name from JOIN

  Siembra({
    required this.id,
    required this.userId,
    required this.idEstanque,
    required this.especie,
    required this.fechaSiembra,
    required this.cantidadInicial,
    required this.cantidadMuertes,
    this.cosechada = false,
    required this.createdAt,
    required this.updatedAt,
    this.nombreEstanque,
  });

  // Create from Supabase JSON
  factory Siembra.fromJson(Map<String, dynamic> json) {
    return Siembra(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      idEstanque: json['id_estanque'] as int,
      especie: json['especie'] as String,
      fechaSiembra: DateTime.parse(json['fecha_siembra'] as String),
      cantidadInicial: json['cantidad_inicial'] as int,
      cantidadMuertes: json['cantidad_muertes'] as int? ?? 0,
      cosechada: json['cosechada'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      nombreEstanque: json['nombre_estanque'] as String?,
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'id_estanque': idEstanque,
      'especie': especie,
      'fecha_siembra': fechaSiembra.toIso8601String(),
      'cantidad_inicial': cantidadInicial,
      'cantidad_muertes': cantidadMuertes,
      'cosechada': cosechada,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  Siembra copyWith({
    String? especie,
    DateTime? fechaSiembra,
    int? cantidadInicial,
    int? cantidadMuertes,
    bool? cosechada,
    DateTime? updatedAt,
  }) {
    return Siembra(
      id: id,
      userId: userId,
      idEstanque: idEstanque,
      especie: especie ?? this.especie,
      fechaSiembra: fechaSiembra ?? this.fechaSiembra,
      cantidadInicial: cantidadInicial ?? this.cantidadInicial,
      cantidadMuertes: cantidadMuertes ?? this.cantidadMuertes,
      cosechada: cosechada ?? this.cosechada,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      nombreEstanque: nombreEstanque,
    );
  }

  // Computed property: current fish count
  int get cantidadActual => cantidadInicial - cantidadMuertes;

  // Calculate survival rate
  double get survivalRate {
    if (cantidadInicial == 0) return 0.0;
    return (cantidadActual / cantidadInicial) * 100;
  }

  // Calculate mortality rate
  double get mortalityRate => 100 - survivalRate;

  // Check if siembra is active (not harvested and has fish)
  bool get isActive => !cosechada && cantidadActual > 0;
}
