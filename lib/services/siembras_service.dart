// Siembras Service
// Related: T024, FR-011 to FR-015
// Manages fish seeding operations with multi-tenancy support

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/siembra.dart';

class SiembrasService {
  final _supabase = Supabase.instance.client;

  /// Get all siembras for current user
  /// Filtered by user_id (multi-tenancy)
  /// Related: T024, FR-011
  Future<List<Siembra>> getAll() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching siembras for user: ${user.id}');

      final response = await _supabase
          .from('siembras')
          .select()
          .eq('user_id', user.id)
          .order('fecha_siembra', ascending: false);

      final siembras = (response as List)
          .map((json) => Siembra.fromJson(json))
          .toList();

      debugPrint('Fetched ${siembras.length} siembras');
      return siembras;
    } catch (e) {
      debugPrint('Error fetching siembras: $e');
      rethrow;
    }
  }

  /// Get siembras by estanque ID
  /// Related: FR-012
  Future<List<Siembra>> getByEstanque(String estanqueId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching siembras for estanque: $estanqueId');

      final response = await _supabase
          .from('siembras')
          .select()
          .eq('id_estanque', estanqueId)
          .eq('user_id', user.id)
          .order('fecha_siembra', ascending: false);

      final siembras = (response as List)
          .map((json) => Siembra.fromJson(json))
          .toList();

      debugPrint('Fetched ${siembras.length} siembras for estanque');
      return siembras;
    } catch (e) {
      debugPrint('Error fetching siembras by estanque: $e');
      rethrow;
    }
  }

  /// Get active siembras (cantidad_actual > 0)
  /// Related: FR-013
  Future<List<Siembra>> getActive() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching active siembras for user: ${user.id}');

      final response = await _supabase
          .from('siembras')
          .select()
          .eq('user_id', user.id)
          .gt('cantidad_inicial', 0) // Assuming this represents active siembras
          .order('fecha_siembra', ascending: false);

      final siembras = (response as List)
          .map((json) => Siembra.fromJson(json))
          .where((s) => s.isActive)
          .toList();

      debugPrint('Fetched ${siembras.length} active siembras');
      return siembras;
    } catch (e) {
      debugPrint('Error fetching active siembras: $e');
      rethrow;
    }
  }

  /// Get siembra by ID
  /// Related: FR-012
  Future<Siembra?> getById(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching siembra: $id');

      final response = await _supabase
          .from('siembras')
          .select('*, estanques!inner(numero)')
          .eq('id', id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('Siembra not found: $id');
        return null;
      }

      // Extract estanque numero from nested object
      if (response['estanques'] != null) {
        response['nombre_estanque'] = response['estanques']['numero'];
      }

      return Siembra.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching siembra by ID: $e');
      rethrow;
    }
  }

  /// Create a new siembra
  /// Automatically adds current user_id
  /// Related: T024, FR-013
  Future<Siembra> create(Siembra siembra) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validations
      if (siembra.especie.trim().isEmpty) {
        throw Exception('La especie no puede estar vacía');
      }

      if (siembra.cantidadInicial <= 0) {
        throw Exception('La cantidad inicial debe ser mayor a 0');
      }

      debugPrint('Creating siembra: ${siembra.especie}');

      final data = siembra.toJson();
      data['user_id'] = user.id; // Auto-add user_id for multi-tenancy
      data.remove('id'); // Remove id to let Supabase generate it
      data.remove(
        'created_at',
      ); // Remove created_at to let Supabase generate it
      data.remove(
        'updated_at',
      ); // Remove updated_at to let Supabase generate it

      final response = await _supabase
          .from('siembras')
          .insert(data)
          .select()
          .single();

      debugPrint('Siembra created successfully: ${response['id']}');
      return Siembra.fromJson(response);
    } catch (e) {
      debugPrint('Error creating siembra: $e');
      rethrow;
    }
  }

  /// Update an existing siembra
  /// Related: T024, FR-014
  Future<void> update(Siembra siembra) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validations
      if (siembra.especie.trim().isEmpty) {
        throw Exception('La especie no puede estar vacía');
      }

      if (siembra.cantidadInicial <= 0) {
        throw Exception('La cantidad inicial debe ser mayor a 0');
      }

      debugPrint('Updating siembra: ${siembra.id}');

      final data = siembra.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('siembras')
          .update(data)
          .eq('id', siembra.id)
          .eq('user_id', user.id); // Ensure user owns this record

      debugPrint('Siembra updated successfully');
    } catch (e) {
      debugPrint('Error updating siembra: $e');
      rethrow;
    }
  }

  /// Delete a siembra
  /// Related: T024, FR-015
  Future<void> delete(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Deleting siembra: $id');

      // Note: Cascade delete will handle associated biometria and muertes
      await _supabase
          .from('siembras')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id); // Ensure user owns this record

      debugPrint('Siembra deleted successfully');
    } catch (e) {
      debugPrint('Error deleting siembra: $e');
      rethrow;
    }
  }

  /// Get count of active siembras for current user
  Future<int> getActiveCount() async {
    try {
      final siembras = await getActive();
      return siembras.length;
    } catch (e) {
      debugPrint('Error getting active siembras count: $e');
      return 0;
    }
  }

  /// Update cantidad_actual and muertes_totales
  /// Used when registering muertes
  Future<void> updateCantidades({
    required String siembraId,
    required int cantidadActual,
    required int muertesTotales,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase
          .from('siembras')
          .update({
            'cantidad_actual': cantidadActual,
            'muertes_totales': muertesTotales,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', siembraId)
          .eq('user_id', user.id);

      debugPrint(
        'Updated siembra cantidades: actual=$cantidadActual, muertes=$muertesTotales',
      );
    } catch (e) {
      debugPrint('Error updating siembra cantidades: $e');
      rethrow;
    }
  }

  /// Check if siembra has biometrias
  /// Used to prevent editing/deleting siembras with biometria records
  Future<bool> hasBiometrias(String siembraId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('biometrias')
          .select('id')
          .eq('siembra_id', siembraId)
          .eq('user_id', user.id)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking biometrias: $e');
      return false;
    }
  }

  /// Mark siembra as harvested (cosechada)
  /// This makes the siembra inactive and frees the estanque for new siembras
  Future<void> marcarComoCosechada(String siembraId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Marking siembra as cosechada: $siembraId');

      await _supabase
          .from('siembras')
          .update({
            'cosechada': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', siembraId)
          .eq('user_id', user.id);

      debugPrint('Siembra marked as cosechada successfully');
    } catch (e) {
      debugPrint('Error marking siembra as cosechada: $e');
      rethrow;
    }
  }
}
