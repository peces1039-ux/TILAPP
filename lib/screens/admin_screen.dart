// Admin Screen
// Related: T083, T085, US6, FR-044, FR-045, FR-046
// Admin panel for user management with tabs for Users and Feeding Tables

import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/user_list_tile.dart';
import '../services/admin_service.dart';
import '../models/user_profile.dart';
import 'user_detail_screen.dart';
import '../widgets/tablas_alimentacion_section.dart';
import '../widgets/fish_loading.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _adminService = AdminService();
  List<UserProfile> _users = [];
  bool _isLoading = true;
  int _currentTabIndex = 0; // 0 = Users, 1 = Tablas de Alimentación

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await _adminService.getAllUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar usuarios: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(UserProfile user) async {
    // T087: Validations before delete
    if (user.isAdmin) {
      _showErrorDialog(
        'Operación no permitida',
        'No se pueden eliminar usuarios administradores.',
      );
      return;
    }

    if (user.isDeleted) {
      _showErrorDialog(
        'Usuario ya eliminado',
        'Este usuario ya ha sido eliminado previamente.',
      );
      return;
    }

    // T090: Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar al usuario ${user.nombre}?',
            ),
            const SizedBox(height: 16),
            const Text(
              'Nota: Verifica que el usuario no tenga estanques asociados antes de eliminar.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF003D7A),
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

    // T089: Soft delete via AdminService
    try {
      await _adminService.deleteUser(user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      _loadUsers();
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();

      // T088: Show appropriate error messages
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: CustomAppBar(
          title: 'Administración',
          bottom: TabBar(
            onTap: (index) => setState(() => _currentTabIndex = index),
            indicatorColor: const Color(0xFF1976D2),
            labelColor: const Color(0xFF1976D2),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.table_chart), text: 'Tablas Alimentación'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // Tab 1: Users Section (T085)
              _buildUsersSection(),

              // Tab 2: Tablas de Alimentación (Placeholder for US8)
              _buildTablasSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    return _isLoading
        ? FishLoading(
            message: 'Cargando usuarios...',
          )
        : RefreshIndicator(
            onRefresh: _loadUsers,
            child: _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay usuarios registrados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return UserListTile(
                        user: user,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UserDetailScreen(user: user),
                            ),
                          );

                          // Refresh if user was deleted
                          if (result == true) {
                            _loadUsers();
                          }
                        },
                        onDelete: user.isDeleted
                            ? null
                            : () => _deleteUser(user),
                      );
                    },
                  ),
          );
  }

  Widget _buildTablasSection() {
    // T091, T093: Tablas de Alimentación management with TablasAlimentacionSection
    return const TablasAlimentacionSection();
  }
}
