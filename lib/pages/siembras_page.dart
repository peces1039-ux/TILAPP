import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../screens/siembra_detalle_screen.dart';

class SiembrasPage extends StatefulWidget {
  const SiembrasPage({super.key});

  @override
  State<SiembrasPage> createState() => _SiembrasPageState();
}

class _SiembrasPageState extends State<SiembrasPage> {
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
                      decoration: const InputDecoration(
                        labelText: 'Cantidad Inicial',
                      ),
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _siembras.length,
                itemBuilder: (context, index) {
                  final siembra = _siembras[index];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: const Text(
                        'Siembra',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      subtitle: Text(
                        '${siembra['especie']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SiembraDetalleScreen(
                              siembraId: siembra['id'] as String,
                            ),
                          ),
                        );
                        if (resultado == true) {
                          await _loadData();
                        }
                      },
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: const Color(0xFF003D7A),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
