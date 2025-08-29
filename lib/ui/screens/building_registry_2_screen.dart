import 'package:flutter_application_1/ui/screens/profile_page.dart';

import '../../ui/screens/assessed_buildings_screen.dart';
//import 'package:evs/pages/perfil_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';

class RegistroEdificio2Page extends StatefulWidget {
  final String nombre;
  final String direccion;
  final String codigoPostal;
  final String uso;
  final String latitud;
  final String longitud;
  final String inspector;
  final String fechaHora;
  final String? fotoUrl;
  final String? graficoUrl;

  const RegistroEdificio2Page({
    super.key,
    required this.nombre,
    required this.direccion,
    required this.codigoPostal,
    required this.uso,
    required this.latitud,
    required this.longitud,
    required this.inspector,
    required this.fechaHora,
    this.fotoUrl,
    this.graficoUrl,
  });

  @override
  State<RegistroEdificio2Page> createState() => _RegistroEdificio2PageState();
}

class _RegistroEdificio2PageState extends State<RegistroEdificio2Page> {
  final _formKey = GlobalKey<FormState>();

  final pisosController = TextEditingController();
  final areaController = TextEditingController();
  final anioConstruccionController = TextEditingController();
  final anioAmpliacionController = TextEditingController();
  final unidadesController = TextEditingController();
  bool _ampliacionSi = false;
  String? _ocupacionSeleccionada;

  int _selectedIndex = 0;

  int currentYear = DateTime.now().year;


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
  final List<String> _ocupacionOpciones = [
    "Asamblea", "Comercial", "Servicios Em.", "Industria", "Oficina", "Escuela",
    "Almacén", "Residencial", "Herramientas",
  ];

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD3D3D3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF195AE6), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  Future<void> _guardarEnSupabase() async {
    final supabase = Supabase.instance.client;

    int? parseInt(String? value) {
      if (value == null || value.isEmpty) return null;
      return int.tryParse(value);
    }

    await supabase.from('edificios').insert({
      'nombre_edificio': widget.nombre,
      'direccion': widget.direccion,
      'codigo_postal': widget.codigoPostal,
      'uso_principal': widget.uso,
      'latitud': widget.latitud,
      'longitud': widget.longitud,
      'inspector': widget.inspector,
      'fecha_hora': widget.fechaHora,
      'foto_url': widget.fotoUrl,
      'grafico_url': widget.graficoUrl,
      'numero_pisos': parseInt(pisosController.text),
      'area_total_pisos': parseInt(areaController.text),
      'anio_construccion': parseInt(anioConstruccionController.text),
      'anio_ampliacion': _ampliacionSi
          ? parseInt(anioAmpliacionController.text)
          : null,
      'ocupacion': _ocupacionSeleccionada,
      'unidades': parseInt(unidadesController.text),
    });

    pisosController.clear();
    areaController.clear();
    anioConstruccionController.clear();
    anioAmpliacionController.clear();
    unidadesController.clear();
    setState(() {
      _ampliacionSi = false;
      _ocupacionSeleccionada = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Datos guardados en Supabase ✅")),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AssessedBuildingsPage()),
      (route) => false,
    );
  }

  void _siguiente() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Siguiente paso... 🚀")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 251, 249),
      appBar: AppBar(
        title: const Text(
          "Registro Edificio",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF195AE6),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: pisosController,
                keyboardType: TextInputType.number,
                maxLength: 3,
                decoration: _inputDecoration("Número de pisos"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingrese el número de pisos";
                  }
                  final n = int.tryParse(value);
                  if (n == null || n < 1) {
                    return "Debe ser un número entero ≥ 1";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: areaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration("Área total de piso (m²)"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingrese el área total";
                  }
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) {
                    return "Debe ser un número decimal > 0";
                  }
                  final parts = value.split(".");
                  if (parts.length == 2 && parts[1].length > 2) {
                    return "Máx. 2 decimales";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: anioConstruccionController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: _inputDecoration("Año de construcción"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingrese el año de construcción";
                  }
                  final n = int.tryParse(value);
                  if (n == null || n < 1800 || n > currentYear) {
                    return "Debe estar entre 1800 y $currentYear";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              const Text(
                "¿Ampliación?",
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _ampliacionSi = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _ampliacionSi
                              ? const Color(0xFF19DBE6)
                              : Colors.white,
                          border: Border.all(color: const Color(0xFFD3D3D3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            "SI",
                            style: TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _ampliacionSi = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_ampliacionSi
                              ? const Color(0xFF19DBE6)
                              : Colors.white,
                          border: Border.all(color: const Color(0xFFD3D3D3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            "NO",
                            style: TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: anioAmpliacionController,
                enabled: _ampliacionSi,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: _inputDecoration("Año de ampliación"),
                validator: (value) {
                  if (!_ampliacionSi) return null;
                  if (value == null || value.isEmpty) {
                    return "Ingrese el año de ampliación";
                  }
                  final n = int.tryParse(value);
                  final construccion = int.tryParse(
                    anioConstruccionController.text,
                  );
                  if (n == null ||
                      construccion == null ||
                      n < construccion ||
                      n > currentYear) {
                    return "Debe ser ≥ año construcción y ≤ $currentYear";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                "Ocupación",
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 2.5,
                physics: const NeverScrollableScrollPhysics(),
                children: _ocupacionOpciones.map((opcion) {
                  final isSelected = _ocupacionSeleccionada == opcion;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _ocupacionSeleccionada = opcion),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF19DBE6)
                            : Colors.white,
                        border: Border.all(color: const Color(0xFFD3D3D3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          opcion,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF1E1E1E)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: unidadesController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                decoration: _inputDecoration("Unidades"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingrese el número de unidades";
                  }
                  final n = int.tryParse(value);
                  if (n == null || n < 1) {
                    return "Debe ser un número entero ≥ 1";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19E6AC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _siguiente,
                child: const Text(
                  "Siguiente",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _guardarEnSupabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19DBE6),
                    ),
                    child: const Text(
                      "Finalizar",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
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
      ),
    );
  }
}
