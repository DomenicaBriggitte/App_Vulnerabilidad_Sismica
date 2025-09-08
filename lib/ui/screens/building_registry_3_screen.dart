import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ui/screens/assessed_buildings_screen.dart';
import '../../ui/screens/profile_page.dart';
import '../../ui/screens/home_page.dart';
import '../../core/theme/app_colors.dart';
import 'building_registry_4_screen.dart';

class BuildingRegistry3Screen extends StatefulWidget {
  final String nombre;
  final String direccion;
  final String codigoPostal;
  final String uso;
  final String latitud;
  final String longitud;
  final String inspector;
  final String? fotoUrl;
  final String? graficoUrl;
  final String otrasIdentificaciones;
  final String fecha;
  final String hora;

  const BuildingRegistry3Screen({
    super.key,
    this.nombre = "",
    this.direccion = "",
    this.codigoPostal = "",
    this.uso = "",
    this.latitud = "",
    this.longitud = "",
    this.inspector = "",
    this.fotoUrl,
    this.graficoUrl,
    this.otrasIdentificaciones= "",
    this.fecha= "",
    this.hora= "",
  });

  @override
  State<BuildingRegistry3Screen> createState() => _BuildingRegistry3ScreenState();
}

class _BuildingRegistry3ScreenState extends State<BuildingRegistry3Screen> {
  final _formKey = GlobalKey<FormState>();

  final pisosController = TextEditingController();
  final areaController = TextEditingController();
  final anioConstruccionController = TextEditingController();
  final anioAmpliacionController = TextEditingController();

  bool _ampliacionSi = false;
  String? _verificacionSeleccionada;

  final List<String> _verificacionOpciones = ["REAL", "EST", "DNK"];
  int _selectedIndex = 0;
  int currentYear = DateTime.now().year;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.gray500),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  void _siguiente() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuildingRegistry4Screen(
            nombre: widget.nombre,
            direccion: widget.direccion,
            codigoPostal: widget.codigoPostal,
            uso: widget.uso,
            latitud: widget.latitud,
            longitud: widget.longitud,
            inspector: widget.inspector,
            fecha: widget.fecha,
            hora: widget.hora,
            fotoUrl: widget.fotoUrl,
            graficoUrl: widget.graficoUrl,
            pisos: pisosController.text,
            area: areaController.text,
            anioConstruccion: anioConstruccionController.text,
            ampliacionSi: _ampliacionSi,
            anioAmpliacion: anioAmpliacionController.text,
            verificacion: _verificacionSeleccionada ?? "DNK",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Características estructurales"),
        backgroundColor: AppColors.primary,
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
                validator: (v) => v == null || v.isEmpty ? "Ingrese el número de pisos" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: areaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration("Área total de piso (m²)"),
                validator: (v) => v == null || v.isEmpty ? "Ingrese el área total" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: anioConstruccionController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: _inputDecoration("Año de construcción"),
              ),
              const SizedBox(height: 10),
              const Text("¿Ampliación?"),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _ampliacionSi = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _ampliacionSi ? AppColors.primary : Colors.white,
                          border: Border.all(color: AppColors.gray300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text("SI")),
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
                          color: !_ampliacionSi ? AppColors.primary : Colors.white,
                          border: Border.all(color: AppColors.gray300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text("NO")),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_ampliacionSi)
                TextFormField(
                  controller: anioAmpliacionController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: _inputDecoration("Año de ampliación"),
                ),
              const SizedBox(height: 10),
              const Text("Verificación de la información"),
              DropdownButtonFormField<String>(
                value: _verificacionSeleccionada,
                items: _verificacionOpciones
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _verificacionSeleccionada = v),
                decoration: _inputDecoration("Seleccione"),
              ),
              const SizedBox(height: 10),
              const Text(
                "- Mensaje\nCuando la información no se pueda verificar, deberá #sooger\nREAL Dato reales/existentes\nEST Dato estimado/immal\nDNK No se conoce o vacío",
                style: TextStyle(color: AppColors.gray500),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _siguiente,
                child: const Text("Siguiente"),
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
