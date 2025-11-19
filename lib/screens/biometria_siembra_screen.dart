import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';

class BiometriaSiembraScreen extends StatefulWidget {
  final int idSiembra;
  final String especieSiembra;
  final DateTime fechaSiembra;

  const BiometriaSiembraScreen({
    super.key,
    required this.idSiembra,
    required this.especieSiembra,
    required this.fechaSiembra,
  });

  @override
  State<BiometriaSiembraScreen> createState() => _BiometriaSiembraScreenState();
}

class _BiometriaSiembraScreenState extends State<BiometriaSiembraScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _registrosBiometria = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometria();
  }

  Future<void> _loadBiometria() async {
    try {
      setState(() => _loading = true);
      
      final response = await _supabase
          .from('biometria')
          .select()
          .eq('id_siembra', widget.idSiembra)
          .order('fecha', ascending: false);

      setState(() {
        _registrosBiometria = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar biometría: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _agregarBiometria() async {
    TextEditingController pesoController = TextEditingController();
    TextEditingController largoController = TextEditingController();
    DateTime fechaBiometria = DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Registro de Biometría'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pesoController,
                      decoration: const InputDecoration(
                        labelText: 'Peso (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: largoController,
                      decoration: const InputDecoration(
                        labelText: 'Largo (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Fecha'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(fechaBiometria)),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaBiometria,
                          firstDate: widget.fechaSiembra,
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setState(() => fechaBiometria = fecha);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    pesoController.dispose();
                    largoController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final peso = double.tryParse(pesoController.text);
                      final largo = double.tryParse(largoController.text);

                      if (peso == null || peso <= 0 || largo == null || largo <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingrese valores válidos'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      await _supabase.from('biometria').insert({
                        'id_siembra': widget.idSiembra,
                        'peso': peso,
                        'largo': largo,
                        'fecha': fechaBiometria.toIso8601String(),
                      });

                      if (!mounted) return;
                      pesoController.dispose();
                      largoController.dispose();
                      Navigator.pop(context);
                      await _loadBiometria();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registro agregado exitosamente'),
                        ),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(
        title: 'Biometría',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _registrosBiometria.isEmpty
              ? const Center(
                  child: Text('No hay registros de biometría'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _registrosBiometria.length,
                  itemBuilder: (context, index) {
                    final registro = _registrosBiometria[index];
                    final fecha = DateTime.parse(registro['fecha']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          'Peso: ${registro['peso']} g | Largo: ${registro['largo']} cm',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(fecha),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarBiometria,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
      ),
    );
  }
}
