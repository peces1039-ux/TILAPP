// Tabla Alimentacion Form Sheet
// Related: T092, T094, US8
// Form for creating/editing feeding tables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tabla_alimentacion.dart';
import '../services/tablas_alimentacion_service.dart';
import '../widgets/bottom_sheet_form.dart';

class TablaAlimentacionFormSheet extends StatefulWidget {
  final TablaAlimentacion? tabla;
  final VoidCallback onSaved;

  const TablaAlimentacionFormSheet({
    super.key,
    this.tabla,
    required this.onSaved,
  });

  static Future<bool?> show(
    BuildContext context, {
    TablaAlimentacion? tabla,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TablaAlimentacionFormSheet(tabla: tabla, onSaved: onSaved),
    );
  }

  @override
  State<TablaAlimentacionFormSheet> createState() =>
      _TablaAlimentacionFormSheetState();
}

class _TablaAlimentacionFormSheetState
    extends State<TablaAlimentacionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tablasService = TablasAlimentacionService();

  late TextEditingController _edadSemanasController;
  late TextEditingController _pesoMinGramosController;
  late TextEditingController _pesoMaxGramosController;
  late TextEditingController _porcentajeBiomasaController;
  late TextEditingController _racionesDiariasController;

  String? _selectedReferenciaAlimento;

  // Lista de referencias de alimento disponibles
  static const List<String> _referenciasAlimento = [
    'Mojarra 45 Harina',
    'Mojarra 45 Extruder',
    'Mojarra 38',
    'Mojarra 32 - 3.5 mm',
    'Mojarra 32 - 4.5 mm',
    'Mojarra 24',
  ];

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.tabla != null;

    _edadSemanasController = TextEditingController(
      text: widget.tabla?.edadSemanas.toString() ?? '',
    );
    _pesoMinGramosController = TextEditingController(
      text: widget.tabla?.pesoMinGramos.toString() ?? '',
    );
    _pesoMaxGramosController = TextEditingController(
      text: widget.tabla?.pesoMaxGramos.toString() ?? '',
    );
    _porcentajeBiomasaController = TextEditingController(
      text: widget.tabla?.porcentajeBiomasa.toString() ?? '',
    );
    _racionesDiariasController = TextEditingController(
      text: widget.tabla?.racionesDiarias.toString() ?? '',
    );
    _selectedReferenciaAlimento = widget.tabla?.referenciaAlimento;
  }

  @override
  void dispose() {
    _edadSemanasController.dispose();
    _pesoMinGramosController.dispose();
    _pesoMaxGramosController.dispose();
    _porcentajeBiomasaController.dispose();
    _racionesDiariasController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedReferenciaAlimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar una referencia de alimento'),
          backgroundColor: const Color(0xFF003D7A),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final edadSemanas = int.parse(_edadSemanasController.text);
      final pesoMinGramos = double.parse(_pesoMinGramosController.text);
      final pesoMaxGramos = double.parse(_pesoMaxGramosController.text);
      final porcentajeBiomasa = double.parse(_porcentajeBiomasaController.text);
      final racionesDiarias = int.parse(_racionesDiariasController.text);

      if (_isEditing) {
        await _tablasService.update(
          widget.tabla!.copyWith(
            edadSemanas: edadSemanas,
            pesoMinGramos: pesoMinGramos,
            pesoMaxGramos: pesoMaxGramos,
            porcentajeBiomasa: porcentajeBiomasa,
            referenciaAlimento: _selectedReferenciaAlimento!,
            racionesDiarias: racionesDiarias,
          ),
        );
      } else {
        await _tablasService.create(
          TablaAlimentacion(
            id: '',
            edadSemanas: edadSemanas,
            pesoMinGramos: pesoMinGramos,
            pesoMaxGramos: pesoMaxGramos,
            porcentajeBiomasa: porcentajeBiomasa,
            referenciaAlimento: _selectedReferenciaAlimento!,
            racionesDiarias: racionesDiarias,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      if (!mounted) return;

      widget.onSaved();
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Tabla actualizada exitosamente'
                : 'Tabla creada exitosamente',
          ),
          backgroundColor: const Color(0xFF00BCD4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetForm(
      title: _isEditing ? 'Editar Tabla' : 'Nueva Tabla de Alimentación',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Edad en semanas
              TextFormField(
                controller: _edadSemanasController,
                decoration: const InputDecoration(
                  labelText: 'Edad (semanas)',
                  hintText: 'Ej: 5',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La edad es requerida';
                  }
                  final edad = int.tryParse(value);
                  if (edad == null || edad <= 0) {
                    return 'Debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Peso Min y Max en gramos
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pesoMinGramosController,
                      decoration: const InputDecoration(
                        labelText: 'Peso Mín (gramos)',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        final peso = double.tryParse(value);
                        if (peso == null || peso < 0) {
                          return 'Debe ser >= 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pesoMaxGramosController,
                      decoration: const InputDecoration(
                        labelText: 'Peso Máx (gramos)',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        final pesoMax = double.tryParse(value);
                        if (pesoMax == null || pesoMax < 0) {
                          return 'Debe ser >= 0';
                        }
                        final pesoMin = double.tryParse(
                          _pesoMinGramosController.text,
                        );
                        if (pesoMin != null && pesoMax < pesoMin) {
                          return 'Debe ser >= peso mín';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Porcentaje de biomasa
              TextFormField(
                controller: _porcentajeBiomasaController,
                decoration: const InputDecoration(
                  labelText: 'Porcentaje de Biomasa (%)',
                  hintText: 'Ej: 3.5',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El porcentaje es requerido';
                  }
                  final porcentaje = double.tryParse(value);
                  if (porcentaje == null || porcentaje <= 0) {
                    return 'Debe ser mayor a 0';
                  }
                  if (porcentaje > 100) {
                    return 'No puede ser mayor a 100%';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Referencia de alimento (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedReferenciaAlimento,
                decoration: const InputDecoration(
                  labelText: 'Referencia de Alimento',
                  prefixIcon: Icon(Icons.restaurant),
                ),
                items: _referenciasAlimento.map((String referencia) {
                  return DropdownMenuItem<String>(
                    value: referencia,
                    child: Text(referencia),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedReferenciaAlimento = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Debe seleccionar una referencia';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Raciones diarias
              TextFormField(
                controller: _racionesDiariasController,
                decoration: const InputDecoration(
                  labelText: 'Raciones Diarias',
                  hintText: 'Ej: 3',
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Las raciones son requeridas';
                  }
                  final raciones = int.tryParse(value);
                  if (raciones == null || raciones <= 0) {
                    return 'Debe ser mayor a 0';
                  }
                  if (raciones > 10) {
                    return 'Máximo 10 raciones al día';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'Actualizar' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
