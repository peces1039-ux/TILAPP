// User Detail Screen
// Related: T086, US6
// Shows complete user information with management options

import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/admin_service.dart';
import '../widgets/custom_app_bar.dart';

class UserDetailScreen extends StatefulWidget {
  final UserProfile user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _adminService = AdminService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Note: We need to check if user has estanques
      // This requires admin to be able to query user's data
      // For now, we'll show a message that this requires manual verification

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser() async {
    // Validations
    if (widget.user.isAdmin) {
      _showErrorDialog(
        'Operación no permitida',
        'No se pueden eliminar usuarios administradores.',
      );
      return;
    }

    if (widget.user.isDeleted) {
      _showErrorDialog(
        'Usuario ya eliminado',
        'Este usuario ya ha sido eliminado previamente.',
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar al usuario "${widget.user.nombre}"?',
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta acción realizará una eliminación lógica (soft delete) y el usuario no podrá acceder a la aplicación.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nota: Verifica manualmente que el usuario no tenga estanques asociados antes de eliminar.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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

    if (confirmed != true) return;

    // Perform soft delete
    try {
      setState(() => _isLoading = true);

      await _adminService.deleteUser(widget.user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate refresh needed
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      String errorMessage = e.toString();

      // Parse common errors
      if (errorMessage.contains('tiene datos asociados') ||
          errorMessage.contains('estanques')) {
        _showErrorDialog(
          'Usuario tiene datos asociados',
          'El usuario tiene estanques asociados. Debe eliminar todos los estanques primero antes de eliminar el usuario.',
        );
      } else if (errorMessage.contains('admin')) {
        _showErrorDialog(
          'Operación no permitida',
          'No se pueden eliminar usuarios administradores.',
        );
      } else {
        _showErrorDialog('Error', 'Error al eliminar usuario: $errorMessage');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'Detalle de Usuario'),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Avatar and Name
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: widget.user.isAdmin
                                ? Colors.orange
                                : Colors.blue,
                            child: Text(
                              widget.user.nombre.isNotEmpty
                                  ? widget.user.nombre[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.user.nombre,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(
                              widget.user.isAdmin ? 'Administrador' : 'Usuario',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: widget.user.isAdmin
                                ? Colors.orange
                                : Colors.blue,
                          ),
                          if (widget.user.isDeleted)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Chip(
                                label: Text(
                                  'ELIMINADO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // User Information
                    const Text(
                      'Información del Usuario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.badge,
                      label: 'ID',
                      value: widget.user.id,
                    ),
                    _buildInfoCard(
                      icon: Icons.email,
                      label: 'Email',
                      value: widget.user.email,
                    ),
                    _buildInfoCard(
                      icon: Icons.person,
                      label: 'Nombre',
                      value: widget.user.nombre,
                    ),
                    _buildInfoCard(
                      icon: Icons.admin_panel_settings,
                      label: 'Rol',
                      value: widget.user.isAdmin ? 'Administrador' : 'Usuario',
                    ),
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      label: 'Fecha de Creación',
                      value: _formatDate(widget.user.createdAt),
                    ),
                    if (widget.user.isDeleted)
                      _buildInfoCard(
                        icon: Icons.block,
                        label: 'Fecha de Eliminación',
                        value: _formatDate(widget.user.deletedAt!),
                        valueColor: Colors.red,
                      ),

                    const SizedBox(height: 32),

                    // Delete Button
                    if (!widget.user.isDeleted && !widget.user.isAdmin)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _deleteUser,
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar Usuario'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                    if (widget.user.isAdmin)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Los usuarios administradores no pueden ser eliminados por razones de seguridad.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
