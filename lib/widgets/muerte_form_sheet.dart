import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/muerte.dart';
import '../services/muertes_service.dart';
import 'bottom_sheet_form.dart';

class MuerteFormSheet extends StatefulWidget {
  final String siembraId;
  final Muerte? muerte;
  final VoidCallback onSaved;

  const MuerteFormSheet({
    super.key,
    required this.siembraId,
    this.muerte,
    required this.onSaved,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String siembraId,
    Muerte? muerte,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MuerteFormSheet(
        siembraId: siembraId,
        muerte: muerte,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<MuerteFormSheet> createState() => _MuerteFormSheetState();
}

class _MuerteFormSheetState extends State<MuerteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final MuertesService _muertesService = MuertesService();

  late DateTime _fecha;
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.muerte != null;
    _fecha = widget.muerte?.fecha ?? DateTime.now();
    _cantidadController.text = widget.muerte?.cantidad.toString() ?? '';
    _observacionesController.text = widget.muerte?.observaciones ?? '';
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionesController.dispose();
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
      final cantidad = int.parse(_cantidadController.text.trim());
      final observaciones = _observacionesController.text.trim();

      if (_isEditing) {
        await _muertesService.update(
          widget.muerte!.copyWith(
            fecha: _fecha,
            cantidad: cantidad,
            observaciones: observaciones.isEmpty ? null : observaciones,
          ),
        );
      } else {
        await _muertesService.create(
          Muerte(
            id: '',
            userId: '',
            siembraId: widget.siembraId,
            fecha: _fecha,
            cantidad: cantidad,
            observaciones: observaciones.isEmpty ? null : observaciones,
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
              _isEditing ? 'Registro actualizado' : 'Muertes registradas',
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
      title: _isEditing ? 'Editar Muertes' : 'Registrar Muertes',
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

              // Cantidad
              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad *',
                  border: OutlineInputBorder(),
                  helperText: 'Número de peces muertos',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La cantidad es obligatoria';
                  }
                  final cantidad = int.tryParse(value.trim());
                  if (cantidad == null || cantidad <= 0) {
                    return 'La cantidad debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Observaciones
              TextFormField(
                controller: _observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                  helperText: 'Causa o detalles adicionales',
                ),
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
