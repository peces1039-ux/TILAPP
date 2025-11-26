// Siembras Screen
// Related: T046, FR-011 to FR-015
// Displays list of user's siembras with card display and navigation to detail

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/siembras_service.dart';
import '../models/siembra.dart';
import '../widgets/siembra_form_sheet.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/fish_loading.dart';
import 'siembra_detalle_screen.dart';

class SiembrasScreen extends StatefulWidget {
  const SiembrasScreen({super.key});

  @override
  State<SiembrasScreen> createState() => _SiembrasScreenState();
}

class _SiembrasScreenState extends State<SiembrasScreen> {
  final _siembrasService = SiembrasService();
  List<Siembra> _siembras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSiembras();
  }

  Future<void> _loadSiembras() async {
    setState(() => _isLoading = true);

    try {
      final siembras = await _siembrasService.getAll();

      if (!mounted) return;

      setState(() {
        _siembras = siembras;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar siembras: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Siembras'),
        backgroundColor: const Color(0xFFF5F7FA),
        body: RefreshIndicator(
          onRefresh: _loadSiembras,
          child: _isLoading
              ? const FishLoading(
                  message: 'Cargando siembras...',
                )
              : _siembras.isEmpty
              ? const Center(
                  child: Text(
                    'No hay siembras registradas',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _siembras.length,
                  itemBuilder: (context, index) {
                    final siembra = _siembras[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          Icons.agriculture,
                          size: 40,
                          color: siembra.isActive ? const Color(0xFF00BCD4) : Colors.grey,
                        ),
                        title: Text(
                          siembra.especie,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(siembra.fechaSiembra)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cantidad: ${siembra.cantidadActual} / ${siembra.cantidadInicial}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      siembra.isActive
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 16,
                                      color: siembra.isActive
                                          ? const Color(0xFF00BCD4)
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      siembra.isActive ? 'Activa' : 'Inactiva',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: siembra.isActive
                                            ? const Color(0xFF00BCD4)
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Supervivencia: ${siembra.survivalRate.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SiembraDetalleScreen(siembraId: siembra.id),
                            ),
                          );
                          // Reload if siembra was deleted
                          if (result == true && mounted) {
                            await _loadSiembras();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await SiembraFormSheet.show(
              context,
              onSaved: _loadSiembras,
            );
            if (result == true && mounted) {
              await _loadSiembras();
            }
          },
          backgroundColor: const Color(0xFF003D7A),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
