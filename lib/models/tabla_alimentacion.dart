// Tabla Alimentacion Model
// Related: T019, FR-023 to FR-025
// Shared reference data model for feeding schedule by age and weight ranges
// NO multi-tenancy: accessible by all users

class TablaAlimentacion {
  final String id; // UUID
  final int edadSemanas; // Age in weeks
  final double pesoMinGramos; // Minimum fish weight in grams
  final double pesoMaxGramos; // Maximum fish weight in grams
  final double porcentajeBiomasa; // Percentage of biomass to feed per day
  final String referenciaAlimento; // Feed reference
  final int racionesDiarias; // Number of daily rations
  final DateTime createdAt;
  final DateTime updatedAt;

  TablaAlimentacion({
    required this.id,
    required this.edadSemanas,
    required this.pesoMinGramos,
    required this.pesoMaxGramos,
    required this.porcentajeBiomasa,
    required this.referenciaAlimento,
    required this.racionesDiarias,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Supabase JSON
  factory TablaAlimentacion.fromJson(Map<String, dynamic> json) {
    return TablaAlimentacion(
      id: json['id'] as String,
      edadSemanas: json['edad_semanas'] as int,
      pesoMinGramos: (json['peso_min_gramos'] as num).toDouble(),
      pesoMaxGramos: (json['peso_max_gramos'] as num).toDouble(),
      porcentajeBiomasa: (json['porcentaje_biomasa'] as num).toDouble(),
      referenciaAlimento: json['referencia_alimento'] as String,
      racionesDiarias: json['raciones_diarias'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'edad_semanas': edadSemanas,
      'peso_min_gramos': pesoMinGramos,
      'peso_max_gramos': pesoMaxGramos,
      'porcentaje_biomasa': porcentajeBiomasa,
      'referencia_alimento': referenciaAlimento,
      'raciones_diarias': racionesDiarias,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  TablaAlimentacion copyWith({
    int? edadSemanas,
    double? pesoMinGramos,
    double? pesoMaxGramos,
    double? porcentajeBiomasa,
    String? referenciaAlimento,
    int? racionesDiarias,
    DateTime? updatedAt,
  }) {
    return TablaAlimentacion(
      id: id,
      edadSemanas: edadSemanas ?? this.edadSemanas,
      pesoMinGramos: pesoMinGramos ?? this.pesoMinGramos,
      pesoMaxGramos: pesoMaxGramos ?? this.pesoMaxGramos,
      porcentajeBiomasa: porcentajeBiomasa ?? this.porcentajeBiomasa,
      referenciaAlimento: referenciaAlimento ?? this.referenciaAlimento,
      racionesDiarias: racionesDiarias ?? this.racionesDiarias,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Check if a given fish weight (in grams) falls within this table's range
  bool isApplicableForWeight(double pesoGramos) {
    return pesoGramos >= pesoMinGramos && pesoGramos <= pesoMaxGramos;
  }

  // Check if a given age (in weeks) matches this table
  bool isApplicableForAge(int semanas) {
    return semanas == edadSemanas;
  }

  // Calculate daily food amount for a given total biomass (in kg)
  double calculateDailyFood(double totalBiomassKg) {
    return totalBiomassKg *
        1000 *
        (porcentajeBiomasa / 100); // Convert to grams
  }

  // Calculate food per ration (in grams)
  double calculateFoodPerRation(double totalBiomassKg) {
    return calculateDailyFood(totalBiomassKg) / racionesDiarias;
  }

  // Format weight range for display
  String get rangeFormatted =>
      '${pesoMinGramos.toStringAsFixed(0)}-${pesoMaxGramos.toStringAsFixed(0)} g';

  // Format percentage for display
  String get percentageFormatted => '${porcentajeBiomasa.toStringAsFixed(1)}%';

  // Display label for age
  String get edadLabel => '$edadSemanas semanas';
}
