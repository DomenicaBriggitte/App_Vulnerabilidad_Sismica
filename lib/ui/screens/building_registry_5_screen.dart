// building_registry_5_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BuildingRegistry5Screen extends StatefulWidget {
  final String nombre;
  final String direccion;
  final String codigoPostal;
  final String uso;
  final String latitud;
  final String longitud;
  final String inspector;
  final String fecha;
  final String hora;
  final String? fotoUrl;
  final String? graficoUrl;
  final String pisos;
  final String area;
  final String anioConstruccion;
  final bool ampliacionSi;
  final String anioAmpliacion;
  final String verificacion;
  final String ocupacion;
  final String unidades;

  const BuildingRegistry5Screen({
    super.key,
    this.nombre = '',
    this.direccion = '',
    this.codigoPostal = '',
    this.uso = '',
    this.latitud = '',
    this.longitud = '',
    this.inspector = '',
    this.fecha = '',
    this.hora = '',
    this.fotoUrl,
    this.graficoUrl,
    this.pisos = '',
    this.area = '',
    this.anioConstruccion = '',
    this.ampliacionSi = false,
    this.anioAmpliacion = '',
    this.verificacion = '',
    this.ocupacion = '',
    this.unidades = '',
  });

  @override
  State<BuildingRegistry5Screen> createState() =>
      _BuildingRegistry5ScreenState();
}

class _BuildingRegistry5ScreenState extends State<BuildingRegistry5Screen> {
  final _formKey = GlobalKey<FormState>();

  final comentariosController = TextEditingController();
  String? _tipoSueloSeleccionado;

  final List<Map<String, String>> _tipoSueloOpciones = [
    {"valor": "A", "texto": "A: Roca dura"},
    {"valor": "B", "texto": "B: Roca semi-dura"},
    {"valor": "C", "texto": "C: Suelo denso"},
    {"valor": "D", "texto": "D: Suelo rígido"},
    {"valor": "E", "texto": "E: Suelo blando"},
    {"valor": "F", "texto": "F: Suelo pobre"},
  ];

  @override
  void initState() {
    super.initState();
    // valor por defecto = D: Suelo rígido
    _tipoSueloSeleccionado = "D";
  }

  void _siguiente() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SizedBox(), // Aquí enlazarás la pantalla 6
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tipo de suelo y observaciones"),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // regresa a pantalla 4
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo tipo de suelo
              const Text("Tipo de suelo"),
              DropdownButtonFormField<String>(
                value: _tipoSueloSeleccionado,
                items: _tipoSueloOpciones
                    .map((e) =>
                    DropdownMenuItem(value: e["valor"], child: Text(e["texto"]!)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoSueloSeleccionado = v),
                decoration: _inputDecoration("Seleccione tipo de suelo"),
              ),
              const SizedBox(height: 10),

              // Mensaje de aviso
              const Text(
                "Aviso: Si no se conoce asumir tipo D",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Campo de comentarios
              TextFormField(
                controller: comentariosController,
                decoration: _inputDecoration("Comentarios"),
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // Botón siguiente
              ElevatedButton(
                onPressed: _siguiente,
                child: const Text("Siguiente"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
