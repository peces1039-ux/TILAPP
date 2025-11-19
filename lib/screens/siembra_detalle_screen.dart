// Siembra Detalle Screen
// Related: T047, T048, T049, T054, T066, FR-013, FR-014, FR-015, US4
// Shows detailed information about a siembra with edit/delete options and tabs for biometrias and muertes

import 'package:flutter/material.dart';
import '../services/siembras_service.dart';
import '../services/biometria_service.dart';
import '../services/tablas_alimentacion_service.dart';
import '../models/siembra.dart';
import '../models/biometria.dart';
import '../models/tabla_alimentacion.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/siembra_form_sheet.dart';
import '../widgets/informacion_general_tab.dart';
import '../widgets/programacion_alimentacion_tab.dart';
import '../widgets/biometrias_tab.dart';
import '../widgets/muertes_tab.dart';
import '../widgets/biometria_form_sheet.dart';
import '../widgets/muerte_form_sheet.dart';

class SiembraDetalleScreen extends StatefulWidget {
  final String siembraId;

  const SiembraDetalleScreen({super.key, required this.siembraId});

  @override
  State<SiembraDetalleScreen> createState() => _SiembraDetalleScreenState();
}

class _SiembraDetalleScreenState extends State<SiembraDetalleScreen>
    with SingleTickerProviderStateMixin {
  final _siembrasService = SiembrasService();
  final _biometriaService = BiometriaService();
  final _tablasAlimentacionService = TablasAlimentacionService();
  late TabController _tabController;

  Siembra? _siembra;
  Biometria? _ultimaBiometria;
  TablaAlimentacion? _tablaAlimentacion;
  bool _isLoading = true;
  bool _hasBiometrias = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.animation!.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.animation!.value == _tabController.index.toDouble()) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final siembra = await _siembrasService.getById(widget.siembraId);
      if (siembra == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      // Get latest biometria
      final biometrias = await _biometriaService.getBySiembra(widget.siembraId);
      final ultimaBiometria = biometrias.isNotEmpty ? biometrias.first : null;
      final hasBiometrias = biometrias.isNotEmpty;

      // Get applicable feeding table if there's a biometria
      TablaAlimentacion? tablaAlimentacion;
      if (ultimaBiometria != null) {
        tablaAlimentacion = await _tablasAlimentacionService
            .findApplicableTable(ultimaBiometria.pesoPromedio);
      }

      if (!mounted) return;

      setState(() {
        _siembra = siembra;
        _ultimaBiometria = ultimaBiometria;
        _tablaAlimentacion = tablaAlimentacion;
        _hasBiometrias = hasBiometrias;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLoading = false;
        _hasBiometrias = false; // Initialize to false on error
      });
    }
  }

  Future<void> _deleteSiembra() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar esta siembra de ${_siembra?.especie}?',
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

    try {
      await _siembrasService.delete(widget.siembraId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Siembra eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate deletion
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

  Future<void> _marcarComoCosechada() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cosecha'),
        content: Text(
          '¿Deseas marcar esta siembra de ${_siembra?.especie} como cosechada?\n\nEsto marcará la siembra como inactiva y liberará el estanque para una nueva siembra.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Marcar como cosechada'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _siembrasService.marcarComoCosechada(widget.siembraId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Siembra marcada como cosechada'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadData(); // Reload data to show updated status
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: _siembra != null
            ? 'Siembra de ${_siembra!.especie}'
            : 'Detalles de Siembra',
        bottom: _siembra != null
            ? TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                isScrollable: false,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(icon: Icon(Icons.info, size: 20), text: 'General'),
                  Tab(
                    icon: Icon(Icons.schedule, size: 20),
                    text: 'Programación',
                  ),
                  Tab(
                    icon: Icon(Icons.analytics, size: 20),
                    text: 'Biometrías',
                  ),
                  Tab(icon: Icon(Icons.warning, size: 20), text: 'Muertes'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _siembra == null
          ? const Center(child: Text('Siembra no encontrada'))
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Información General
                InformacionGeneralTab(
                  siembra: _siembra!,
                  ultimaBiometria: _ultimaBiometria,
                  tablaAlimentacion: _tablaAlimentacion,
                  hasBiometrias: _hasBiometrias,
                  onEdit: () async {
                    final result = await SiembraFormSheet.show(
                      context,
                      siembra: _siembra,
                      onSaved: _loadData,
                    );
                    if (result == true && mounted) {
                      await _loadData();
                    }
                  },
                  onDelete: _deleteSiembra,
                  onMarcarCosechada: _marcarComoCosechada,
                ),
                // Tab 2: Programación Diaria
                ProgramacionAlimentacionTab(
                  siembraId: widget.siembraId,
                  tablaAlimentacion: _tablaAlimentacion,
                  ultimaBiometria: _ultimaBiometria,
                ),
                // Tab 3: Biometrías
                BiometriasTab(
                  siembraId: widget.siembraId,
                  onBiometriaAdded: _loadData,
                ),
                // Tab 4: Historial de Muertes
                MuertesTab(
                  siembraId: widget.siembraId,
                  onMuerteAdded: _loadData,
                ),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_siembra == null) return null;

    debugPrint('Current tab index: ${_tabController.index}');

    // Tab 2: Biometrías
    if (_tabController.index == 2) {
      debugPrint('Showing biometria FAB');
      return FloatingActionButton(
        onPressed: () async {
          final result = await BiometriaFormSheet.show(
            context,
            siembraId: widget.siembraId,
            onSaved: _loadData,
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
      );
    }

    // Tab 3: Muertes
    if (_tabController.index == 3) {
      debugPrint('Showing muertes FAB');
      return FloatingActionButton(
        onPressed: () async {
          final result = await MuerteFormSheet.show(
            context,
            siembraId: widget.siembraId,
            onSaved: _loadData,
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
      );
    }

    debugPrint('No FAB for tab ${_tabController.index}');
    return null;
  }
}
