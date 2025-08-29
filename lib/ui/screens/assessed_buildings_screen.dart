import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/screens/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ui/screens/building_registry_1_screen.dart';
import 'home_page.dart';

class AssessedBuildingsPage extends StatefulWidget {
  const AssessedBuildingsPage({super.key});

  @override
  State<AssessedBuildingsPage> createState() => _AssessedBuildingsPageState();
}

class _AssessedBuildingsPageState extends State<AssessedBuildingsPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _futureEdificios;
  List<Map<String, dynamic>> _edificios = [];
  List<Map<String, dynamic>> _filteredEdificios = [];
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final Color colorFondo = const Color(0xFFF9FAFB);
  final Color colorTexto = const Color(0xFF1E1E1E);
  final Color colorSecundario = const Color(0xFF6B7280);
  final Color colorPrimario = const Color(0xFF195AE6);
  final Color colorAlertaVerde = const Color(0xFF22C55E);
  final Color colorAlertaAmarillo = const Color(0xFFEAB308);
  final Color colorAlertaRojo = const Color(0xFFDC2626);

  Future<List<Map<String, dynamic>>> _getEdificios() async {
    final response = await supabase
        .from('edificios')
        .select('*')
        .order('id_edificio', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  void initState() {
    super.initState();
    _futureEdificios = _getEdificios();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEdificios = _edificios
          .where((edificio) =>
          (edificio['nombre_edificio'] ?? "").toLowerCase().contains(query))
          .toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      ).then((_) => setState(() => _selectedIndex = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 28,
              color: colorPrimario,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "SismosApp",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              color: colorPrimario,
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              width: double.infinity,
              child: const Text(
                "Edificios",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureEdificios,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text("Error: ${snapshot.error}",
                            style: TextStyle(color: colorAlertaRojo)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text("No hay edificios registrados",
                            style: TextStyle(color: colorSecundario)));
                  }

                  _edificios = snapshot.data!;
                  _filteredEdificios = _filteredEdificios.isEmpty
                      ? _edificios
                      : _filteredEdificios;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Edificios Evaluados",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: colorTexto,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Buscar edificio por nombre...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorPrimario),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _filteredEdificios.length,
                          itemBuilder: (context, index) {
                            final edificio = _filteredEdificios[index];

                            return SizedBox(
                              height: 250,
                              width: 180,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (edificio['foto_url'] != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            edificio['foto_url'],
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Text(
                                        edificio['nombre_edificio'] ?? "Sin nombre",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: colorTexto,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        edificio['direccion'] ?? "Sin dirección",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colorSecundario,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: colorPrimario,
        unselectedItemColor: colorSecundario,
      ),
    );
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
