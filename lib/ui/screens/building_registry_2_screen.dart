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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
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
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  Widget _labeledTextFormField(String label, TextEditingController controller, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(),
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
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
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _labeledTextFormField("Otras identificaciones", otrasIdentificacionesController),
                    const SizedBox(height: 16),

                    _labeledTextFormField("Uso del edificio", usoController),
                    const SizedBox(height: 16),

                    _labeledTextFormField("Latitud", latitudController, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),

                    _labeledTextFormField("Longitud", longitudController, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),

                    _labeledTextFormField("Nombre del inspector", inspectorController),
                    const SizedBox(height: 16),

                    // Fecha y Hora en fila horizontal
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Fecha (mm/dd/yy)",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: fechaController,
                                decoration: _inputDecoration(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Hora",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: horaController,
                                decoration: _inputDecoration(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
              ),
              const SizedBox(height: 16),
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