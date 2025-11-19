import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/biometria.dart';
import '../services/biometria_service.dart';
import 'biometria_form_sheet.dart';

class BiometriasTab extends StatefulWidget {
  final String siembraId;
  final VoidCallback onBiometriaAdded;

  const BiometriasTab({
    super.key,
    required this.siembraId,
    required this.onBiometriaAdded,
  });

  @override
  State<BiometriasTab> createState() => _BiometriasTabState();
}

class _BiometriasTabState extends State<BiometriasTab> {
  final BiometriaService _biometriaService = BiometriaService();
  List<Biometria> _biometrias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometrias();
  }

  Future<void> _loadBiometrias() async {
    setState(() => _isLoading = true);
    try {
      final biometrias = await _biometriaService.getBySiembra(widget.siembraId);
      // Ordenar por fecha descendente
      biometrias.sort((a, b) => b.fecha.compareTo(a.fecha));
      setState(() {
        _biometrias = biometrias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar biometrías: $e')),
        );
      }
    }
  }

  Future<void> _deleteBiometria(Biometria biometria) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Eliminar la biometría del ${DateFormat('dd/MM/yyyy').format(biometria.fecha)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _biometriaService.delete(biometria.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Biometría eliminada')));
        await _loadBiometrias();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_biometrias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay biometrías registradas',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona + para agregar la primera',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBiometrias,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _biometrias.length,
        itemBuilder: (context, index) {
          final biometria = _biometrias[index];
          final isMostRecent = index == 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.analytics, color: Colors.blue[700]),
              ),
              title: Text(
                DateFormat('dd/MM/yyyy').format(biometria.fecha),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Peso promedio: ${biometria.pesoPromedio.toStringAsFixed(1)} g',
                  ),
                  Text(
                    'Tamaño promedio: ${biometria.tamanoPromedio.toStringAsFixed(2)} cm',
                  ),
                  if (!isMostRecent)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Solo la biometría más reciente puede editarse o eliminarse',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
              trailing: isMostRecent
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteBiometria(biometria),
                    )
                  : null,
              onTap: isMostRecent
                  ? () async {
                      final result = await BiometriaFormSheet.show(
                        context,
                        siembraId: widget.siembraId,
                        biometria: biometria,
                        onSaved: () async {
                          await _loadBiometrias();
                          widget.onBiometriaAdded();
                        },
                      );
                      if (result == true && mounted) {
                        await _loadBiometrias();
                      }
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }
}
