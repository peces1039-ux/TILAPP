import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/estanques_service.dart';
import '../models/estanque.dart';
import '../widgets/estanque_form_sheet.dart';
import '../widgets/custom_app_bar.dart';
import 'estanque_detalle_screen.dart';

class EstanquesPage extends StatefulWidget {
  const EstanquesPage({super.key});

  @override
  State<EstanquesPage> createState() => _EstanquesPageState();
}

class _EstanquesPageState extends State<EstanquesPage> {
  final _estanquesService = EstanquesService();
  bool _isLoading = true;
  List<Estanque> _estanques = [];

  @override
  void initState() {
    super.initState();
    _loadEstanques();
  }

  Future<void> _loadEstanques() async {
    try {
      setState(() => _isLoading = true);

      final estanques = await _estanquesService.getAll();

      if (!mounted) return;

      setState(() {
        _estanques = estanques;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estanques: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEstanque(Estanque estanque) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro de eliminar el estanque ${estanque.numero}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        debugPrint('Intentando eliminar estanque con ID: ${estanque.id}');
        debugPrint('Datos del estanque: ${estanque.toJson()}');

        await _estanquesService.delete(estanque.id.toString());

        if (!mounted) return;
        await _loadEstanques();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estanque eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar estanque: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Estanques'),
        backgroundColor: const Color(0xFFF5F7FA),
        body: RefreshIndicator(
          onRefresh: _loadEstanques,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _estanques.isEmpty
              ? const Center(
                  child: Text(
                    'No hay estanques registrados',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _estanques.length,
                  itemBuilder: (context, index) {
                    final estanque = _estanques[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const Icon(
                          Icons.water,
                          size: 40,
                          color: Colors.blue,
                        ),
                        title: Text(
                          'Estanque ${estanque.numero}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Capacidad: ${estanque.capacidad} m³',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Creado: ${DateFormat('dd/MM/yyyy').format(estanque.createdAt)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await EstanqueFormSheet.show(
                                  context,
                                  estanque: estanque,
                                  onSaved: _loadEstanques,
                                );
                                if (result == true && mounted) {
                                  await _loadEstanques();
                                }
                              },
                              color: Colors.blue,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteEstanque(estanque),
                              color: Colors.red,
                            ),
                          ],
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EstanqueDetalleScreen(
                                estanqueId: estanque.id.toString(),
                              ),
                            ),
                          );
                          // Reload if estanque was deleted
                          if (result == true && mounted) {
                            await _loadEstanques();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await EstanqueFormSheet.show(
              context,
              onSaved: _loadEstanques,
            );
            if (result == true && mounted) {
              await _loadEstanques();
            }
          },
          backgroundColor: const Color(0xFF1976D2),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
