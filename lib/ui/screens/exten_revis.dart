import 'package:flutter/material.dart';

class ExtensionRevisionPage extends StatefulWidget {
  const ExtensionRevisionPage({super.key});

  @override
  State<ExtensionRevisionPage> createState() => _ExtensionRevisionPageState();
}

class _ExtensionRevisionPageState extends State<ExtensionRevisionPage> {
  bool _exteriorParcial = false;
  bool _exteriorTodosLados = false;
  bool _exteriorAereo = false;
  bool _interiorNo = false;
  bool _interiorVisible = false;
  bool _interiorIngreso = false;
  String? _revisionPlanosSeleccion = '';
  String? _requiereInspeccionSeleccion = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extensión de la revisión'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exterior',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Parcial'),
              value: _exteriorParcial,
              onChanged: (bool? value) {
                setState(() {
                  _exteriorParcial = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Todos los lados'),
              value: _exteriorTodosLados,
              onChanged: (bool? value) {
                setState(() {
                  _exteriorTodosLados = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Aéreo'),
              value: _exteriorAereo,
              onChanged: (bool? value) {
                setState(() {
                  _exteriorAereo = value ?? false;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Interior',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('No'),
              value: _interiorNo,
              onChanged: (bool? value) {
                setState(() {
                  _interiorNo = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Visible'),
              value: _interiorVisible,
              onChanged: (bool? value) {
                setState(() {
                  _interiorVisible = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Ingresó'),
              value: _interiorIngreso,
              onChanged: (bool? value) {
                setState(() {
                  _interiorIngreso = value ?? false;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Revisión de planos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text('Sí'),
              value: 'Sí',
              groupValue: _revisionPlanosSeleccion,
              onChanged: (String? value) {
                setState(() {
                  _revisionPlanosSeleccion = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('No'),
              value: 'No',
              groupValue: _revisionPlanosSeleccion,
              onChanged: (String? value) {
                setState(() {
                  _revisionPlanosSeleccion = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Container(
              height: 48,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Fuente del tipo de suelo',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 48,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Fuente del peligros geológicos',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 48,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Contacto',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Requiere inspección Nivel 2?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text('Sí'),
              value: 'Sí',
              groupValue: _requiereInspeccionSeleccion,
              onChanged: (String? value) {
                setState(() {
                  _requiereInspeccionSeleccion = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('No'),
              value: 'No',
              groupValue: _requiereInspeccionSeleccion,
              onChanged: (String? value) {
                setState(() {
                  _requiereInspeccionSeleccion = value;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Siguiente presionado')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Siguiente',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}