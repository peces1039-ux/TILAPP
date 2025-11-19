// Estanques Service
// Related: T023, FR-008 to FR-010, FR-017, FR-043
// Manages fish pond operations with multi-tenancy support

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/estanque.dart';

class EstanquesService {
  final _supabase = Supabase.instance.client;

  /// Get all estanques for current user
  /// Filtered by user_id (multi-tenancy)
  /// Related: T023, FR-008
  Future<List<Estanque>> getAll() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching estanques for user: ${user.id}');

      final response = await _supabase
          .from('estanques')
          .select()
          .eq('user_id', user.id)
          .order('numero', ascending: true);

      final estanques = (response as List)
          .map((json) => Estanque.fromJson(json))
          .toList();

      debugPrint('Fetched ${estanques.length} estanques');
      return estanques;
    } catch (e) {
      debugPrint('Error fetching estanques: $e');
      rethrow;
    }
  }

  /// Get estanque by ID
  /// Related: FR-009
  Future<Estanque?> getById(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Fetching estanque: $id');

      final response = await _supabase
          .from('estanques')
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('Estanque not found: $id');
        return null;
      }

      return Estanque.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching estanque by ID: $e');
      rethrow;
    }
  }

  /// Create a new estanque
  /// Automatically adds current user_id
  /// Validates numero uniqueness within user scope (FR-017)
  /// Related: T023, FR-009, FR-017
  Future<Estanque> create(Estanque estanque) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validations
      if (estanque.capacidad <= 0) {
        throw Exception('La capacidad debe ser mayor a 0');
      }

      // Check numero uniqueness within user_id scope (FR-017)
      final existing = await _checkNumeroExists(estanque.numero);
      if (existing) {
        throw Exception(
          'Ya existe un estanque con el número ${estanque.numero}',
        );
      }

      debugPrint('Creating estanque: ${estanque.numero}');

      final data = estanque.toJson();
      data['user_id'] = user.id; // Auto-add user_id for multi-tenancy

      final response = await _supabase
          .from('estanques')
          .insert(data)
          .select()
          .single();

      debugPrint('Estanque created successfully: ${response['id']}');
      return Estanque.fromJson(response);
    } catch (e) {
      debugPrint('Error creating estanque: $e');
      rethrow;
    }
  }

  /// Update an existing estanque
  /// Validates numero uniqueness if changed (FR-017)
  /// Related: T023, FR-010, FR-017
  Future<void> update(Estanque estanque) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validations
      if (estanque.capacidad <= 0) {
        throw Exception('La capacidad debe ser mayor a 0');
      }

      // Check numero uniqueness if changed (FR-017)
      if (estanque.id != null) {
        final existing = await getById(estanque.id.toString());
        if (existing != null && existing.numero != estanque.numero) {
          final numeroExists = await _checkNumeroExists(estanque.numero);
          if (numeroExists) {
            throw Exception(
              'Ya existe un estanque con el número ${estanque.numero}',
            );
          }
        }
      }

      debugPrint('Updating estanque: ${estanque.id}');

      if (estanque.id == null) {
        throw Exception('No se puede actualizar un estanque sin ID');
      }

      final data = estanque.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('estanques')
          .update(data)
          .eq('id', estanque.id!)
          .eq('user_id', user.id); // Ensure user owns this record

      debugPrint('Estanque updated successfully');
    } catch (e) {
      debugPrint('Error updating estanque: $e');
      rethrow;
    }
  }

  /// Delete an estanque
  /// Prevents deletion if has associated siembras (FR-043)
  /// Related: T023, FR-010, FR-043
  Future<void> delete(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Deleting estanque: $id');

      // Check for associated siembras (FR-043)
      final hasSiembras = await _checkHasSiembras(id);
      if (hasSiembras) {
        throw Exception(
          'No se puede eliminar un estanque con siembras asociadas',
        );
      }

      await _supabase
          .from('estanques')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id); // Ensure user owns this record

      debugPrint('Estanque deleted successfully');
    } catch (e) {
      debugPrint('Error deleting estanque: $e');
      rethrow;
    }
  }

  /// Check if numero already exists for current user (FR-017)
  Future<bool> _checkNumeroExists(String numero) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('estanques')
          .select('id')
          .eq('numero', numero)
          .eq('user_id', user.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking numero existence: $e');
      return false;
    }
  }

  /// Check if estanque has associated siembras (FR-043)
  Future<bool> _checkHasSiembras(String estanqueId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('siembras')
          .select('id')
          .eq('id_estanque', estanqueId)
          .eq('user_id', user.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking siembras: $e');
      return false;
    }
  }

  /// Get count of estanques for current user
  Future<int> getCount() async {
    try {
      final estanques = await getAll();
      return estanques.length;
    } catch (e) {
      debugPrint('Error getting estanques count: $e');
      return 0;
    }
  }
}
