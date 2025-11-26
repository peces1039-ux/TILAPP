import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/fish_loading.dart';

class MuertesSiembraScreen extends StatefulWidget {
  final String idSiembra;
  final String especieSiembra;
  final DateTime fechaSiembra;

  const MuertesSiembraScreen({
    super.key,
    required this.idSiembra,
    required this.especieSiembra,
    required this.fechaSiembra,
  });

  @override
  State<MuertesSiembraScreen> createState() => _MuertesSiembraScreenState();
}

class _MuertesSiembraScreenState extends State<MuertesSiembraScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _muertes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMuertes();
  }

  Future<void> _loadMuertes() async {
    try {
      setState(() => _loading = true);
      final response = await _supabase
          .from('muertes_siembra')
          .select('id, cantidad, fecha_muerte, causa')
          .eq('id_siembra', widget.idSiembra)
          .order('fecha_muerte', ascending: false);
      
      setState(() {
        _muertes = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar muertes: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _agregarMuerte() async {
    TextEditingController cantidadController = TextEditingController();
    TextEditingController causaController = TextEditingController();
    DateTime fechaMuerte = DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Registrar Nueva Muerte'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cantidadController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad de Peces',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Fecha'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(fechaMuerte)),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaMuerte,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) {
                          setState(() => fechaMuerte = fecha);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: causaController,
                      decoration: const InputDecoration(
                        labelText: 'Causa',
                        hintText: 'Ej: Enfermedad, depredador, etc.',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
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
                  onPressed: () async {
                    final cantidad = int.tryParse(cantidadController.text);
                    if (cantidad == null || cantidad <= 0) {
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
                        'id_siembra': widget.idSiembra,
                        'cantidad': cantidad,
                        'fecha_muerte': fechaMuerte.toIso8601String(),
                        'causa': causaController.text.isNotEmpty
                            ? causaController.text
                            : null,
                      });

                      if (!mounted) return;
                      Navigator.pop(context);
                      await _loadMuertes();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Muerte registrada correctamente'),
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
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDetalles(Map<String, dynamic> muerte) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final fecha = muerte['fecha_muerte'] != null
            ? DateTime.parse(muerte['fecha_muerte'])
            : null;

        return AlertDialog(
          title: const Text('Detalle de Muerte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cantidad:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${muerte['cantidad']} peces',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Fecha:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'Sin fecha',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Causa:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (muerte['causa'] as String?) ?? 'Sin causa registrada',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _mostrarDialogoEditar(muerte);
              },
              icon: const Icon(Icons.edit, color: Color(0xFF5B7FFF)),
              label: const Text('Editar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B7FFF).withOpacity(0.1),
                foregroundColor: const Color(0xFF003D7A),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoEditar(Map<String, dynamic> muerte) async {
    DateTime fechaMuerte = muerte['fecha_muerte'] != null
        ? DateTime.parse(muerte['fecha_muerte'])
        : DateTime.now();
    TextEditingController cantidadController =
        TextEditingController(text: muerte['cantidad'].toString());
    TextEditingController causaController =
        TextEditingController(text: (muerte['causa'] as String?) ?? '');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Muerte'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cantidadController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad de Peces',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Fecha'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(fechaMuerte)),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaMuerte,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) {
                          setState(() => fechaMuerte = fecha);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Causa:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: causaController,
                      decoration: const InputDecoration(
                        hintText: 'Ej: Enfermedad, depredador, etc.',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cantidadController.dispose();
                    causaController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final cantidad = int.tryParse(cantidadController.text);
                      if (cantidad == null || cantidad <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingrese un número válido'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      await _supabase
                          .from('muertes_siembra')
                          .update({
                            'cantidad': cantidad,
                            'fecha_muerte': fechaMuerte.toIso8601String(),
                            'causa': causaController.text.isNotEmpty
                                ? causaController.text
                                : null,
                          })
                          .eq('id', muerte['id']);

                      if (!mounted) return;
                      cantidadController.dispose();
                      causaController.dispose();
                      Navigator.pop(context);
                      await _loadMuertes();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Actualizado correctamente'),
                        ),
                      );
                    } catch (error) {
                      cantidadController.dispose();
                      causaController.dispose();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $error'),
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

  Future<void> _eliminarMuerte(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Muerte'),
          content: const Text('¿Está seguro?'),
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
        );
      },
    );

    if (confirm == true) {
      try {
        await _supabase.from('muertes_siembra').delete().eq('id', id);
        await _loadMuertes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Muerte eliminada')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Gestión de Muertes - ${widget.especieSiembra}',
      ),
      body: _loading
          ? const FishLoading(
              message: 'Cargando muertes...',
            )
          : _muertes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: const Color(0xFFB2DFDB),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sin registros de muertes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _muertes.length,
                  itemBuilder: (context, index) {
                    final muerte = _muertes[index];
                    final fecha = muerte['fecha_muerte'] != null
                        ? DateTime.parse(muerte['fecha_muerte'])
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          '${muerte['cantidad']} peces',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: fecha != null
                            ? Text(
                                DateFormat('dd/MM/yyyy').format(fecha),
                                style: const TextStyle(fontSize: 14),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info),
                              onPressed: () => _mostrarDetalles(muerte),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarMuerte(muerte['id']),
                            ),
                          ],
                        ),
                        onTap: () => _mostrarDetalles(muerte),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarMuerte,
        backgroundColor: const Color(0xFF003D7A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
