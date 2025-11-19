import 'package:flutter/material.dart';
import '../services/estanques_service.dart';
import '../services/siembras_service.dart';
import '../services/profiles_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/summary_card.dart';
import '../models/user_profile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _estanquesService = EstanquesService();
  final _siembrasService = SiembrasService();
  final _profilesService = ProfilesService();

  int _totalEstanques = 0;
  int _siembrasActivas = 0;
  UserProfile? _currentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load data in parallel
      final results = await Future.wait([
        _estanquesService.getCount(),
        _siembrasService.getActiveCount(),
        _profilesService.getCurrentUserProfile(),
      ]);

      if (!mounted) return;

      setState(() {
        _totalEstanques = results[0] as int;
        _siembrasActivas = results[1] as int;
        _currentProfile = results[2] as UserProfile?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Dashboard'),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome section
                      Text(
                        'Bienvenido, ${_currentProfile?.nombre ?? "Usuario"}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aquí tienes un resumen de tu operación',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Summary cards
                      Text(
                        'Resumen',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                          SummaryCard(
                            title: 'Total de Estanques',
                            value: _totalEstanques.toString(),
                            icon: Icons.water,
                            color: Colors.blue,
                          ),
                          SummaryCard(
                            title: 'Siembras Activas',
                            value: _siembrasActivas.toString(),
                            icon: Icons.agriculture,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Information card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Acceso Rápido',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Usa la barra de navegación inferior para acceder a Estanques y Siembras.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
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
