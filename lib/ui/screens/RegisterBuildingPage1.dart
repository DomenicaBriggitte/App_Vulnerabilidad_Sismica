import 'package:flutter/material.dart';
import 'app_colors.dart';

class RegisterBuildingPage1 extends StatefulWidget {
  const RegisterBuildingPage1({super.key});

  @override
  State<RegisterBuildingPage1> createState() => _RegisterBuildingPage1State();
}

class _RegisterBuildingPage1State extends State<RegisterBuildingPage1> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _buildingNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SismosApp'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView( // Añadido para permitir scroll
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Registro de Edificio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(thickness: 1, height: 24),
                const Text('Identificación inicial y fachada',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildUploadButton('Subir foto', Icons.photo_camera),
                    _buildUploadButton('Subir gráfico', Icons.bar_chart),
                  ],
                ),
                const Divider(thickness: 1, height: 32),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la dirección';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Código Postal',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el código postal';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _buildingNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Edificio',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre del edificio';
                    }
                    return null;
                  },
                ),
                const Divider(thickness: 1, height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pushNamed(context, '/register-building-2');
                      }
                    },
                    child: const Text('Siguiente'),
                  ),
                ),
                const SizedBox(height: 20), // Espacio adicional al final
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(String text, IconData icon) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 40, color: AppColors.gray500),
        ),
        const SizedBox(height: 8),
        Text(text),
      ],
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _postalCodeController.dispose();
    _buildingNameController.dispose();
    super.dispose();
  }
}