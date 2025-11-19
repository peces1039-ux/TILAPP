// Biometria Model
// Related: T017, FR-018, FR-019
// Represents a biometric measurement of fish in a siembra

class Biometria {
  final String id; // UUID
  final String userId; // FK to auth.users
  final String siembraId; // FK to siembras
  final DateTime fecha; // Measurement date
  final double pesoPromedio; // Average weight in grams
  final double tamanoPromedio; // Average size in cm
  final double? biomasaTotal; // Total biomass in grams
  final double? cantidadAlimentoDiario; // Daily food amount in grams
  final double? fca; // Feed Conversion Ratio (null for first biometry)
  final double?
  alimentoAcumulado; // Accumulated food since previous biometry in grams
  final DateTime createdAt;

  Biometria({
    required this.id,
    required this.userId,
    required this.siembraId,
    required this.fecha,
    required this.pesoPromedio,
    required this.tamanoPromedio,
    this.biomasaTotal,
    this.cantidadAlimentoDiario,
    this.fca,
    this.alimentoAcumulado,
    required this.createdAt,
  });

  // Create from Supabase JSON
  factory Biometria.fromJson(Map<String, dynamic> json) {
    return Biometria(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      siembraId: json['id_siembra'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      pesoPromedio: (json['peso_promedio'] as num).toDouble(),
      tamanoPromedio: (json['largo'] as num).toDouble(),
      biomasaTotal: json['biomasa_total'] != null
          ? (json['biomasa_total'] as num).toDouble()
          : null,
      cantidadAlimentoDiario: json['cantidad_alimento_diario'] != null
          ? (json['cantidad_alimento_diario'] as num).toDouble()
          : null,
      fca: json['fca'] != null ? (json['fca'] as num).toDouble() : null,
      alimentoAcumulado: json['alimento_acumulado'] != null
          ? (json['alimento_acumulado'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'id_siembra': siembraId,
      'fecha': fecha.toIso8601String().split('T')[0], // Date only
      'peso_promedio': pesoPromedio,
      'largo': tamanoPromedio,
      'biomasa_total': biomasaTotal,
      'cantidad_alimento_diario': cantidadAlimentoDiario,
      'fca': fca,
      'alimento_acumulado': alimentoAcumulado,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  Biometria copyWith({
    DateTime? fecha,
    double? pesoPromedio,
    double? tamanoPromedio,
    double? biomasaTotal,
    double? cantidadAlimentoDiario,
    double? fca,
    double? alimentoAcumulado,
  }) {
    return Biometria(
      id: id,
      userId: userId,
      siembraId: siembraId,
      fecha: fecha ?? this.fecha,
      pesoPromedio: pesoPromedio ?? this.pesoPromedio,
      tamanoPromedio: tamanoPromedio ?? this.tamanoPromedio,
      biomasaTotal: biomasaTotal ?? this.biomasaTotal,
      cantidadAlimentoDiario:
          cantidadAlimentoDiario ?? this.cantidadAlimentoDiario,
      fca: fca ?? this.fca,
      alimentoAcumulado: alimentoAcumulado ?? this.alimentoAcumulado,
      createdAt: createdAt,
    );
  }

  // Format peso for display
  String get pesoFormatted => '${pesoPromedio.toStringAsFixed(1)} g';

  // Format tamano for display
  String get tamanoFormatted => '${tamanoPromedio.toStringAsFixed(1)} cm';

  // Format biomasa total for display
  String get biomasaTotalFormatted =>
      biomasaTotal != null ? '${biomasaTotal!.toStringAsFixed(2)} g' : 'N/A';

  // Format cantidad alimento diario for display
  String get cantidadAlimentoFormatted => cantidadAlimentoDiario != null
      ? '${cantidadAlimentoDiario!.toStringAsFixed(2)} g/día'
      : 'N/A';

  // Format FCA for display
  String get fcaFormatted =>
      fca != null ? fca!.toStringAsFixed(2) : 'N/A (Primera biometría)';

  // Format alimento acumulado for display
  String get alimentoAcumuladoFormatted => alimentoAcumulado != null
      ? '${alimentoAcumulado!.toStringAsFixed(2)} g'
      : '0.00 g';
}
