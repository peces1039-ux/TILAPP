// Tablas Alimentacion Section Widget
// Related: T091, T093, T095, T096, T097, US8
// Displays and manages feeding tables in AdminScreen

import 'package:flutter/material.dart';
import '../models/tabla_alimentacion.dart';
import '../services/tablas_alimentacion_service.dart';
import '../widgets/tabla_alimentacion_form_sheet.dart';

class TablasAlimentacionSection extends StatefulWidget {
  const TablasAlimentacionSection({super.key});

  @override
  State<TablasAlimentacionSection> createState() =>
      _TablasAlimentacionSectionState();
}

class _TablasAlimentacionSectionState extends State<TablasAlimentacionSection> {
  final _tablasService = TablasAlimentacionService();
  List<TablaAlimentacion> _tablas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTablas();
  }

  Future<void> _loadTablas() async {
    setState(() => _isLoading = true);

    try {
      final tablas = await _tablasService.getAll();

      if (!mounted) return;

      setState(() {
        _tablas = tablas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar tablas: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  Future<void> _openFormSheet({TablaAlimentacion? tabla}) async {
    final result = await TablaAlimentacionFormSheet.show(
      context,
      tabla: tabla,
      onSaved: _loadTablas,
    );

    if (result == true) {
      _loadTablas();
    }
  }

  Future<void> _deleteTabla(TablaAlimentacion tabla) async {
    // T096: Check if tabla is in use (placeholder - would need to check siembras)
    // For now, we show a warning dialog

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tabla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar la tabla para "${tabla.edadLabel}"?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003D7A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF003D7A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: const Color(0xFF003D7A), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nota: Verifica que esta tabla no esté en uso por siembras activas.',
                      style: TextStyle(fontSize: 12, color: const Color(0xFF003D7A)),
                    ),
                  ),
                ],
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

    try {
      await _tablasService.delete(tabla.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tabla eliminada exitosamente'),
          backgroundColor: Color(0xFF00BCD4),
        ),
      );

      _loadTablas();
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();

      // T097: Show warning if tabla is in use
      if (errorMessage.contains('en uso') ||
          errorMessage.contains('foreign key') ||
          errorMessage.contains('constraint')) {
        _showErrorDialog(
          'Tabla en uso',
          'Esta tabla está en uso por siembras activas. No se puede eliminar hasta que se eliminen las siembras asociadas.',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $errorMessage'),
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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTablas,
              child: _tablas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay tablas de alimentación',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona + para crear una nueva tabla',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _tablas.length,
                      itemBuilder: (context, index) {
                        final tabla = _tablas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF008B8B),
                              child: Text(
                                '${tabla.edadSemanas}s',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              tabla.edadLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Peso: ${tabla.rangeFormatted}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Biomasa: ${tabla.porcentajeBiomasa.toStringAsFixed(1)}% | ${tabla.racionesDiarias} raciones/día',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Alimento: ${tabla.referenciaAlimento}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF5B7FFF),
                                  ),
                                  tooltip: 'Editar',
                                  onPressed: () => _openFormSheet(tabla: tabla),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Eliminar',
                                  onPressed: () => _deleteTabla(tabla),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFormSheet(),
        tooltip: 'Nueva tabla',
        backgroundColor: const Color(0xFF003D7A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
