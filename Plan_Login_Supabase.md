# 🧩 Plan de Implementación del Módulo de Login (Supabase)

## 🎯 Objetivo
Implementar un sistema de autenticación de usuarios utilizando **Supabase Auth** para permitir el acceso seguro a la aplicación de alimentación de peces.  
El login será la primera pantalla del flujo principal de la app.

---

## 🧠 Fase 1: Análisis y Diseño Lógico

### 1.1 Requerimientos Funcionales
- El usuario debe poder iniciar sesión con **correo electrónico y contraseña**.  
- Si el inicio de sesión es correcto, el usuario será redirigido al **Dashboard**.  
- Si las credenciales son incorrectas, se mostrará un mensaje de error.  
- El sistema debe mantener la sesión activa mientras el usuario no cierre sesión.  

### 1.2 Modelo de Datos (Tabla: `auth.users`)
Supabase ya gestiona la tabla de usuarios internamente, pero se puede crear una tabla complementaria:

**Tabla:** `perfil_usuario`  
| Campo | Tipo | Descripción |
|--------|------|-------------|
| id | UUID (PK, FK de auth.users) | Identificador único del usuario |
| nombre | VARCHAR(100) | Nombre del usuario |
| rol | VARCHAR(20) | Rol del usuario (admin, técnico, invitado) |
| fecha_creacion | TIMESTAMP | Fecha de registro |

---

## ⚙️ Fase 2: Configuración del Backend en Supabase



### 2.2 Configuración de la Base de Datos
- Tabla `perfil_usuario` ya está configurada con la estructura necesaria.
- No se requieren triggers ya que no habrá registro de nuevos usuarios.

---

## 💻 Fase 3: Implementación del Login en Flutter

### 3.1 Instalación de dependencias
En el archivo `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.0.0
  flutter_secure_storage: ^9.0.0
```

### 3.2 Inicialización de Supabase
En `main.dart`:
```dart
await Supabase.initialize(
  url: 'https://tu-proyecto.supabase.co',
  anonKey: 'tu_anon_key',
);
```

### 3.3 Lógica de Autenticación
En `auth_service.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<bool> login(String email, String password) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.session != null;
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}
```

---

## 🧩 Fase 4: Interfaz del Login (Estructura básica)
En `login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() => _loading = true);
    final success = await _authService.login(_email.text, _password.text);
    setState(() => _loading = false);
    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      setState(() => _error = 'Credenciales inválidas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Iniciar Sesión', style: TextStyle(fontSize: 24)),
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Correo')),
            TextField(controller: _password, decoration: InputDecoration(labelText: 'Contraseña'), obscureText: true),
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading ? CircularProgressIndicator() : Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔐 Fase 5: Seguridad
- Usar `flutter_secure_storage` para guardar tokens de sesión.  
- Implementar cierre de sesión seguro.  
- Validar autenticación antes de entrar a cualquier otra pantalla (middleware o guard).  

---

## 🚀 Fase 6: Pruebas
- Prueba de login exitoso con usuario válido.  
- Prueba de error con credenciales incorrectas.  
- Verificar persistencia de sesión.  
- Validar cierre de sesión y redirección al login.

---

## 🧾 Resultados Esperados
✅ Login funcional con Supabase.  
✅ Sesión persistente y segura.  
✅ Redirección correcta al Dashboard.  
✅ Control de errores visual y claro para el usuario.
