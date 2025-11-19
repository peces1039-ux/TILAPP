// Muertes Service
// Related: T026, FR-020 to FR-022
// Manages fish death records with multi-tenancy support

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/muerte.dart';
import 'biometria_service.dart';

class MuertesService {
  final _supabase = Supabase.instance.client;
  final _biometriaService = BiometriaService();

  /// Get all muertes for a specific siembra
  /// Filtered by current user (multi-tenancy)
  /// Related: FR-020
  Future<List<Muerte>> getMuertesBySiembra(String siembraId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching muertes for siembra: $siembraId');

      final response = await _supabase
          .from('muertes')
          .select()
          .eq('siembra_id', siembraId)
          .eq('user_id', user.id)
          .order('fecha', ascending: false);

      final muertes = (response as List)
          .map((json) => Muerte.fromJson(json))
          .toList();

      debugPrint('Fetched ${muertes.length} muertes');
      return muertes;
    } catch (e) {
      debugPrint('Error fetching muertes: $e');
      rethrow;
    }
  }

  /// Get all muertes for current user
  /// Related: FR-021
  Future<List<Muerte>> getAllMuertes() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching all muertes for user: ${user.id}');

      final response = await _supabase
          .from('muertes')
          .select()
          .eq('user_id', user.id)
          .order('fecha', ascending: false);

      final muertes = (response as List)
          .map((json) => Muerte.fromJson(json))
          .toList();

      debugPrint('Fetched ${muertes.length} muertes');
      return muertes;
    } catch (e) {
      debugPrint('Error fetching all muertes: $e');
      rethrow;
    }
  }

  /// Create a new muerte record
  /// Automatically adds current user_id
  /// Related: T026, FR-022
  Future<Muerte> create(Muerte muerte) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      if (muerte.cantidad <= 0) {
        throw Exception('La cantidad de muertes debe ser mayor a 0');
      }

      debugPrint('Creating muerte for siembra: ${muerte.siembraId}');

      final data = muerte.toJson();
      data['user_id'] = user.id; // Auto-add user_id for multi-tenancy
      data.remove('id'); // Remove id to let Supabase generate it
      data.remove(
        'created_at',
      ); // Remove created_at to let Supabase generate it

      final response = await _supabase
          .from('muertes')
          .insert(data)
          .select()
          .single();

      debugPrint('Muerte created successfully: ${response['id']}');

      // Update siembra muertes_totales and cantidad_actual
      await _updateSiembraMuertes(muerte.siembraId, muerte.cantidad);

      // Recalculate biometria fields based on new cantidad_actual
      await _recalculateLastBiometria(muerte.siembraId);

      return Muerte.fromJson(response);
    } catch (e) {
      debugPrint('Error creating muerte: $e');
      rethrow;
    }
  }

  /// Update an existing muerte record
  /// Related: T026
  Future<void> update(Muerte muerte) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      if (muerte.cantidad <= 0) {
        throw Exception('La cantidad de muertes debe ser mayor a 0');
      }

      debugPrint('Updating muerte: ${muerte.id}');

      // Get old cantidad to adjust siembra totals
      final oldMuerte = await _getMuerteById(muerte.id);
      final cantidadDiff = muerte.cantidad - (oldMuerte?.cantidad ?? 0);

      final data = muerte.toJson();

      await _supabase
          .from('muertes')
          .update(data)
          .eq('id', muerte.id)
          .eq('user_id', user.id); // Ensure user owns this record

      debugPrint('Muerte updated successfully');

      // Update siembra totals if cantidad changed
      if (cantidadDiff != 0) {
        await _updateSiembraMuertes(muerte.siembraId, cantidadDiff);

        // Recalculate biometria fields based on new cantidad_actual
        await _recalculateLastBiometria(muerte.siembraId);
      }
    } catch (e) {
      debugPrint('Error updating muerte: $e');
      rethrow;
    }
  }

  /// Delete a muerte record
  /// Related: T026
  Future<void> delete(String muerteId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Deleting muerte: $muerteId');

      // Get muerte to adjust siembra totals
      final muerte = await _getMuerteById(muerteId);
      if (muerte == null) {
        throw Exception('Muerte no encontrada');
      }

      await _supabase
          .from('muertes')
          .delete()
          .eq('id', muerteId)
          .eq('user_id', user.id); // Ensure user owns this record

      debugPrint('Muerte deleted successfully');

      // Subtract from siembra totals
      await _updateSiembraMuertes(muerte.siembraId, -muerte.cantidad);

      // Recalculate biometria fields based on new cantidad_actual
      await _recalculateLastBiometria(muerte.siembraId);
    } catch (e) {
      debugPrint('Error deleting muerte: $e');
      rethrow;
    }
  }

  /// Get muerte by ID (internal helper)
  Future<Muerte?> _getMuerteById(String muerteId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('muertes')
          .select()
          .eq('id', muerteId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return Muerte.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching muerte by ID: $e');
      return null;
    }
  }

  /// Update siembra muertes_totales and cantidad_actual
  Future<void> _updateSiembraMuertes(
    String siembraId,
    int cantidadChange,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get current siembra
      final siembra = await _supabase
          .from('siembras')
          .select('cantidad_muertes, cantidad_inicial')
          .eq('id', siembraId)
          .eq('user_id', user.id)
          .single();

      final currentMuertes = siembra['cantidad_muertes'] ?? 0;
      final cantidadInicial = siembra['cantidad_inicial'] ?? 0;

      final newMuertes = currentMuertes + cantidadChange;
      final newCantidadActual = cantidadInicial - newMuertes;

      await _supabase
          .from('siembras')
          .update({
            'cantidad_muertes': newMuertes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', siembraId)
          .eq('user_id', user.id);

      debugPrint(
        'Updated siembra muertes: $newMuertes, actual: $newCantidadActual',
      );
    } catch (e) {
      debugPrint('Error updating siembra muertes: $e');
    }
  }

  /// Get total muertes for a siembra
  Future<int> getTotalMuertesBySiembra(String siembraId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final muertes = await getMuertesBySiembra(siembraId);
      return muertes.fold<int>(0, (sum, muerte) => sum + muerte.cantidad);
    } catch (e) {
      debugPrint('Error getting total muertes: $e');
      return 0;
    }
  }

  /// Recalculate the last biometria fields after muerte changes
  /// This updates biomasa_total and cantidad_alimento_diario based on new cantidad_actual
  Future<void> _recalculateLastBiometria(String siembraId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get the latest biometria for this siembra
      final biometrias = await _biometriaService.getBySiembra(siembraId);
      if (biometrias.isEmpty) {
        debugPrint('No biometria found for siembra, skipping recalculation');
        return;
      }

      final lastBiometria = biometrias.first;

      // Get current siembra to get cantidad_actual (already updated by _updateSiembraMuertes)
      final siembraData = await _supabase
          .from('siembras')
          .select('cantidad_inicial, cantidad_muertes')
          .eq('id', siembraId)
          .eq('user_id', user.id)
          .single();

      final cantidadInicial = siembraData['cantidad_inicial'] as int;
      final cantidadMuertes = siembraData['cantidad_muertes'] as int? ?? 0;
      final cantidadActual = cantidadInicial - cantidadMuertes;

      // Recalculate biomasa_total: peso_promedio * cantidad_actual
      final pesoPromedio = lastBiometria.pesoPromedio;
      final biomasaTotal = pesoPromedio * cantidadActual;

      // Get feeding table to calculate cantidad_alimento_diario
      final tablaData = await _supabase
          .from('tabla_alimentacion')
          .select()
          .lte('peso_min_gramos', pesoPromedio)
          .gte('peso_max_gramos', pesoPromedio)
          .maybeSingle();

      double? cantidadAlimentoDiario;
      if (tablaData != null) {
        final porcentajeBiomasa = (tablaData['porcentaje_biomasa'] as num)
            .toDouble();
        // Formula: biomasa_total * (porcentaje_biomasa)
        cantidadAlimentoDiario = biomasaTotal * porcentajeBiomasa;
      }

      // Update the biometria with recalculated values
      final updateData = {'biomasa_total': biomasaTotal};

      if (cantidadAlimentoDiario != null) {
        updateData['cantidad_alimento_diario'] = cantidadAlimentoDiario;
      }

      await _supabase
          .from('biometrias')
          .update(updateData)
          .eq('id', lastBiometria.id)
          .eq('user_id', user.id);

      debugPrint(
        'Recalculated biometria: biomasa_total=$biomasaTotal, cantidad_alimento_diario=$cantidadAlimentoDiario',
      );
    } catch (e) {
      debugPrint('Error recalculating last biometria: $e');
      // Don't rethrow - this is a secondary operation
    }
  }
}
