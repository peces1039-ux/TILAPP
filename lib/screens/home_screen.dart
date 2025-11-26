import 'package:flutter/material.dart';
import '../services/profiles_service.dart';
import '../models/user_profile.dart';
import '../widgets/fish_loading.dart';
import 'dashboard_screen.dart';
import 'estanques_screen.dart';
import 'siembras_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profilesService = ProfilesService();

  int _currentIndex = 0;
  UserProfile? _currentProfile;
  bool _isLoading = true;

  // Mantener estado de cada pantalla
  final List<Widget> _screens = [
    const DashboardScreen(),
    const EstanquesPage(),
    const SiembrasScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profilesService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Inicio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.waves),
        label: 'Estanques',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.agriculture),
        label: 'Siembras',
      ),
    ];

    // Agregar tab Admin solo si el usuario es admin
    if (_currentProfile?.role == UserRole.admin) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    return items;
  }

  List<Widget> _buildScreens() {
    final screens = List<Widget>.from(_screens);

    // Agregar AdminScreen solo si es admin
    if (_currentProfile?.role == UserRole.admin) {
      screens.add(const AdminScreen());
    }

    return screens;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: FishLoading(
          message: 'Inicializando...',
        ),
      );
    }

    final screens = _buildScreens();
    final navItems = _buildBottomNavItems();

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: navItems,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFE3F2FD),
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
