// Profile Screen
// Related: T029, FR-040, FR-041, FR-042, FR-043
// User profile management with editable nombre, change password, and delete account

import 'package:flutter/material.dart';
import '../services/profiles_service.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profilesService = ProfilesService();
  final _authService = AuthService();
  final _nombreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  UserProfile? _currentProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profilesService.getCurrentUserProfile();

      if (!mounted) return;

      setState(() {
        _currentProfile = profile;
        _nombreController.text = profile?.nombre ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar perfil: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _profilesService.updateProfile(_nombreController.text.trim());

      if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: const Color(0xFF00BCD4),
          ),
        );      setState(() => _isEditing = false);
      _loadProfile();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Contraseña Actual',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureCurrent = !obscureCurrent;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),
                    helperText: 'Min 8 chars, 1 mayúscula, 1 número',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    if (value.length < 8) {
                      return 'Mínimo 8 caracteres';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Debe tener 1 mayúscula';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Debe tener 1 número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await _profilesService.changePassword(
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña cambiada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showDeleteAccountDialog() async {
    // Check if user has estanques (FR-043)
    final hasEstanques = await _profilesService.hasEstanques();

    if (!mounted) return;

    if (hasEstanques) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No se puede eliminar'),
          content: const Text(
            'No puedes eliminar tu cuenta mientras tengas estanques registrados. '
            'Por favor, elimina todos tus estanques primero.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar tu cuenta? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _profilesService.deleteAccount();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF5B7FFF)),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nombreController.text = _currentProfile?.nombre ?? '';
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentProfile == null
            ? const Center(child: Text('Error al cargar perfil'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile icon
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            _currentProfile!.nombre.isNotEmpty
                                ? _currentProfile!.nombre[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Role badge
                      Center(
                        child: Chip(
                          label: Text(
                            _currentProfile!.isAdmin
                                ? 'Administrador'
                                : 'Usuario',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _currentProfile!.isAdmin
                              ? const Color(0xFF003D7A)
                              : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email (read-only)
                      TextFormField(
                        initialValue: _currentProfile!.email,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre (editable)
                      TextFormField(
                        controller: _nombreController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          if (value.trim().length < 2) {
                            return 'Mínimo 2 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save button (only when editing)
                      if (_isEditing)
                        ElevatedButton.icon(
                          onPressed: _updateProfile,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar Cambios'),
                        ),
                      if (_isEditing) const SizedBox(height: 16),

                      // Change password button
                      OutlinedButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock, color: Color(0xFF003D7A)),
                        label: const Text(
                          'Cambiar Contraseña',
                          style: TextStyle(color: Color(0xFF003D7A)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF003D7A)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logout button
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _authService.logout();
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: const Icon(Icons.logout, color: Color(0xFF003D7A)),
                        label: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Color(0xFF003D7A)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF003D7A)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Divider(),
                      const SizedBox(height: 16),

                      // Delete account button
                      TextButton.icon(
                        onPressed: _showDeleteAccountDialog,
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Eliminar Cuenta',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
