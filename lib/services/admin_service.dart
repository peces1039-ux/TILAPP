// Admin Service
// Related: T022, FR-054 to FR-056
// Manages admin operations for user management

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  /// Verify current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return false;

      return response['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Get all users (admin only)
  /// Related: T022, FR-054
  Future<List<UserProfile>> getAllUsers() async {
    try {
      debugPrint('Fetching all users (admin operation)');

      // Verify admin access
      if (!await isCurrentUserAdmin()) {
        throw Exception(
          'Acceso denegado: Solo administradores pueden ver todos los usuarios',
        );
      }

      // Use view that combines profiles with emails from auth.users
      final response = await _supabase
          .from('user_profiles_with_email')
          .select()
          .order('created_at', ascending: false);

      final profiles = (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();

      debugPrint('Fetched ${profiles.length} users');
      return profiles;
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      rethrow;
    }
  }

  /// Get user by ID (admin only)
  /// Related: T022, FR-055
  Future<UserProfile?> getUserById(String userId) async {
    try {
      debugPrint('Fetching user by ID: $userId (admin operation)');

      // Verify admin access
      if (!await isCurrentUserAdmin()) {
        throw Exception(
          'Acceso denegado: Solo administradores pueden ver detalles de usuarios',
        );
      }

      // Use view that combines profiles with emails from auth.users
      final response = await _supabase
          .from('user_profiles_with_email')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('User not found: $userId');
        return null;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user by ID: $e');
      rethrow;
    }
  }

  /// Delete user (soft-delete) - admin only
  /// Validation: user must have no estanques, cannot be admin
  /// Related: T022, FR-056
  Future<void> deleteUser(String userId) async {
    try {
      debugPrint('Deleting user: $userId (admin operation)');

      // Verify admin access
      if (!await isCurrentUserAdmin()) {
        throw Exception(
          'Acceso denegado: Solo administradores pueden eliminar usuarios',
        );
      }

      // Get current admin user ID
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Prevent self-deletion
      if (userId == currentUser.id) {
        throw Exception('No puedes eliminar tu propia cuenta');
      }

      // Check if target user is admin
      final targetProfile = await getUserById(userId);
      if (targetProfile?.isAdmin ?? false) {
        throw Exception('No se pueden eliminar cuentas de administrador');
      }

      // Check if user has estanques
      final hasEstanques = await _checkUserHasEstanques(userId);
      if (hasEstanques) {
        throw Exception(
          'No se puede eliminar usuario con estanques asociados. Debe eliminar los estanques primero.',
        );
      }

      // Soft-delete user
      await _supabase
          .from('profiles')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      debugPrint('User soft-deleted successfully');
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  /// Check if user has any estanques
  Future<bool> _checkUserHasEstanques(String userId) async {
    try {
      final response = await _supabase
          .from('estanques')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user estanques: $e');
      return false;
    }
  }
}
