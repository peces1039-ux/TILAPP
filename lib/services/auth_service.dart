import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final supabase = Supabase.instance.client;
  static const String supabaseUrl = 'https://autoxfzkntochlfdcrvj.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1dG94ZnprbnRvY2hsZmRjcnZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExNDMzMzUsImV4cCI6MjA3NjcxOTMzNX0.4Ai_98tc2g1Q3BKcibEPhDKQojwTgWUzTXXfYBaAguw';

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<AuthResponse> login(String email, String password) async {
    try {
      debugPrint('Iniciando proceso de login con Supabase...');
      
      final trimmedEmail = email.trim().toLowerCase();
      debugPrint('Email a utilizar: $trimmedEmail');

      // Validaciones básicas
      if (!trimmedEmail.contains('@')) {
        throw AuthException('El correo electrónico no es válido');
      }
      
      if (password.isEmpty) {
        throw AuthException('La contraseña no puede estar vacía');
      }
      
      // Verificar conexión a Supabase
      try {
        final currentSession = supabase.auth.currentSession;
        debugPrint('Sesión actual: ${currentSession?.accessToken ?? 'ninguna'}');
      } catch (e) {
        debugPrint('Error verificando sesión: $e');
      }

      debugPrint('Intentando autenticar...');

      // Limpiar cualquier sesión existente
      await supabase.auth.signOut();
      
      // Intento de inicio de sesión
      debugPrint('Intentando login con email: $trimmedEmail');
      debugPrint('Longitud de la contraseña: ${password.length}');
      
      final response = await supabase.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );
      
      debugPrint('Respuesta recibida de Supabase');
      
      // Verificación de la respuesta
      if (response.session == null) {
        debugPrint('Error: No se pudo obtener la sesión');
        throw AuthException('No se pudo establecer la sesión');
      }
      
      debugPrint('¡Login exitoso! Usuario: ${response.user?.email}');
      debugPrint('Token de sesión: ${response.session?.accessToken.substring(0, 10)}...');
      return response;
      
    } on AuthException catch (e) {
      debugPrint('Error de autenticación: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        throw AuthException('Credenciales incorrectas. Por favor, verifica tu correo y contraseña.');
      }
      throw AuthException(e.message);
    } catch (e) {
      debugPrint('Error inesperado durante el login: $e');
      throw AuthException('Error inesperado al intentar iniciar sesión');
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  bool isAuthenticated() {
    return supabase.auth.currentSession != null;
  }

  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return supabase.auth.onAuthStateChange;
  }

  Future<void> persistSession(Session session) async {
    try {
      if (session.accessToken != null && session.refreshToken != null) {
        await supabase.auth.setSession(session.accessToken!);
      }
    } catch (e) {
      print('Error persisting session: $e');
    }
  }

  Future<void> checkAndRefreshSession() async {
    try {
      final currentSession = supabase.auth.currentSession;
      if (currentSession != null && currentSession.isExpired) {
        await supabase.auth.refreshSession();
      }
    } catch (e) {
      // Si hay un error al refrescar, cerrar sesión
      await logout();
    }
  }

  /// Función de validación manual para verificar el estado completo de la autenticación
  Future<bool> validateAuthState() async {
    try {
      // Verificar si hay una sesión
      if (!isAuthenticated()) return false;

      // Verificar si la sesión está expirada
      final session = supabase.auth.currentSession;
      if (session?.isExpired ?? true) {
        try {
          await supabase.auth.refreshSession();
        } catch (e) {
          return false;
        }
      }

      // Verificar si podemos acceder al perfil del usuario
      final user = getCurrentUser();
      if (user == null) return false;

      try {
        final response = await supabase
          .from('perfil_usuario')
          .select()
          .eq('id', user.id)
          .single();
        return response != null;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}