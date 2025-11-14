import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SiembraDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> siembra;

  const SiembraDetalleScreen({
    super.key,
    required this.siembra,
  });

  @override
  State<SiembraDetalleScreen> createState() => _SiembraDetalleScreenState();
}

class _SiembraDetalleScreenState extends State<SiembraDetalleScreen> {
  final _supabase = Supabase.instance.client;
  late Map<String, dynamic> _siembra;
  bool _loading = false;

  // Controladores para la edición
  late TextEditingController _especieController;
  late TextEditingController _cantidadController;
  late DateTime _fechaSiembra;
  late String _selectedEstanqueId;
  List<Map<String, dynamic>> _estanques = [];

  @override
  void initState() {
    super.initState();
    _siembra = widget.siembra;
    _especieController = TextEditingController(text: _siembra['especie']);
    _cantidadController = TextEditingController(
      text: _siembra['cantidad_inicial'].toString(),
    );
    _fechaSiembra = DateTime.parse(_siembra['fecha_siembra']);
    _selectedEstanqueId = _siembra['id_estanque'].toString();
    _loadEstanques();
  }

  @override
  void dispose() {
    _especieController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _loadEstanques() async {
    try {
      final response = await _supabase.from('estanques').select();
      setState(() {
        _estanques = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar estanques: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _actualizarSiembra() async {
    setState(() => _loading = true);

    try {
      final cantidad = int.tryParse(_cantidadController.text);
      if (cantidad == null || cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cantidad debe ser un número positivo'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      await _supabase.from('siembras').update({
        'especie': _especieController.text,
        'cantidad_inicial': cantidad,
        'fecha_siembra': _fechaSiembra.toIso8601String(),
        'id_estanque': _selectedEstanqueId,
      }).eq('id', _siembra['id']);

      setState(() {
        _siembra['especie'] = _especieController.text;
        _siembra['cantidad_inicial'] = cantidad;
        _siembra['fecha_siembra'] = _fechaSiembra.toIso8601String();
        _siembra['id_estanque'] = int.parse(_selectedEstanqueId);
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siembra actualizada exitosamente')),
      );
    } catch (error) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarSiembra() async {
    final confirmada = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Está seguro de que desea eliminar esta siembra?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmada != true) return;

    setState(() => _loading = true);

    try {
      await _supabase.from('siembras').delete().eq('id', _siembra['id']);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siembra eliminada exitosamente')),
      );
    } catch (error) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _registrarMuertes() async {
    TextEditingController muertesController = TextEditingController();
    TextEditingController causaController = TextEditingController();
    DateTime fechaMuertes = DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Registrar Muertes'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: muertesController,
                      decoration: const InputDecoration(labelText: 'Cantidad de Muertes'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Fecha de Muertes'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(fechaMuertes)),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaMuertes,
                          firstDate: DateTime.parse(_siembra['fecha_siembra']),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setState(() => fechaMuertes = fecha);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: causaController,
                      decoration: const InputDecoration(
                        labelText: 'Causa de la Muerte',
                        hintText: 'Ej: Enfermedad, depredador, oxígeno bajo, etc.',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Registre la cantidad de peces muertos y la causa.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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
                        'id_siembra': _siembra['id'],
                        'cantidad': muertes,
                        'fecha_muerte': fechaMuertes.toIso8601String(),
                        'causa': causaController.text.isNotEmpty ? causaController.text : null,
                      });
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Muertes registradas correctamente'),
                        ),
                      );
                      // Recargar datos
                      Navigator.pop(context, true);
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
      },
    );
  }

  Future<void> _editarFechaMuerte(Map<String, dynamic> muerte) async {
    DateTime fechaMuertes = muerte['fecha_muerte'] != null
        ? DateTime.parse(muerte['fecha_muerte'])
        : DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController causaController =
            TextEditingController(text: (muerte['causa'] as String?) ?? '');

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Muerte'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cantidad: ${muerte['cantidad']} peces',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Fecha de Muertes'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(fechaMuertes)),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaMuertes,
                          firstDate: DateTime.parse(_siembra['fecha_siembra']),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setState(() => fechaMuertes = fecha);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: causaController,
                      decoration: const InputDecoration(
                        labelText: 'Causa de la Muerte',
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
                    causaController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final muertesId = muerte['id'];
                      if (muertesId == null) {
                        throw Exception('ID de muerte no encontrado');
                      }

                      // Primero actualizar solo la fecha
                      await _supabase
                          .from('muertes_siembra')
                          .update({
                            'fecha_muerte': fechaMuertes.toIso8601String(),
                          })
                          .eq('id', muertesId);

                      // Luego actualizar la causa si hay texto
                      if (causaController.text.isNotEmpty) {
                        await _supabase
                            .from('muertes_siembra')
                            .update({
                              'causa': causaController.text,
                            })
                            .eq('id', muertesId);
                      }

                      if (!mounted) return;
                      causaController.dispose();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Muerte actualizada correctamente'),
                        ),
                      );
                      // Recargar datos
                      Navigator.pop(context, true);
                    } catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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

