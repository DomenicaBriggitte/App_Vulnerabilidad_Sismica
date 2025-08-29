import 'package:flutter/material.dart';
import 'app_colors.dart';

class RegisterBuildingPage2 extends StatefulWidget {
  const RegisterBuildingPage2({super.key});

  @override
  State<RegisterBuildingPage2> createState() => _RegisterBuildingPage2State();
}

class _RegisterBuildingPage2State extends State<RegisterBuildingPage2> {
  final _formKey = GlobalKey<FormState>();
  final _otherIdsController = TextEditingController();
  final _useController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _inspectorController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

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
          child: SingleChildScrollView( // Añade esto para permitir scroll
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Datos complementarios y localización',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otherIdsController,
                  decoration: const InputDecoration(
                    labelText: 'Otras identificaciones',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _useController,
                  decoration: const InputDecoration(
                    labelText: 'Uso',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Latitud',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Longitud',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _inspectorController,
                  decoration: const InputDecoration(
                    labelText: 'Inspector',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'mm/dd/yy',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(thickness: 1, height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    border: Border.all(color: AppColors.error),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mensaje',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error)),
                      const SizedBox(height: 8),
                      const Text(
                        'Cuando la información no se puede verificar, deberá escribir:',
                        style: TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 8),
                      Text('EST - Dato estimado/irreal',
                          style: TextStyle(color: AppColors.error)),
                      Text('DNK - No se conoce o vacio',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Guardar datos y finalizar registro
                        Navigator.popUntil(context, (route) => route.isFirst);
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

  @override
  void dispose() {
    _otherIdsController.dispose();
    _useController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _inspectorController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}