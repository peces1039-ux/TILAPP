import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import '../screens/estanques_screen.dart';
import 'siembras_page.dart';
import 'biometria_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Lista de páginas a mostrar
  late final List<Widget> _pages = [
    const DashboardPage(),
    const EstanquesPage(),
    const SiembrasPage(),
    const BiometriaPage(),
  ];

  // Títulos de las secciones
  late final List<Map<String, String>> _sectionTitles = [
    {'title': 'Inicio', 'subtitle': 'Bienvenido a TilApp'},
    {'title': 'Mis Estanques', 'subtitle': 'Gestiona tus tanques'},
    {'title': 'Mis Siembras', 'subtitle': 'Control de sembrados'},
    {'title': 'Biometrías', 'subtitle': 'Monitoreo de biomasa'},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSection = _sectionTitles[_selectedIndex];

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentSection['title']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentSection['subtitle']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black87,
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water),
              label: 'Estanques',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.agriculture),
              label: 'Siembras',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_weight),
              label: 'Biometrías',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          elevation: 8,
        ),
      ),
    );
  }
}
