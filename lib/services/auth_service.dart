import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final supabase = Supabase.instance.client;
  static const String supabaseUrl = 'https://autoxfzkntochlfdcrvj.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1dG94ZnprbnRvY2hsZmRjcnZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExNDMzMzUsImV4cCI6MjA3NjcxOTMzNX0.4Ai_98tc2g1Q3BKcibEPhDKQojwTgWUzTXXfYBaAguw';

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
        debugPrint(
          'Sesión actual: ${currentSession?.accessToken ?? 'ninguna'}',
        );
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
      debugPrint(
        'Token de sesión: ${response.session?.accessToken.substring(0, 10)}...',
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('Error de autenticación: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        throw AuthException(
          'Credenciales incorrectas. Por favor, verifica tu correo y contraseña.',
        );
      }
      throw AuthException(e.message);
    } catch (e) {
      debugPrint('Error inesperado durante el login: $e');
      throw AuthException('Error inesperado al intentar iniciar sesión');
    }
  }

  /// Register new user with email, password, and nombre
  /// Creates user in auth.users and profile in profiles table with role 'user'
  /// Related: T020, FR-036, FR-037
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      debugPrint('Iniciando proceso de registro con Supabase...');

      final trimmedEmail = email.trim().toLowerCase();
      final trimmedNombre = nombre.trim();

      debugPrint('Email a utilizar: $trimmedEmail');
      debugPrint('Nombre: $trimmedNombre');

      // Validaciones
      if (!trimmedEmail.contains('@')) {
        throw AuthException('El correo electrónico no es válido');
      }

      if (password.length < 8) {
        throw AuthException('La contraseña debe tener al menos 8 caracteres');
      }

      // Validate password criteria (8+ chars, 1 number, 1 uppercase)
      if (!_validatePassword(password)) {
        throw AuthException(
          'La contraseña debe tener al menos 8 caracteres, 1 número y 1 mayúscula',
        );
      }

      if (trimmedNombre.isEmpty) {
        throw AuthException('El nombre no puede estar vacío');
      }

      debugPrint('Intentando registrar usuario...');

      // Create user in auth.users
      final response = await supabase.auth.signUp(
        email: trimmedEmail,
        password: password,
      );

      if (response.user == null) {
        debugPrint('Error: No se pudo crear el usuario');
        throw AuthException('No se pudo crear el usuario');
      }

      debugPrint('Usuario creado en auth.users: ${response.user!.id}');

      // Create profile with role 'user'
      try {
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'role': 'user',
          'nombre': trimmedNombre,
          'created_at': DateTime.now().toIso8601String(),
        });

        debugPrint('Perfil creado exitosamente con rol "user"');
      } catch (e) {
        debugPrint('Error creando perfil: $e');
        // Try to delete the auth user if profile creation failed
        try {
          await supabase.auth.signOut();
        } catch (_) {}
        throw AuthException('Error creando perfil de usuario');
      }

      debugPrint('¡Registro exitoso! Usuario: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      debugPrint('Error de autenticación: ${e.message}');
      if (e.message.contains('User already registered')) {
        throw AuthException('Este email ya está registrado');
      }
      throw AuthException(e.message);
    } catch (e) {
      debugPrint('Error inesperado durante el registro: $e');
      throw AuthException('Error inesperado al intentar registrar usuario');
    }
  }

  /// Validate password criteria: 8+ chars, 1 number, 1 uppercase
  /// Related: FR-038
  bool _validatePassword(String password) {
    if (password.length < 8) return false;

    // Check for at least one number
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    return true;
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
      await supabase.auth.setSession(session.accessToken);
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
        await supabase
            .from('perfil_usuario')
            .select()
            .eq('id', user.id)
            .single();
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
