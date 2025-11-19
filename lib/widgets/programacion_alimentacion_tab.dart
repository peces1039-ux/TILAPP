// Programacion Alimentacion Tab
// Shows daily feeding schedule with checklist for each ration
// Schedule calculated based on daily rations from 8:00 AM to 4:00 PM
// Persists rations in database for historical tracking

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tabla_alimentacion.dart';
import '../models/biometria.dart';
import '../models/racion.dart';
import '../services/raciones_service.dart';

class ProgramacionAlimentacionTab extends StatefulWidget {
  final TablaAlimentacion? tablaAlimentacion;
  final Biometria? ultimaBiometria;
  final String siembraId;

  const ProgramacionAlimentacionTab({
    super.key,
    this.tablaAlimentacion,
    this.ultimaBiometria,
    required this.siembraId,
  });

  @override
  State<ProgramacionAlimentacionTab> createState() =>
      _ProgramacionAlimentacionTabState();
}

class _ProgramacionAlimentacionTabState
    extends State<ProgramacionAlimentacionTab> {
  final _racionesService = RacionesService();
  List<Racion> _raciones = [];
  bool _isLoading = false;
  DateTime get _selectedDate => DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadOrGenerateRaciones();
  }

  @override
  void didUpdateWidget(ProgramacionAlimentacionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if biometria or tabla alimentacion changed
    if (oldWidget.ultimaBiometria != widget.ultimaBiometria ||
        oldWidget.tablaAlimentacion != widget.tablaAlimentacion) {
      _loadOrGenerateRaciones();
    }
  }

  Future<void> _loadOrGenerateRaciones() async {
    if (widget.tablaAlimentacion == null || widget.ultimaBiometria == null) {
      setState(() {
        _raciones = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Try to load existing raciones for selected date
      var raciones = await _racionesService.getRacionesByFecha(
        widget.siembraId,
        _selectedDate,
      );

      // If no raciones exist, generate them
      if (raciones.isEmpty) {
        raciones = await _racionesService.generateDailyRaciones(
          siembraId: widget.siembraId,
          fecha: _selectedDate,
          ultimaBiometria: widget.ultimaBiometria!,
          tablaAlimentacion: widget.tablaAlimentacion!,
        );
      }

      if (!mounted) return;

      setState(() {
        _raciones = raciones;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar raciones: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleRacion(Racion racion) async {
    try {
      if (racion.completada) {
        await _racionesService.markAsNotCompleted(racion.id);
      } else {
        await _racionesService.markAsCompleted(racion.id);
      }

      // Reload raciones to reflect changes
      await _loadOrGenerateRaciones();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDate() async {
    // Selector de fecha deshabilitado: solo programación de hoy
    return;
  }

  double _calcularTotalDiario() {
    return _raciones.fold<double>(0, (sum, r) => sum + r.cantidadGramos);
  }

  int _calcularCompletadas() {
    return _raciones.where((r) => r.completada).length;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tablaAlimentacion == null || widget.ultimaBiometria == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay programación disponible',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra una biometría para calcular la programación',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_raciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se pudo generar la programación',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOrGenerateRaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final totalDiario = _calcularTotalDiario();
    final completadas = _calcularCompletadas();

    return Column(
      children: [
        // Header card with date and summary
        Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Date row (sin selector)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'es',
                        ).format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                // Summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Total Diario',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${totalDiario.toStringAsFixed(2)} g',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.grey[300]),
                    Column(
                      children: [
                        Text(
                          'Completadas',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completadas / ${_raciones.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.grey[300]),
                    Column(
                      children: [
                        Text(
                          'Raciones',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_raciones.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
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
        // Checklist
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOrGenerateRaciones,
            child: SafeArea(
              top: false,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _raciones.length,
                itemBuilder: (context, index) {
                  final racion = _raciones[index];
                  final isCompletada = racion.completada;
                  final isPastDue = racion.isPastDue;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isCompletada
                        ? Colors.green[50]
                        : (isPastDue ? Colors.red[50] : null),
                    child: CheckboxListTile(
                      value: isCompletada,
                      onChanged: (value) => _toggleRacion(racion),
                      title: Row(
                        children: [
                          Icon(
                            isCompletada
                                ? Icons.check_circle
                                : (isPastDue ? Icons.warning : Icons.schedule),
                            color: isCompletada
                                ? Colors.green[700]
                                : (isPastDue
                                      ? Colors.red[700]
                                      : Colors.blue[700]),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ración ${racion.numeroRacion}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isCompletada
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                racion.horaProgramadaFormatted,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.scale,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                racion.cantidadFormatted,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (isCompletada && racion.horaCompletada != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '✓ Completada a las ${racion.horaCompletadaFormatted}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (isPastDue && !isCompletada)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '⚠️ Hora programada pasada',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      secondary: isCompletada
                          ? Icon(Icons.check_circle, color: Colors.green[700])
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
