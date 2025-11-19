import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'peces1039@gmail.com');
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    // Validaciones básicas
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, complete todos los campos';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Iniciando proceso de login...');
      final email = _emailController.text.trim().toLowerCase();
      debugPrint('Email a utilizar: $email');

      final response = await _authService.login(
        email,
        _passwordController.text,
      );

      if (!mounted) return;

      debugPrint('Verificando respuesta de autenticación...');

      if (response.session != null && response.user != null) {
        debugPrint('Login exitoso, navegando al dashboard');
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        setState(() {
          _errorMessage = 'Error: La sesión o el usuario son inválidos';
          _loading = false;
        });
      }
    } on AuthException catch (error) {
      debugPrint('Error de autenticación: ${error.message}');
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error inesperado: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error inesperado al intentar iniciar sesión';
          _loading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa tu correo electrónico';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim().toLowerCase(),
        redirectTo: 'http://localhost:3000',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se ha enviado un correo para restablecer tu contraseña',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al enviar el correo de recuperación';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'lib/screens/imagenes/TILAPP.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¡Bienvenido de nuevo!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Correo Electrónico',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu correo electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_loading,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contraseña',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        enabled: !_loading,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implementar recuperación de contraseña
                      },
                      child: const Text(
                        'Olvidé mi contraseña',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Register button (T030)
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.pushNamed(context, '/register');
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Registrarse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
