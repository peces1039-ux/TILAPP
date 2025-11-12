import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishes_app/services/auth_service.dart';

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService();
  });

  group('AuthService Tests', () {
    test('isAuthenticated should return false when no session exists', () {
      expect(authService.isAuthenticated(), false);
    });

    test('getCurrentUser should return null when not authenticated', () {
      expect(authService.getCurrentUser(), null);
    });

    test('login should throw error with invalid credentials', () async {
      expect(
        () => authService.login('invalid@email.com', 'wrongpassword'),
        throwsA(isA<String>()),
      );
    });

    test('authStateChanges should emit new states', () async {
      expect(
        authService.authStateChanges(),
        emits(isA<AuthState>()),
      );
    });
  });
}