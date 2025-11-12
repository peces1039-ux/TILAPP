import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EstanquesScreen extends StatefulWidget {
  const EstanquesScreen({super.key});

  @override
  State<EstanquesScreen> createState() => _EstanquesScreenState();
}

class _EstanquesScreenState extends State<EstanquesScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _estanques = [];

  @override
  void initState() {
    super.initState();
    _loadEstanques();
  }

  Future<void> _loadEstanques() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _supabase
          .from('estanques')
          .select()
          .order('numero');
      
      setState(() {
        _estanques = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
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

  Future<void> _showEstanqueDialog([Map<String, dynamic>? estanque]) async {
    final isEditing = estanque != null;
    final numeroController = TextEditingController(
      text: isEditing ? estanque['numero']?.toString() : '',
    );
    final capacidadController = TextEditingController(
      text: isEditing ? estanque['capacidad']?.toString() : '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Estanque' : 'Nuevo Estanque'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número de Estanque',
                  hintText: 'Ej: E001',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacidadController,
                decoration: const InputDecoration(
                  labelText: 'Capacidad (m³)',
                  hintText: 'Ej: 1000',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (isEditing) {
                  await _supabase.from('estanques').update({
                    'numero': numeroController.text,
                    'capacidad': double.tryParse(capacidadController.text) ?? 0,
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', estanque['id']);
                } else {
                  await _supabase.from('estanques').insert({
                    'numero': numeroController.text,
                    'capacidad': double.tryParse(capacidadController.text) ?? 0,
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                }
                if (!mounted) return;
                Navigator.of(context).pop();
                _loadEstanques();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Estanque actualizado correctamente'
                          : 'Estanque creado correctamente',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEstanque(Map<String, dynamic> estanque) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro de eliminar el estanque ${estanque['numero']}?',
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
        debugPrint('Intentando eliminar estanque con ID: ${estanque['id']}');
        debugPrint('Datos del estanque: $estanque');
        
        await _supabase
            .from('estanques')
            .delete()
            .eq('id', estanque['id']);
            
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estanques'),
        backgroundColor: Colors.teal,
      ),
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
                          title: Text(
                            'Estanque ${estanque['numero']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            'Capacidad: ${estanque['capacidad']} m³',
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEstanqueDialog(estanque),
                                color: Colors.blue,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteEstanque(estanque),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEstanqueDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}