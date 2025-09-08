import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/screens/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/screens/building_registry_1_screen.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _futureEdificios;
  List<Map<String, dynamic>> _edificios = [];
  List<Map<String, dynamic>> _filteredEdificios = [];
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _userName = "";

  Future<List<Map<String, dynamic>>> _getEdificios() async {
    final response = await supabase
        .from('edificios')
        .select('*')
        .order('id_edificio', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _getUserName() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.userMetadata?['full_name'] ?? user.email ?? "";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _futureEdificios = _getEdificios();
    _getUserName();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEdificios = _edificios.where((edificio) {
        final nombre = (edificio['nombre_edificio'] ?? "").toLowerCase();
        final inspector = (edificio['inspector'] ?? "").toLowerCase();
        return nombre.contains(query) || inspector.contains(query);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0), // evitar overflow mínimo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mensaje "Hola, usuario"
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    "Hola, $_userName",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                // Encabezado Edificios Registrados + flecha de retroceso
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        "Edificios Registrados",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                // Barra de búsqueda
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar por nombre de edificio o inspector...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                // Botón Nuevo registro +
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/buildingRegistry1');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Nuevo registro +",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                // Lista de edificios
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _futureEdificios,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            "No hay edificios registrados",
                            style: TextStyle(color: AppColors.gray500),
                          ),
                        );
                      }

                      _edificios = snapshot.data!;
                      _filteredEdificios = _filteredEdificios.isEmpty
                          ? _edificios
                          : _filteredEdificios;

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredEdificios.length,
                        itemBuilder: (context, index) {
                          final edificio = _filteredEdificios[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Foto del edificio
                                  if (edificio['foto_url'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        edificio['foto_url'],
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: AppColors.gray500,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  // Información del edificio
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          edificio['nombre_edificio'] ?? "Sin nombre",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          edificio['fecha_hora'] ?? "Sin fecha",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Inspector: ${edificio['inspector'] ?? "Desconocido"}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          edificio['direccion'] ?? "Sin dirección",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
