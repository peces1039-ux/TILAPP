import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/biometria.dart';
import '../services/biometria_service.dart';
import 'bottom_sheet_form.dart';

class BiometriaFormSheet extends StatefulWidget {
  final String siembraId;
  final Biometria? biometria;
  final VoidCallback onSaved;

  const BiometriaFormSheet({
    super.key,
    required this.siembraId,
    this.biometria,
    required this.onSaved,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String siembraId,
    Biometria? biometria,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BiometriaFormSheet(
        siembraId: siembraId,
        biometria: biometria,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<BiometriaFormSheet> createState() => _BiometriaFormSheetState();
}

class _BiometriaFormSheetState extends State<BiometriaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final BiometriaService _biometriaService = BiometriaService();

  late DateTime _fecha;
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _tamanoController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.biometria != null;
    _fecha = widget.biometria?.fecha ?? DateTime.now();
    _pesoController.text = widget.biometria?.pesoPromedio.toString() ?? '';
    _tamanoController.text = widget.biometria?.tamanoPromedio.toString() ?? '';
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _tamanoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) {
      setState(() => _fecha = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final peso = double.parse(_pesoController.text.trim());
      final tamano = double.parse(_tamanoController.text.trim());

      if (_isEditing) {
        await _biometriaService.update(
          widget.biometria!.copyWith(
            fecha: _fecha,
            pesoPromedio: peso,
            tamanoPromedio: tamano,
          ),
        );
      } else {
        await _biometriaService.create(
          Biometria(
            id: '',
            userId: '',
            siembraId: widget.siembraId,
            fecha: _fecha,
            pesoPromedio: peso,
            tamanoPromedio: tamano,
            createdAt: DateTime.now(),
          ),
        );
      }

      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Biometría actualizada' : 'Biometría registrada',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetForm(
      title: _isEditing ? 'Editar Biometría' : 'Nueva Biometría',
      onCancel: () => Navigator.of(context).pop(false),
      onSave: _handleSave,
      isLoading: _isLoading,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_fecha),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Peso promedio
              TextFormField(
                controller: _pesoController,
                decoration: const InputDecoration(
                  labelText: 'Peso promedio (g) *',
                  border: OutlineInputBorder(),
                  helperText: 'Ejemplo: 150.5',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El peso es obligatorio';
                  }
                  final peso = double.tryParse(value.trim());
                  if (peso == null || peso <= 0) {
                    return 'El peso debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tamaño promedio
              TextFormField(
                controller: _tamanoController,
                decoration: const InputDecoration(
                  labelText: 'Tamaño promedio (cm) *',
                  border: OutlineInputBorder(),
                  helperText: 'Ejemplo: 15.5',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El tamaño es obligatorio';
                  }
                  final tamano = double.tryParse(value.trim());
                  if (tamano == null || tamano <= 0) {
                    return 'El tamaño debe ser mayor a 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
