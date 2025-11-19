// Racion Model
// Represents a daily feeding ration for a siembra

class Racion {
  final String id; // UUID
  final String userId; // FK to auth.users
  final String siembraId; // FK to siembras
  final DateTime fecha; // Date of the ration
  final int numeroRacion; // Ration number (1, 2, 3, etc.)
  final DateTime horaProgramada; // Scheduled time
  final double cantidadGramos; // Amount in grams
  final bool completada; // Whether the ration was completed
  final DateTime? horaCompletada; // When it was completed
  final String? observaciones; // Optional notes
  final DateTime createdAt;
  final DateTime updatedAt;

  Racion({
    required this.id,
    required this.userId,
    required this.siembraId,
    required this.fecha,
    required this.numeroRacion,
    required this.horaProgramada,
    required this.cantidadGramos,
    required this.completada,
    this.horaCompletada,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Supabase JSON
  factory Racion.fromJson(Map<String, dynamic> json) {
    // Parse date and time separately
    final fecha = DateTime.parse(json['fecha'] as String);
    final horaProgramadaStr = json['hora_programada'] as String;

    // Parse time (format: HH:mm:ss or HH:mm:ss.ffffff)
    final timeParts = horaProgramadaStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = timeParts.length > 2
        ? int.parse(timeParts[2].split('.')[0])
        : 0;

    final horaProgramada = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hour,
      minute,
      second,
    );

    return Racion(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      siembraId: json['siembra_id'] as String,
      fecha: fecha,
      numeroRacion: json['numero_racion'] as int,
      horaProgramada: horaProgramada,
      cantidadGramos: (json['cantidad_gramos'] as num).toDouble(),
      completada: json['completada'] as bool? ?? false,
      horaCompletada: json['hora_completada'] != null
          ? DateTime.parse(json['hora_completada'] as String)
          : null,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'siembra_id': siembraId,
      'fecha': fecha.toIso8601String().split('T')[0], // Date only
      'numero_racion': numeroRacion,
      'hora_programada':
          '${horaProgramada.hour.toString().padLeft(2, '0')}:${horaProgramada.minute.toString().padLeft(2, '0')}:00',
      'cantidad_gramos': cantidadGramos,
      'completada': completada,
      'hora_completada': horaCompletada?.toIso8601String(),
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  Racion copyWith({
    bool? completada,
    DateTime? horaCompletada,
    String? observaciones,
  }) {
    return Racion(
      id: id,
      userId: userId,
      siembraId: siembraId,
      fecha: fecha,
      numeroRacion: numeroRacion,
      horaProgramada: horaProgramada,
      cantidadGramos: cantidadGramos,
      completada: completada ?? this.completada,
      horaCompletada: horaCompletada ?? this.horaCompletada,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Format cantidad for display
  String get cantidadFormatted => '${cantidadGramos.toStringAsFixed(2)} g';

  // Format hora programada for display
  String get horaProgramadaFormatted =>
      '${horaProgramada.hour.toString().padLeft(2, '0')}:${horaProgramada.minute.toString().padLeft(2, '0')}';

  // Format hora completada for display
  String get horaCompletadaFormatted => horaCompletada != null
      ? '${horaCompletada!.hour.toString().padLeft(2, '0')}:${horaCompletada!.minute.toString().padLeft(2, '0')}'
      : 'N/A';

  // Check if the ration is past due
  bool get isPastDue {
    if (completada) return false;
    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      horaProgramada.hour,
      horaProgramada.minute,
    );
    return now.isAfter(scheduledDateTime);
  }
}
