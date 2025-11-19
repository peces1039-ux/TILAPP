// Tablas Alimentacion Service
// Related: T027, FR-023 to FR-025
// Manages shared feeding reference tables (NO multi-tenancy)
// Security enforced via RLS: SELECT = all authenticated users, INSERT/UPDATE/DELETE = admin only

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/tabla_alimentacion.dart';

class TablasAlimentacionService {
  final _supabase = Supabase.instance.client;

  /// Get all tabla_alimentacion records (shared across all users)
  /// Related: T027, FR-023
  Future<List<TablaAlimentacion>> getAll() async {
    try {
      debugPrint('Fetching all tabla_alimentacion records');

      final response = await _supabase
          .from('tabla_alimentacion')
          .select()
          .order('edad_semanas', ascending: true);

      final tablas = (response as List)
          .map((json) => TablaAlimentacion.fromJson(json))
          .toList();

      debugPrint('Fetched ${tablas.length} tabla_alimentacion records');
      return tablas;
    } catch (e) {
      debugPrint('Error fetching tabla_alimentacion: $e');
      rethrow;
    }
  }

  /// Get tabla_alimentacion by ID (shared data)
  /// Related: FR-024
  Future<TablaAlimentacion?> getById(String id) async {
    try {
      debugPrint('Fetching tabla_alimentacion: $id');

      final response = await _supabase
          .from('tabla_alimentacion')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        debugPrint('Tabla_alimentacion not found: $id');
        return null;
      }

      return TablaAlimentacion.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching tabla_alimentacion by ID: $e');
      rethrow;
    }
  }

  /// Find applicable tabla_alimentacion for a given fish weight (in grams)
  /// Related: FR-023
  Future<TablaAlimentacion?> findApplicableTable(double pesoGramos) async {
    try {
      final tablas = await getAll();

      // Find first table where peso falls within range
      for (final tabla in tablas) {
        if (tabla.isApplicableForWeight(pesoGramos)) {
          debugPrint(
            'Found applicable table for ${tabla.edadLabel}: peso ${pesoGramos}g',
          );
          return tabla;
        }
      }

      debugPrint('No applicable table found for peso: ${pesoGramos}g');
      return null;
    } catch (e) {
      debugPrint('Error finding applicable table: $e');
      return null;
    }
  }

  /// Create a new tabla_alimentacion (admin only via RLS)
  /// Related: T027, FR-024
  Future<TablaAlimentacion> create(TablaAlimentacion tabla) async {
    try {
      // Validations
      if (tabla.edadSemanas <= 0) {
        throw Exception('La edad en semanas debe ser mayor a 0');
      }

      if (tabla.pesoMinGramos < 0) {
        throw Exception('El peso mínimo debe ser mayor o igual a 0');
      }

      if (tabla.pesoMaxGramos < tabla.pesoMinGramos) {
        throw Exception('El peso máximo debe ser mayor o igual al peso mínimo');
      }

      if (tabla.porcentajeBiomasa <= 0 || tabla.porcentajeBiomasa > 100) {
        throw Exception('El porcentaje de biomasa debe estar entre 0 y 100');
      }

      if (tabla.referenciaAlimento.trim().isEmpty) {
        throw Exception('La referencia de alimento es requerida');
      }

      if (tabla.racionesDiarias <= 0) {
        throw Exception('Las raciones diarias deben ser mayores a 0');
      }

      debugPrint('Creating tabla_alimentacion: ${tabla.edadLabel}');

      final data = tabla.toJson();

      final response = await _supabase
          .from('tabla_alimentacion')
          .insert(data)
          .select()
          .single();

      debugPrint('Tabla_alimentacion created successfully: ${response['id']}');
      return TablaAlimentacion.fromJson(response);
    } catch (e) {
      debugPrint('Error creating tabla_alimentacion: $e');
      rethrow;
    }
  }

  /// Update an existing tabla_alimentacion (admin only via RLS)
  /// Related: T027, FR-025
  Future<void> update(TablaAlimentacion tabla) async {
    try {
      // Same validations as create
      if (tabla.edadSemanas <= 0) {
        throw Exception('La edad en semanas debe ser mayor a 0');
      }

      if (tabla.pesoMinGramos < 0) {
        throw Exception('El peso mínimo debe ser mayor o igual a 0');
      }

      if (tabla.pesoMaxGramos < tabla.pesoMinGramos) {
        throw Exception('El peso máximo debe ser mayor o igual al peso mínimo');
      }

      if (tabla.porcentajeBiomasa <= 0 || tabla.porcentajeBiomasa > 100) {
        throw Exception('El porcentaje de biomasa debe estar entre 0 y 100');
      }

      if (tabla.referenciaAlimento.trim().isEmpty) {
        throw Exception('La referencia de alimento es requerida');
      }

      if (tabla.racionesDiarias <= 0) {
        throw Exception('Las raciones diarias deben ser mayores a 0');
      }

      debugPrint('Updating tabla_alimentacion: ${tabla.id}');

      final data = tabla.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('tabla_alimentacion')
          .update(data)
          .eq('id', tabla.id);

      debugPrint('Tabla_alimentacion updated successfully');
    } catch (e) {
      debugPrint('Error updating tabla_alimentacion: $e');
      rethrow;
    }
  }

  /// Delete a tabla_alimentacion (admin only via RLS)
  /// Related: T027, FR-025
  Future<void> delete(String id) async {
    try {
      debugPrint('Deleting tabla_alimentacion: $id');

      await _supabase.from('tabla_alimentacion').delete().eq('id', id);

      debugPrint('Tabla_alimentacion deleted successfully');
    } catch (e) {
      debugPrint('Error deleting tabla_alimentacion: $e');
      rethrow;
    }
  }

  /// Calculate daily food amount for a siembra
  /// Related: FR-023
  Future<double> calculateDailyFood({
    required double pesoPromedio,
    required int cantidadPeces,
  }) async {
    try {
      // pesoPromedio is already in grams
      final pesoGramos = pesoPromedio;

      final tabla = await findApplicableTable(pesoGramos);
      if (tabla == null) {
        throw Exception(
          'No se encontró tabla de alimentación aplicable para peso: ${pesoGramos}g',
        );
      }

      // Calculate total biomass in kg for the calculation
      final totalBiomassKg = (pesoPromedio / 1000) * cantidadPeces;
      final dailyFood = tabla.calculateDailyFood(totalBiomassKg);

      debugPrint(
        'Calculated daily food: $dailyFood kg for biomass: $totalBiomassKg kg',
      );
      return dailyFood;
    } catch (e) {
      debugPrint('Error calculating daily food: $e');
      rethrow;
    }
  }

  /// Calculate food per feeding for a siembra
  /// Related: FR-023
  Future<Map<String, dynamic>> calculateFeedingSchedule({
    required double pesoPromedio,
    required int cantidadPeces,
  }) async {
    try {
      // pesoPromedio is already in grams
      final pesoGramos = pesoPromedio;

      final tabla = await findApplicableTable(pesoGramos);
      if (tabla == null) {
        throw Exception(
          'No se encontró tabla de alimentación aplicable para peso: ${pesoGramos}g',
        );
      }

      // Calculate total biomass in kg for the calculation
      final totalBiomassKg = (pesoPromedio / 1000) * cantidadPeces;
      final dailyFood = tabla.calculateDailyFood(totalBiomassKg);
      final foodPerRation = tabla.calculateFoodPerRation(totalBiomassKg);

      return {
        'edad_semanas': tabla.edadSemanas,
        'referencia_alimento': tabla.referenciaAlimento,
        'raciones_diarias': tabla.racionesDiarias,
        'porcentaje_biomasa': tabla.porcentajeBiomasa,
        'biomasa_total_kg': totalBiomassKg,
        'alimento_diario_kg': dailyFood,
        'alimento_por_racion_kg': foodPerRation,
      };
    } catch (e) {
      debugPrint('Error calculating feeding schedule: $e');
      rethrow;
    }
  }
}
