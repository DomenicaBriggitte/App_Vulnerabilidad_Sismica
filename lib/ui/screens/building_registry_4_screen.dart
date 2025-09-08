import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
//import 'building_registry_5_screen.dart';

class BuildingRegistry4Screen extends StatefulWidget {
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

  const BuildingRegistry4Screen({
    super.key,
    this.nombre='',
    this.direccion='',
    this.codigoPostal='',
    this.uso='',
    this.latitud='',
    this.longitud='',
    this.inspector='',
    this.fecha='',
    this.hora='',
    this.fotoUrl,
    this.graficoUrl,
    this.pisos='',
    this.area='',
    this.anioConstruccion='',
    this.ampliacionSi= false,
    this.anioAmpliacion='',
    this.verificacion='',
  });

  @override
  State<BuildingRegistry4Screen> createState() => _BuildingRegistry4ScreenState();
}

class _BuildingRegistry4ScreenState extends State<BuildingRegistry4Screen> {
  final _formKey = GlobalKey<FormState>();
  final unidadesController = TextEditingController();
  String? _tipoSeleccionado;
  final List<String> _tipoOpciones = [
    "Asamblea", "Comercial", "Servicios Em.", "Industria", "Oficina", "Escuela",
    "Almacén", "Residencial", "Historico", "Albergue", "Gubernamentas", "Herramientas", "Almacen", "Otros"
  ];

  void _siguiente() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SizedBox()), // reemplazar por building_registry_5_screen
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
        title: const Text("Ocupación y Unidades"),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Tipo de ocupación"),
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                items: _tipoOpciones.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _tipoSeleccionado = v),
                decoration: _inputDecoration("Seleccione tipo"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: _inputDecoration("Si no selecciona, escriba aquí"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: unidadesController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Número de unidades"),
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
    );
  }
}
