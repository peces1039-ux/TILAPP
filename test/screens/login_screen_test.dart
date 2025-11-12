import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishes_app/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('should show error when fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Encontrar el botón de login
      final loginButton = find.byType(ElevatedButton);
      
      // Tap en el botón sin llenar campos
      await tester.tap(loginButton);
      await tester.pump();

      // Verificar que se muestre el mensaje de error
      expect(find.text('Por favor, complete todos los campos'), findsOneWidget);
    });

    testWidgets('should show loading indicator when logging in',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Encontrar los campos de texto
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      // Ingresar credenciales
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password');

      // Tap en el botón de login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verificar que se muestre el indicador de carga
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}