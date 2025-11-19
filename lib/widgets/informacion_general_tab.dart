// Informacion General Tab
// Shows main siembra information and latest biometria data

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/siembra.dart';
import '../models/biometria.dart';
import '../models/tabla_alimentacion.dart';

class InformacionGeneralTab extends StatelessWidget {
  final Siembra siembra;
  final Biometria? ultimaBiometria;
  final TablaAlimentacion? tablaAlimentacion;
  final bool hasBiometrias;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarcarCosechada;

  const InformacionGeneralTab({
    super.key,
    required this.siembra,
    this.ultimaBiometria,
    this.tablaAlimentacion,
    required this.hasBiometrias,
    required this.onEdit,
    required this.onDelete,
    required this.onMarcarCosechada,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: 48,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              siembra.especie,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            if (siembra.nombreEstanque != null)
                              Text(
                                'Estanque: ${siembra.nombreEstanque}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              siembra.cosechada
                                  ? 'Estado: Cosechada'
                                  : (siembra.isActive
                                        ? 'Estado: Activa'
                                        : 'Estado: Inactiva'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: siembra.cosechada
                                        ? Colors.orange
                                        : (siembra.isActive
                                              ? Colors.green
                                              : Colors.red),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Fecha de siembra',
                    DateFormat('dd/MM/yyyy').format(siembra.fechaSiembra),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactStat(
                          'Inicial',
                          siembra.cantidadInicial.toString(),
                          Icons.start,
                        ),
                      ),
                      Expanded(
                        child: _buildCompactStat(
                          'Actual',
                          siembra.cantidadActual.toString(),
                          Icons.numbers,
                        ),
                      ),
                      Expanded(
                        child: _buildCompactStat(
                          'Muertes',
                          siembra.cantidadMuertes.toString(),
                          Icons.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Si tiene biometrías, solo permitir marcar como cosechada
                  if (hasBiometrias && !siembra.cosechada)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onMarcarCosechada,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Marcar como cosechada'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  // Si no tiene biometrías, mostrar botones de edición y eliminación
                  if (!hasBiometrias)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Eliminar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Mensaje informativo si ya está cosechada
                  if (siembra.cosechada)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta siembra ha sido cosechada y no puede modificarse',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Mensaje informativo si tiene biometrías pero no está cosechada
                  if (hasBiometrias && !siembra.cosechada)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No se puede editar o eliminar: tiene biometrías registradas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Biometria info card
          if (ultimaBiometria != null)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Última Biometría',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(ultimaBiometria!.fecha),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildBiometriaInfo(
                      'Biomasa Total',
                      ultimaBiometria!.biomasaTotalFormatted,
                      Icons.scale,
                      Colors.green[700]!,
                    ),
                    const SizedBox(height: 8),
                    _buildBiometriaInfo(
                      'Alimento Diario',
                      ultimaBiometria!.cantidadAlimentoFormatted,
                      Icons.restaurant,
                      Colors.orange[700]!,
                    ),
                    if (ultimaBiometria!.fca != null) ...[
                      const SizedBox(height: 8),
                      _buildBiometriaInfo(
                        'FCA (Factor Conversión)',
                        ultimaBiometria!.fcaFormatted,
                        Icons.trending_up,
                        ultimaBiometria!.fca! < 2.0
                            ? Colors.green[700]!
                            : Colors.red[700]!,
                      ),
                    ],
                    if (tablaAlimentacion != null) ...[
                      const Divider(height: 16),
                      _buildBiometriaInfo(
                        'Referencia Alimento',
                        tablaAlimentacion!.referenciaAlimento,
                        Icons.info_outline,
                        Colors.blue[700]!,
                      ),
                      const SizedBox(height: 8),
                      _buildBiometriaInfo(
                        'Raciones Diarias',
                        '${tablaAlimentacion!.racionesDiarias} raciones/día',
                        Icons.schedule,
                        Colors.blue[700]!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (ultimaBiometria == null)
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay biometrías registradas',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ve a la pestaña Biometrías para agregar',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCompactStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBiometriaInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
