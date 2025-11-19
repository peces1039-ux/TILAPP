// Biometria Service
// Related: T025, FR-018, FR-019
// Manages biometric measurements with multi-tenancy support

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/biometria.dart';
import 'siembras_service.dart';
import 'tablas_alimentacion_service.dart';

class BiometriaService {
  final _supabase = Supabase.instance.client;
  final _siembrasService = SiembrasService();
  final _tablasAlimentacionService = TablasAlimentacionService();

  /// Get all biometria records for a specific siembra
  /// Filtered by current user (multi-tenancy)
  /// Related: T025, FR-018
  Future<List<Biometria>> getBySiembra(String siembraId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching biometria for siembra: $siembraId');

      final response = await _supabase
          .from('biometrias')
          .select()
          .eq('id_siembra', siembraId)
          .eq('user_id', user.id)
          .order('fecha', ascending: false);

      final biometrias = (response as List)
          .map((json) => Biometria.fromJson(json))
          .toList();

      debugPrint('Fetched ${biometrias.length} biometria records');
      return biometrias;
    } catch (e) {
      debugPrint('Error fetching biometria: $e');
      rethrow;
    }
  }

  /// Get all biometria records for current user
  /// Related: FR-018
  Future<List<Biometria>> getAll() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching all biometria for user: ${user.id}');

      final response = await _supabase
          .from('biometrias')
          .select()
          .eq('user_id', user.id)
          .order('fecha', ascending: false);

      final biometrias = (response as List)
          .map((json) => Biometria.fromJson(json))
          .toList();

      debugPrint('Fetched ${biometrias.length} biometria records');
      return biometrias;
    } catch (e) {
      debugPrint('Error fetching all biometria: $e');
      rethrow;
    }
  }

  /// Get biometria by ID
  /// Related: FR-018
  Future<Biometria?> getById(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching biometria: $id');

      final response = await _supabase
          .from('biometrias')
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('Biometria not found: $id');
        return null;
      }

      return Biometria.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching biometria by ID: $e');
      rethrow;
    }
  }

  /// Calculate biometrics values (biomasa, alimento diario, FCA)
  /// Related: Biometrics calculations feature
  Future<Map<String, double?>> _calculateBiometrics({
    required String siembraId,
    required double pesoPromedioGramos,
    required DateTime fecha,
  }) async {
    try {
      // Fetch siembra data to get current fish count
      final siembra = await _siembrasService.getById(siembraId);
      if (siembra == null) {
        throw Exception('Siembra no encontrada');
      }

      final cantidadActual =
          siembra.cantidadActual; // cantidad_inicial - cantidad_muertes

      // 1. Calculate Biomasa Total (g)
      // Formula: peso_promedio (grams) * cantidad_actual
      final biomasaTotal = pesoPromedioGramos * cantidadActual;
      debugPrint('=== CÁLCULO BIOMASA ===');
      debugPrint('Peso promedio: $pesoPromedioGramos g');
      debugPrint('Cantidad actual: $cantidadActual peces');
      debugPrint('Biomasa total: $biomasaTotal g');

      // 2. Calculate Cantidad de Alimento Diario (g/día)
      // Formula: biomasa_total * porcentaje_biomasa
      // Get porcentaje_biomasa from tabla_alimentacion based on peso_promedio
      double porcentajeBiomasa = 0.03; // Default 3% if no table found

      final tablaAplicable = await _tablasAlimentacionService
          .findApplicableTable(pesoPromedioGramos);
      if (tablaAplicable != null) {
        porcentajeBiomasa = tablaAplicable
            .porcentajeBiomasa; // Already in decimal format (0.15 = 15%)
        debugPrint(
          'Using tabla alimentacion: ${tablaAplicable.edadLabel} with porcentaje ${tablaAplicable.porcentajeBiomasa}',
        );
      } else {
        debugPrint(
          'No applicable tabla found for ${pesoPromedioGramos}g, using default 3%',
        );
      }

      final cantidadAlimentoDiario = biomasaTotal * porcentajeBiomasa;
      debugPrint('=== CÁLCULO ALIMENTO ===');
      debugPrint(
        'Porcentaje biomasa: $porcentajeBiomasa (${porcentajeBiomasa * 100}%)',
      );
      debugPrint('Alimento diario: $cantidadAlimentoDiario g/día');
      debugPrint('======================');

      // 3. Calculate FCA (Factor de Conversión Alimenticia)
      // Only if there's a previous biometry
      double? fca;
      double? alimentoAcumuladoAnterior; // For FCA calculation

      final previousBiometries = await getBySiembra(siembraId);
      // Filter biometries before current date
      final previousBio = previousBiometries
          .where((b) => b.fecha.isBefore(fecha))
          .toList();

      if (previousBio.isNotEmpty) {
        // Get the most recent previous biometry
        previousBio.sort((a, b) => b.fecha.compareTo(a.fecha));
        final lastBio = previousBio.first;

        // Calculate biomass increase (g)
        final biomasaAnterior = lastBio.biomasaTotal ?? 0;
        final aumentoBiomasa = biomasaTotal - biomasaAnterior;

        // Get accumulated food from the last biometry's alimento_acumulado column
        // This value is updated each time a ration is marked as completed
        alimentoAcumuladoAnterior = lastBio.alimentoAcumulado ?? 0;

        // Calculate FCA: alimento_suministrado / aumento_biomasa
        if (aumentoBiomasa > 0 && alimentoAcumuladoAnterior > 0) {
          fca = alimentoAcumuladoAnterior / aumentoBiomasa;
        }

        debugPrint('=== CÁLCULO FCA Y ALIMENTO ACUMULADO ===');
        debugPrint('Biometría anterior: ${lastBio.fecha}');
        debugPrint('Biomasa anterior: $biomasaAnterior g');
        debugPrint('Aumento biomasa: $aumentoBiomasa g');
        debugPrint(
          'Alimento acumulado (desde última biometría): $alimentoAcumuladoAnterior g',
        );
        debugPrint('FCA: ${fca ?? "null (sin aumento de biomasa)"}');
        debugPrint('========================================');
      }

      return {
        'biomasa_total': biomasaTotal,
        'cantidad_alimento_diario': cantidadAlimentoDiario,
        'fca': fca,
        'alimento_acumulado': 0.0, // Reset to 0 for new period
      };
    } catch (e) {
      debugPrint('Error calculating biometrics: $e');
      rethrow;
    }
  }

  /// Create a new biometria record
  /// Automatically adds current user_id and calculates biometrics
  /// Related: T025, FR-018, FR-019
  Future<Biometria> create(Biometria biometria) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validations
      if (biometria.pesoPromedio <= 0) {
        throw Exception('El peso promedio debe ser mayor a 0');
      }

      if (biometria.tamanoPromedio <= 0) {
        throw Exception('El tamaño promedio debe ser mayor a 0');
      }

      debugPrint('Creating biometria for siembra: ${biometria.siembraId}');

      // Calculate biometrics values
      final calculations = await _calculateBiometrics(
        siembraId: biometria.siembraId,
        pesoPromedioGramos: biometria.pesoPromedio,
        fecha: biometria.fecha,
      );

      // Create biometria with calculated values
      final biometriaWithCalculations = biometria.copyWith(
        biomasaTotal: calculations['biomasa_total'],
        cantidadAlimentoDiario: calculations['cantidad_alimento_diario'],
        fca: calculations['fca'],
        alimentoAcumulado: calculations['alimento_acumulado'],
      );

      final data = biometriaWithCalculations.toJson();
      data['user_id'] = user.id; // Auto-add user_id for multi-tenancy
      data.remove('id'); // Remove id - let database generate it
      data.remove('created_at'); // Remove created_at - let database generate it

      final response = await _supabase
          .from('biometrias')
          .insert(data)
          .select()
          .single();

      debugPrint('Biometria created successfully: ${response['id']}');
      return Biometria.fromJson(response);
    } catch (e) {
      debugPrint('Error creating biometria: $e');
      rethrow;
    }
  }

  /// Update an existing biometria record
  /// Recalculates biometrics values
  /// Related: T025, FR-019
  Future<void> update(Biometria biometria) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validations
      if (biometria.pesoPromedio <= 0) {
        throw Exception('El peso promedio debe ser mayor a 0');
      }

      if (biometria.tamanoPromedio <= 0) {
        throw Exception('El tamaño promedio debe ser mayor a 0');
      }

      debugPrint('Updating biometria: ${biometria.id}');

      // Recalculate biometrics values
      final calculations = await _calculateBiometrics(
        siembraId: biometria.siembraId,
        pesoPromedioGramos: biometria.pesoPromedio,
        fecha: biometria.fecha,
      );

      // Update biometria with recalculated values
      final biometriaWithCalculations = biometria.copyWith(
        biomasaTotal: calculations['biomasa_total'],
        cantidadAlimentoDiario: calculations['cantidad_alimento_diario'],
        fca: calculations['fca'],
        alimentoAcumulado: calculations['alimento_acumulado'],
      );

      final data = biometriaWithCalculations.toJson();

      await _supabase
          .from('biometrias')
          .update(data)
          .eq('id', biometria.id)
          .eq('user_id', user.id); // Ensure user owns this record

      debugPrint('Biometria updated successfully');
    } catch (e) {
      debugPrint('Error updating biometria: $e');
      rethrow;
    }
  }

  /// Delete a biometria record
  /// Related: T025, FR-019
  Future<void> delete(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Deleting biometria: $id');

      await _supabase
          .from('biometrias')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id); // Ensure user owns this record

      debugPrint('Biometria deleted successfully');
    } catch (e) {
      debugPrint('Error deleting biometria: $e');
      rethrow;
    }
  }

  /// Get latest biometria for a siembra
  /// Used for feeding calculations
  /// Related: FR-023
  Future<Biometria?> getLatestBySiembra(String siembraId) async {
    try {
      final biometrias = await getBySiembra(siembraId);
      if (biometrias.isEmpty) return null;

      // Already sorted by fecha DESC, so first is latest
      return biometrias.first;
    } catch (e) {
      debugPrint('Error getting latest biometria: $e');
      return null;
    }
  }

  /// Calculate growth rate between two biometria records
  /// Returns percentage growth per day
  Future<double?> calculateGrowthRate({
    required String siembraId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final biometrias = await getBySiembra(siembraId);

      // Filter by date range
      final startBio = biometrias
          .where(
            (b) =>
                b.fecha.isAtSameMomentAs(startDate) ||
                b.fecha.isAfter(startDate.subtract(const Duration(days: 1))),
          )
          .toList();

      final endBio = biometrias
          .where(
            (b) =>
                b.fecha.isAtSameMomentAs(endDate) ||
                b.fecha.isBefore(endDate.add(const Duration(days: 1))),
          )
          .toList();

      if (startBio.isEmpty || endBio.isEmpty) return null;

      final startPeso = startBio.first.pesoPromedio;
      final endPeso = endBio.first.pesoPromedio;
      final days = endDate.difference(startDate).inDays;

      if (days <= 0 || startPeso <= 0) return null;

      final growthRate = ((endPeso - startPeso) / startPeso) * 100 / days;
      return growthRate;
    } catch (e) {
      debugPrint('Error calculating growth rate: $e');
      return null;
    }
  }
}
