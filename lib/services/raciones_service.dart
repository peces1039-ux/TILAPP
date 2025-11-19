// Raciones Service
// Handles all database operations for feeding rations

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/racion.dart';
import '../models/biometria.dart';
import '../models/tabla_alimentacion.dart';
import 'biometria_service.dart';

class RacionesService {
  final _supabase = Supabase.instance.client;
  final _biometriaService = BiometriaService();

  // Get raciones for a specific siembra and date
  Future<List<Racion>> getRacionesByFecha(
    String siembraId,
    DateTime fecha,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final dateStr = fecha.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('raciones_alimentacion')
          .select()
          .eq('user_id', userId)
          .eq('siembra_id', siembraId)
          .eq('fecha', dateStr)
          .order('numero_racion', ascending: true);

      return (response as List)
          .map((json) => Racion.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error loading raciones: $e');
    }
  }

  // Get all raciones for a siembra (for history)
  Future<List<Racion>> getRacionesBySiembra(String siembraId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('raciones_alimentacion')
          .select()
          .eq('user_id', userId)
          .eq('siembra_id', siembraId)
          .order('fecha', ascending: false)
          .order('numero_racion', ascending: true);

      return (response as List)
          .map((json) => Racion.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error loading raciones history: $e');
    }
  }

  // Get raciones for a date range
  Future<List<Racion>> getRacionesByDateRange(
    String siembraId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('raciones_alimentacion')
          .select()
          .eq('user_id', userId)
          .eq('siembra_id', siembraId)
          .gte('fecha', startDateStr)
          .lte('fecha', endDateStr)
          .order('fecha', ascending: false)
          .order('numero_racion', ascending: true);

      return (response as List)
          .map((json) => Racion.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error loading raciones by date range: $e');
    }
  }

