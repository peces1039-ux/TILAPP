import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/muerte.dart';
import '../services/muertes_service.dart';

class MuertesTab extends StatefulWidget {
  final String siembraId;
  final VoidCallback onMuerteAdded;

  const MuertesTab({
    super.key,
    required this.siembraId,
    required this.onMuerteAdded,
  });

  @override
  State<MuertesTab> createState() => _MuertesTabState();
}

class _MuertesTabState extends State<MuertesTab> {
  final MuertesService _muertesService = MuertesService();
  List<Muerte> _muertes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMuertes();
  }

  Future<void> _loadMuertes() async {
    setState(() => _isLoading = true);
    try {
      final muertes = await _muertesService.getMuertesBySiembra(
        widget.siembraId,
      );
      // Ordenar por fecha descendente
      muertes.sort((a, b) => b.fecha.compareTo(a.fecha));
      setState(() {
        _muertes = muertes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar muertes: $e')));
      }
    }
  }

  Future<void> _deleteMuerte(Muerte muerte) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Eliminar el registro de ${muerte.cantidad} muertes del ${DateFormat('dd/MM/yyyy').format(muerte.fecha)}?',
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
        await _muertesService.delete(muerte.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registro eliminado')));
        await _loadMuertes();
        widget.onMuerteAdded(); // Refresh parent to update counters
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

    if (_muertes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay muertes registradas',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón inferior para registrar',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMuertes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _muertes.length,
        itemBuilder: (context, index) {
          final muerte = _muertes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red[100],
                child: Icon(Icons.warning, color: Colors.red[700]),
              ),
              title: Text(
                DateFormat('dd/MM/yyyy').format(muerte.fecha),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Cantidad: ${muerte.cantidad}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (muerte.observaciones != null &&
                      muerte.observaciones!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Causa: ${muerte.observaciones!}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteMuerte(muerte),
              ),
            ),
          );
        },
      ),
    );
  }
}
