import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SiembrasScreen extends StatefulWidget {
  const SiembrasScreen({super.key});

  @override
  State<SiembrasScreen> createState() => _SiembrasScreenState();
}

class _SiembrasScreenState extends State<SiembrasScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _siembras = [];
  List<Map<String, dynamic>> _estanques = [];
  bool _loading = true;

  // Controladores para el formulario
  final _especieController = TextEditingController();
  final _cantidadController = TextEditingController();
  DateTime _fechaSiembra = DateTime.now();
  String? _selectedEstanqueId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _especieController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      
      // Cargar estanques
      final estanquesResponse = await _supabase
          .from('estanques')
          .select()
          .order('numero');
      
      // Cargar siembras con información de estanques y muertes
      final siembrasResponse = await _supabase
          .from('siembras')
          .select('''
            *,
            estanques (
              numero
            ),
            muertes_siembra (
              cantidad
            )
          ''')
          .order('fecha_siembra', ascending: false);

      setState(() {
        _estanques = List<Map<String, dynamic>>.from(estanquesResponse);
        _siembras = List<Map<String, dynamic>>.from(siembrasResponse);
        _loading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los datos: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _addSiembra() async {
    if (_selectedEstanqueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un estanque'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final cantidad = int.tryParse(_cantidadController.text);
      if (cantidad == null || cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cantidad debe ser un número positivo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _supabase.from('siembras').insert({
        'especie': _especieController.text,
        'cantidad_inicial': cantidad,
        'fecha_siembra': _fechaSiembra.toIso8601String(),
        'id_estanque': _selectedEstanqueId,
      });

      // Limpiar el formulario
      _especieController.clear();
      _cantidadController.clear();
      _selectedEstanqueId = null;
      _fechaSiembra = DateTime.now();

      // Recargar datos
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siembra agregada exitosamente')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar la siembra: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registrarMuertes(String idSiembra, int cantidadInicial) async {
    TextEditingController muertesController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registrar Muertes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: muertesController,
                decoration: const InputDecoration(labelText: 'Cantidad de Muertes'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'Registre la cantidad de peces muertos en este evento.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final muertes = int.tryParse(muertesController.text);
                if (muertes == null || muertes <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrese un número válido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _supabase.from('muertes_siembra').insert({
                    'id_siembra': idSiembra,
                    'cantidad': muertes,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Muertes registradas correctamente'),
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al registrar muertes: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarSiembra(Map<String, dynamic> siembra) async {
    _especieController.text = siembra['especie'];
    _cantidadController.text = siembra['cantidad_inicial'].toString();
    _fechaSiembra = DateTime.parse(siembra['fecha_siembra']);
    _selectedEstanqueId = siembra['id_estanque'].toString();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Siembra'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedEstanqueId,
                      decoration: const InputDecoration(labelText: 'Estanque'),
                      items: _estanques.map((estanque) {
                        return DropdownMenuItem(
                          value: estanque['id'].toString(),
                          child: Text('Estanque ${estanque['numero']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedEstanqueId = value);
                      },
                    ),
                    TextField(
                      controller: _especieController,
                      decoration: const InputDecoration(labelText: 'Especie'),
                    ),
                    TextField(
                      controller: _cantidadController,
                      decoration: const InputDecoration(labelText: 'Cantidad Inicial'),
                      keyboardType: TextInputType.number,
                    ),
                    ListTile(
                      title: const Text('Fecha de Siembra'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(_fechaSiembra),
                      ),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fechaSiembra,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setState(() => _fechaSiembra = fecha);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _especieController.clear();
                    _cantidadController.clear();
                    _selectedEstanqueId = null;
                    _fechaSiembra = DateTime.now();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final cantidad = int.tryParse(_cantidadController.text);
                      if (cantidad == null || cantidad <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('La cantidad debe ser un número positivo'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      await _supabase
                          .from('siembras')
                          .update({
                            'especie': _especieController.text,
                            'cantidad_inicial': cantidad,
                            'fecha_siembra': _fechaSiembra.toIso8601String(),
                            'id_estanque': _selectedEstanqueId,
                          })
                          .eq('id', siembra['id']);

                      if (!mounted) return;
                      Navigator.pop(context);
                      _especieController.clear();
                      _cantidadController.clear();
                      _selectedEstanqueId = null;
                      _fechaSiembra = DateTime.now();
                      await _loadData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Siembra actualizada exitosamente'),
                        ),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar la siembra: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSiembra(String id) async {
    try {
      await _supabase.from('siembras').delete().match({'id': id});
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siembra eliminada exitosamente')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la siembra: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Nueva Siembra'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedEstanqueId,
                      decoration: const InputDecoration(labelText: 'Estanque'),
                      items: _estanques.map((estanque) {
                        return DropdownMenuItem(
                          value: estanque['id'].toString(),
                          child: Text('Estanque ${estanque['numero']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedEstanqueId = value);
                      },
                    ),
                    TextField(
                      controller: _especieController,
                      decoration: const InputDecoration(labelText: 'Especie'),
                    ),
                    TextField(
                      controller: _cantidadController,
                      decoration: const InputDecoration(labelText: 'Cantidad Inicial'),
                      keyboardType: TextInputType.number,
                    ),
                    ListTile(
                      title: const Text('Fecha de Siembra'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(_fechaSiembra),
                      ),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fechaSiembra,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setState(() => _fechaSiembra = fecha);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addSiembra();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Siembras'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _siembras.length,
              itemBuilder: (context, index) {
                final siembra = _siembras[index];
                final totalMuertes = (siembra['muertes_siembra'] as List?)
                    ?.fold<int>(0, (sum, muerte) => sum + (muerte['cantidad'] as int)) ?? 0;
                final cantidadActual = siembra['cantidad_inicial'] - totalMuertes;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('${siembra['especie']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estanque: ${siembra['estanques']['numero']}\n'
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(siembra['fecha_siembra']))}\n'
                              'Cantidad Inicial: ${siembra['cantidad_inicial']}\n'
                              'Total Muertes: $totalMuertes\n'
                              'Cantidad Actual: $cantidadActual',
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editarSiembra(siembra),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteSiembra(siembra['id']),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _registrarMuertes(
                            siembra['id'],
                            siembra['cantidad_inicial'],
                          ),
                          icon: const Icon(Icons.warning_amber),
                          label: const Text('Registrar Muertes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[100],
                            foregroundColor: Colors.red[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