  // Generate daily raciones based on biometria and feeding table
  Future<List<Racion>> generateDailyRaciones({
    required String siembraId,
    required DateTime fecha,
    required Biometria ultimaBiometria,
    required TablaAlimentacion tablaAlimentacion,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if raciones already exist for this date
      final existing = await getRacionesByFecha(siembraId, fecha);
      if (existing.isNotEmpty) {
        return existing; // Return existing raciones
      }

      // Calculate cantidad por racion
      final cantidadDiaria = ultimaBiometria.cantidadAlimentoDiario ?? 0.0;
      final racionesDiarias = tablaAlimentacion.racionesDiarias;

      if (racionesDiarias <= 0 || cantidadDiaria <= 0) {
        return []; // No raciones to generate
      }

      final cantidadPorRacion = cantidadDiaria / racionesDiarias;

      // Calculate schedule times (8:00 AM to 5:00 PM)
      const horaInicio = 8; // 8 AM
      const horaFin = 17; // 5 PM
      const minutosDisponibles = (horaFin - horaInicio) * 60;

      final List<Racion> raciones = [];

      if (racionesDiarias == 1) {
        // Single ration at noon
        final horaProgramada = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          12,
          0,
        );
        raciones.add(
          Racion(
            id: 'temp-${DateTime.now().millisecondsSinceEpoch}-1',
            userId: userId,
            siembraId: siembraId,
            fecha: fecha,
            numeroRacion: 1,
            horaProgramada: horaProgramada,
            cantidadGramos: cantidadPorRacion,
            completada: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        // Distribute evenly
        final intervaloMinutos = minutosDisponibles ~/ (racionesDiarias - 1);

        for (int i = 0; i < racionesDiarias; i++) {
          final minutosDesdeInicio = i * intervaloMinutos;
          final hora = horaInicio + (minutosDesdeInicio ~/ 60);
          final minutos = minutosDesdeInicio % 60;

          final horaProgramada = DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
            hora,
            minutos,
          );

          raciones.add(
            Racion(
              id: 'temp-${DateTime.now().millisecondsSinceEpoch}-${i + 1}',
              userId: userId,
              siembraId: siembraId,
              fecha: fecha,
              numeroRacion: i + 1,
              horaProgramada: horaProgramada,
              cantidadGramos: cantidadPorRacion,
              completada: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      // Insert all raciones into database (omit id field, let Supabase generate it)
      final racionesJson = raciones.map((r) {
        final json = r.toJson();
        json.remove('id'); // Remove temporary ID, let DB generate UUID
        return json;
      }).toList();

      final insertedData = await _supabase
          .from('raciones_alimentacion')
          .insert(racionesJson)
          .select();

      // Convert inserted data back to Racion objects with real IDs
      return (insertedData as List)
          .map((json) => Racion.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error generating daily raciones: $e');
    }
  }

  // Mark a racion as completed
  Future<void> markAsCompleted(String racionId, {String? observaciones}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // First, get the racion details to know siembra_id and cantidad
      final racionData = await _supabase
          .from('raciones_alimentacion')
          .select()
          .eq('id', racionId)
          .eq('user_id', userId)
          .single();

      final racion = Racion.fromJson(racionData);

      // Update the racion as completed
      await _supabase
          .from('raciones_alimentacion')
          .update({
            'completada': true,
            'hora_completada': DateTime.now().toIso8601String(),
            'observaciones': observaciones,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', racionId)
          .eq('user_id', userId);

      // Update alimento_acumulado in the latest biometria
      await _updateAlimentoAcumulado(racion.siembraId, racion.cantidadGramos);
    } catch (e) {
      throw Exception('Error marking racion as completed: $e');
    }
  }

  // Mark a racion as not completed (undo)
  Future<void> markAsNotCompleted(String racionId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // First, get the racion details to know siembra_id and cantidad
      final racionData = await _supabase
          .from('raciones_alimentacion')
          .select()
          .eq('id', racionId)
          .eq('user_id', userId)
          .single();

      final racion = Racion.fromJson(racionData);

      // Update the racion as not completed
      await _supabase
          .from('raciones_alimentacion')
          .update({
            'completada': false,
            'hora_completada': null,
            'observaciones': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', racionId)
          .eq('user_id', userId);

      // Subtract from alimento_acumulado in the latest biometria
      await _updateAlimentoAcumulado(racion.siembraId, -racion.cantidadGramos);
    } catch (e) {
      throw Exception('Error marking racion as not completed: $e');
    }
  }

  // Update alimento_acumulado in the latest biometria
  Future<void> _updateAlimentoAcumulado(
    String siembraId,
    double cantidadGramos,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get the latest biometria for this siembra
      final biometriaData = await _supabase
          .from('biometrias')
          .select()
          .eq('user_id', userId)
          .eq('id_siembra', siembraId)
          .order('fecha', ascending: false)
          .limit(1)
          .maybeSingle();

      if (biometriaData == null) {
        // No biometria yet, nothing to update
        return;
      }

      final biometria = Biometria.fromJson(biometriaData);
      final currentAlimento = biometria.alimentoAcumulado ?? 0.0;
      final newAlimento = currentAlimento + cantidadGramos;

      // Update the alimento_acumulado
      await _supabase
          .from('biometrias')
          .update({
            'alimento_acumulado': newAlimento.clamp(0.0, double.infinity),
          })
          .eq('id', biometria.id)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error updating alimento acumulado: $e');
    }
  }

  // Update observaciones for a racion
  Future<void> updateObservaciones(
    String racionId,
    String observaciones,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('raciones_alimentacion')
          .update({
            'observaciones': observaciones,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', racionId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error updating observaciones: $e');
    }
  }

  // Delete all raciones for a specific date (useful for regeneration)
  Future<void> deleteRacionesByFecha(String siembraId, DateTime fecha) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final dateStr = fecha.toIso8601String().split('T')[0];

      await _supabase
          .from('raciones_alimentacion')
          .delete()
          .eq('user_id', userId)
          .eq('siembra_id', siembraId)
          .eq('fecha', dateStr);
    } catch (e) {
      throw Exception('Error deleting raciones: $e');
    }
  }

  // Get summary statistics for a siembra
  Future<Map<String, dynamic>> getSummary(String siembraId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('raciones_alimentacion')
          .select()
          .eq('user_id', userId)
          .eq('siembra_id', siembraId);

      final raciones = (response as List)
          .map((json) => Racion.fromJson(json as Map<String, dynamic>))
          .toList();

      final totalRaciones = raciones.length;
      final completadas = raciones.where((r) => r.completada).length;
      final pendientes = totalRaciones - completadas;
      final totalAlimento = raciones.fold<double>(
        0,
        (sum, r) => sum + r.cantidadGramos,
      );
      final alimentoSuministrado = raciones
          .where((r) => r.completada)
          .fold<double>(0, (sum, r) => sum + r.cantidadGramos);

      return {
        'total_raciones': totalRaciones,
        'completadas': completadas,
        'pendientes': pendientes,
        'total_alimento_programado': totalAlimento,
        'alimento_suministrado': alimentoSuministrado,
        'porcentaje_cumplimiento': totalRaciones > 0
            ? (completadas / totalRaciones) * 100
            : 0,
      };
    } catch (e) {
      throw Exception('Error getting summary: $e');
    }
  }
}
