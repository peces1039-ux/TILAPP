// Estanque Form Sheet
// Related: T056, T062, US2, FR-009, FR-017
// Form for creating/editing estanques with validation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/estanque.dart';
import '../services/estanques_service.dart';
import '../widgets/bottom_sheet_form.dart';

class EstanqueFormSheet extends StatefulWidget {
  final Estanque? estanque; // null for create, not null for edit
  final VoidCallback? onSaved;

  const EstanqueFormSheet({super.key, this.estanque, this.onSaved});

  @override
  State<EstanqueFormSheet> createState() => _EstanqueFormSheetState();

  /// Show estanque form as bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    Estanque? estanque,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EstanqueFormSheet(estanque: estanque, onSaved: onSaved),
    );
  }
}

class _EstanqueFormSheetState extends State<EstanqueFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _estanquesService = EstanquesService();

  late TextEditingController _numeroController;
  late TextEditingController _capacidadController;
  bool _isLoading = false;

  bool get _isEditing => widget.estanque != null;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(
      text: widget.estanque?.numero.toString() ?? '',
    );
    _capacidadController = TextEditingController(
      text: widget.estanque?.capacidad.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final numero = _numeroController.text;
      final capacidad = double.parse(_capacidadController.text);

      if (_isEditing) {
        // Update existing estanque
        final updated = widget.estanque!.copyWith(
          numero: numero,
          capacidad: capacidad,
        );
        await _estanquesService.update(updated);
      } else {
        // Create new estanque
        final newEstanque = Estanque(
          userId: '', // Will be auto-added by service
          numero: numero,
          capacidad: capacidad,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _estanquesService.create(newEstanque);
      }

      if (!mounted) return;

      // Close sheet and notify success
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Estanque actualizado exitosamente'
                : 'Estanque creado exitosamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Call callback if provided
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      String errorMessage = 'Error: ${e.toString()}';

      // Handle specific error cases
      if (e.toString().contains('Ya existe un estanque')) {
        errorMessage = 'El número de estanque ya está en uso';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetForm(
      title: _isEditing ? 'Editar Estanque' : 'Nuevo Estanque',
      formKey: _formKey,
      isLoading: _isLoading,
      onSave: _handleSave,
      children: [
        // Numero field
        TextFormField(
          controller: _numeroController,
          decoration: const InputDecoration(
            labelText: 'Número de Estanque *',
            hintText: 'Ej: 1',
            prefixIcon: Icon(Icons.numbers),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El número es requerido';
            }
            final numero = int.tryParse(value);
            if (numero == null || numero <= 0) {
              return 'Ingrese un número válido mayor a 0';
            }
            return null;
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),

        // Capacidad field
        TextFormField(
          controller: _capacidadController,
          decoration: const InputDecoration(
            labelText: 'Capacidad (m³) *',
            hintText: 'Ej: 1000',
            prefixIcon: Icon(Icons.water),
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La capacidad es requerida';
            }
            final capacidad = double.tryParse(value);
            if (capacidad == null || capacidad <= 0) {
              return 'Ingrese una capacidad válida mayor a 0';
            }
            return null;
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 8),

        // Help text
        Text(
          '* Campos requeridos',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
