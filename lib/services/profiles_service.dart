// Profiles Service
// Related: T021, FR-039 to FR-042, FR-053
// Manages user profile operations with multi-tenancy support

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class ProfilesService {
  final _supabase = Supabase.instance.client;

  /// Get current user's profile
  /// Related: FR-039
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user');
        return null;
      }

      debugPrint('Fetching profile for user: ${user.id}');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('No profile found for user: ${user.id}');
        return null;
      }

      // Add email from auth.user to profile data
      final profileData = Map<String, dynamic>.from(response);
      profileData['email'] = user.email ?? '';

      return UserProfile.fromJson(profileData);
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
      rethrow;
    }
  }

  /// Update profile nombre
  /// Related: T021, FR-040
  Future<void> updateProfile(String nombre) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final trimmedNombre = nombre.trim();
      if (trimmedNombre.isEmpty) {
        throw Exception('El nombre no puede estar vacío');
      }

      debugPrint('Updating profile nombre for user: ${user.id}');

      await _supabase
          .from('profiles')
          .update({'nombre': trimmedNombre})
          .eq('id', user.id);

      debugPrint('Profile updated successfully');
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Change user password
  /// Related: T021, FR-041
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validate new password criteria (8+ chars, 1 number, 1 uppercase)
      if (!_validatePassword(newPassword)) {
        throw Exception(
          'La contraseña debe tener al menos 8 caracteres, 1 número y 1 mayúscula',
        );
      }

      debugPrint('Changing password for user: ${user.id}');

      // Supabase will handle password change via auth API
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      debugPrint('Password changed successfully');
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  /// Validate password criteria: 8+ chars, 1 number, 1 uppercase
  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    return true;
  }

  /// Soft-delete current user account (set deleted_at)
  /// Prevents deletion if user is admin
  /// Related: T021, FR-042, FR-053
  Future<void> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Soft-deleting account for user: ${user.id}');

      // Check if user is admin (admins cannot delete their own accounts)
      final profile = await getCurrentUserProfile();
      if (profile?.isAdmin ?? false) {
        throw Exception(
          'Los administradores no pueden eliminar sus propias cuentas',
        );
      }

      // Set deleted_at timestamp (soft-delete)
      await _supabase
          .from('profiles')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      debugPrint('Account soft-deleted successfully (30-day retention)');

      // Sign out user after soft-delete
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  /// Check if user has any estanques (used before account deletion)
  /// Related: FR-053
  Future<bool> hasEstanques() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('estanques')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking estanques: $e');
      return false;
    }
  }
}