  Future<void> _eliminarMuerte(dynamic id) async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se puede identificar el registro'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Muerte'),
          content: const Text('¿Está seguro de que desea eliminar este registro de muerte?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _supabase.from('muertes_siembra').delete().eq('id', id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Muerte eliminada correctamente')),
        );
        Navigator.pop(context, true);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMuertes = (_siembra['muertes_siembra'] as List?)
            ?.fold<int>(0, (sum, muerte) => sum + (muerte['cantidad'] as int)) ??
        0;
    final cantidadActual =
        (_siembra['cantidad_inicial'] as int) - totalMuertes;

  return SafeArea(child: Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Siembra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _loading ? null : _eliminarSiembra,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información actual
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información Actual',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cantidad Inicial',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${_siembra['cantidad_inicial']}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Muertes',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '$totalMuertes',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cantidad Actual',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '$cantidadActual',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Historial de Muertes
                    const Text(
                      'Historial de Muertes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if ((_siembra['muertes_siembra'] as List?)?.isEmpty ?? true)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'Sin registros de muertes',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (_siembra['muertes_siembra'] as List?)?.length ?? 0,
                        itemBuilder: (context, index) {
                          final muerte = (_siembra['muertes_siembra'] as List?)?[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Cantidad: ${muerte['cantidad']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Evento ${index + 1}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red[900],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _editarFechaMuerte(muerte),
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (muerte['fecha_muerte'] != null)
                                    Text(
                                      'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(muerte['fecha_muerte']))}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  if (muerte['causa'] != null &&
                                      (muerte['causa'] as String).isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Causa:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            muerte['causa'],
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _editarFechaMuerte(muerte),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Editar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[100],
                                          foregroundColor: Colors.blue[900],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _eliminarMuerte(muerte['id']),
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Eliminar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[100],
                                          foregroundColor: Colors.red[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    // Formulario de edición
                    const Text(
                      'Editar Información',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedEstanqueId,
                      decoration: const InputDecoration(
                        labelText: 'Estanque',
                        border: OutlineInputBorder(),
                      ),
                      items: _estanques.map((estanque) {
                        return DropdownMenuItem(
                          value: estanque['id'].toString(),
                          child: Text('Estanque ${estanque['numero']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedEstanqueId = value ?? _selectedEstanqueId);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _especieController,
                      decoration: const InputDecoration(
                        labelText: 'Especie',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cantidadController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad Inicial',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Fecha de Siembra'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(_fechaSiembra),
                      ),
                      trailing: const Icon(Icons.calendar_today),
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
                    const SizedBox(height: 24),
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _actualizarSiembra,
                            icon: const Icon(Icons.save),
                            label: const Text('Actualizar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _registrarMuertes,
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
                  ],
                ),
              ),
            ),
    ));
  }
}
