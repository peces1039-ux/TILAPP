// Estanque Detalle Screen
// Related: T047, T048, T049, T053, FR-009, FR-010
// Shows detailed information about an estanque with edit/delete options

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/estanques_service.dart';
import '../services/siembras_service.dart';
import 'siembra_detalle_screen.dart';
import '../models/estanque.dart';
import '../models/siembra.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/estanque_form_sheet.dart';
import '../widgets/fish_loading.dart';

class EstanqueDetalleScreen extends StatefulWidget {
  final String estanqueId;

  const EstanqueDetalleScreen({super.key, required this.estanqueId});

  @override
  State<EstanqueDetalleScreen> createState() => _EstanqueDetalleScreenState();
}

class _EstanqueDetalleScreenState extends State<EstanqueDetalleScreen> {
  final _estanquesService = EstanquesService();
  final _siembrasService = SiembrasService();

  Estanque? _estanque;
  List<Siembra> _siembrasAsociadas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final estanque = await _estanquesService.getById(widget.estanqueId);
      final siembras = await _siembrasService.getByEstanque(widget.estanqueId);

      // Filtrar solo siembras activas y tomar la última (por fecha de siembra descendente)
      final siembrasActivas = siembras.where((s) => s.isActive).toList()
        ..sort((a, b) => b.fechaSiembra.compareTo(a.fechaSiembra));
      final ultimaSiembraActiva = siembrasActivas.isNotEmpty
          ? [siembrasActivas.first]
          : [];

      if (!mounted) return;

      setState(() {
        _estanque = estanque;
        _siembrasAsociadas = ultimaSiembraActiva.cast<Siembra>();
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

      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEstanque() async {
    // Obtener todas las siembras (activas e históricas) asociadas a este estanque
    final todasSiembras = await _siembrasService.getByEstanque(
      widget.estanqueId,
    );
    final tieneSiembras = todasSiembras.isNotEmpty;
    final tieneSiembrasActivas = todasSiembras.any((s) => s.isActive);

    if (tieneSiembrasActivas || tieneSiembras) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No se puede eliminar'),
          content: Text(
            tieneSiembrasActivas
                ? 'Este estanque tiene siembras activas. No se puede eliminar hasta que todas las siembras estén cosechadas y eliminadas.'
                : 'Este estanque ya ha tenido siembras asociadas. No se puede eliminar estanques con historial de siembras.',
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar el estanque ${_estanque?.numero}?',
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
      await _estanquesService.delete(widget.estanqueId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estanque eliminado exitosamente'),
          backgroundColor: const Color(0xFF00BCD4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: _estanque != null
            ? 'Estanque ${_estanque!.numero}'
            : 'Detalles del Estanque',
      ),
      body: _isLoading
          ? FishLoading(
              message: 'Cargando estanque...',
            )
          : _estanque == null
          ? const Center(child: Text('Estanque no encontrado'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.water,
                                  size: 48,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Estanque ${_estanque!.numero}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Capacidad: ${_estanque!.capacidad} m³',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            _buildInfoRow(
                              'Fecha de creación',
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(_estanque!.createdAt),
                            ),
                            _buildInfoRow(
                              'Última actualización',
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(_estanque!.updatedAt),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Siembras asociadas
                    Text(
                      'Siembras Asociadas (${_siembrasAsociadas.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_siembrasAsociadas.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No hay siembras en este estanque',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._siembrasAsociadas.map(
                        (siembra) => Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: const Icon(Icons.agriculture, color: Color(0xFF00BCD4)),
                            title: Text(siembra.especie),
                            subtitle: Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(siembra.fechaSiembra)}\n'
                              'Cantidad: ${siembra.cantidadActual} / ${siembra.cantidadInicial}',
                            ),
                            trailing: Icon(
                              siembra.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: siembra.isActive
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SiembraDetalleScreen(
                                    siembraId: siembra.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              if (_estanque == null) return;
                              final result = await EstanqueFormSheet.show(
                                context,
                                estanque: _estanque,
                                onSaved: _loadData,
                              );
                              if (result == true && mounted) {
                                await _loadData();
                              }
                            },
                            icon: const Icon(Icons.edit, color: Color(0xFF5B7FFF)),
                            label: const Text('Editar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF003D7A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _deleteEstanque,
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
