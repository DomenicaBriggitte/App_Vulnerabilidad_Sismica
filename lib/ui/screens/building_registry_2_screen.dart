import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'building_registry_3_screen.dart';
import 'home_page.dart';
import 'profile_page.dart';

class BuildingRegistry2Screen extends StatefulWidget {
  final String nombre;
  final String direccion;
  final String codigoPostal;
  final String? fotoUrl;
  final String? graficoUrl;

  const BuildingRegistry2Screen({
    super.key,
    this.nombre='',
    this.direccion='',
    this.codigoPostal='',
    this.fotoUrl,
    this.graficoUrl,
  });

  @override
  State<BuildingRegistry2Screen> createState() => _BuildingRegistry2ScreenState();
}

class _BuildingRegistry2ScreenState extends State<BuildingRegistry2Screen> {
  final _formKey = GlobalKey<FormState>();

  final otrasIdentificacionesController = TextEditingController();
  final usoController = TextEditingController();
  final latitudController = TextEditingController();
  final longitudController = TextEditingController();
  final inspectorController = TextEditingController();
  final fechaController = TextEditingController();
  final horaController = TextEditingController();

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  void _siguiente() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuildingRegistry3Screen(
            nombre: widget.nombre,
            direccion: widget.direccion,
            codigoPostal: widget.codigoPostal,
            fotoUrl: widget.fotoUrl,
            graficoUrl: widget.graficoUrl,
            otrasIdentificaciones: otrasIdentificacionesController.text,
            uso: usoController.text,
            latitud: latitudController.text,
            longitud: longitudController.text,
            inspector: inspectorController.text,
            fecha: fechaController.text,
            hora: horaController.text,
          ),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.gray500),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: const Text(
          "Registro Edificio",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: otrasIdentificacionesController,
                decoration: _inputDecoration("Otras identificaciones"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usoController,
                decoration: _inputDecoration("Uso del edificio"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: latitudController,
                decoration: _inputDecoration("Latitud"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: longitudController,
                decoration: _inputDecoration("Longitud"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: inspectorController,
                decoration: _inputDecoration("Nombre del inspector"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fechaController,
                decoration: _inputDecoration("Fecha"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: horaController,
                decoration: _inputDecoration("Hora"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
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
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
      ),
    );
  }
}
