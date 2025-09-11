import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../core/theme/app_colors.dart';
import 'building_registry_2_screen.dart';

class BuildingRegistry1Screen extends StatefulWidget {
  const BuildingRegistry1Screen({super.key});

  @override
  State<BuildingRegistry1Screen> createState() => _BuildingRegistry1ScreenState();
}

class _BuildingRegistry1ScreenState extends State<BuildingRegistry1Screen> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final direccionController = TextEditingController();
  final codigoPostalController = TextEditingController();

  File? _foto;
  File? _grafico;

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  Future<void> _pickFile(bool isFoto) async {
    final picker = ImagePicker();

    // Mostrar opciones al usuario
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Galería"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Cámara"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return; // Usuario canceló

    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileSize = await file.length();
    final mimeType = lookupMimeType(file.path);

    // VALIDACIÓN DE TAMAÑO (10MB máximo)
    if (fileSize > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El archivo no puede superar los 10 MB")),
      );
      return;
    }

    // VALIDACIÓN DE FORMATO CORREGIDA - Solo JPG/PNG para ambos
    if (mimeType != "image/jpeg" && mimeType != "image/png") {
      final String tipoArchivo = isFoto ? "foto" : "gráfico";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("La $tipoArchivo debe ser JPEG o PNG únicamente"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // VALIDACIÓN ADICIONAL: Verificar extensión del archivo
    final String extension = file.path.toLowerCase();
    if (!extension.endsWith('.jpg') &&
        !extension.endsWith('.jpeg') &&
        !extension.endsWith('.png')) {
      final String tipoArchivo = isFoto ? "foto" : "gráfico";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("La $tipoArchivo debe tener extensión .jpg, .jpeg o .png"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Log para verificar archivo seleccionado (remover en producción)
    print('Archivo seleccionado:');
    print('  Tipo: ${isFoto ? "Foto" : "Gráfico"}');
    print('  Ruta: ${file.path}');
    print('  MIME: $mimeType');
    print('  Tamaño: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

    setState(() {
      if (isFoto) {
        _foto = file;
      } else {
        _grafico = file;
      }
    });

    // Mostrar confirmación al usuario
    final String tipoArchivo = isFoto ? "foto" : "gráfico";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$tipoArchivo seleccionada correctamente"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }



  void _siguiente() async {
    if (_formKey.currentState!.validate()) {
      if (_foto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes subir al menos una foto de la fachada")),
        );
        return;
      }

      // CAMBIADO: Pasar archivos File directamente en lugar de subirlos aquí
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuildingRegistry2Screen(
            nombre: nombreController.text,
            direccion: direccionController.text,
            codigoPostal: codigoPostalController.text,
            // Pasar archivos File directamente
            fotoEdificio: _foto,
            graficoEdificio: _grafico,
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

  Widget _labeledTextFormField(String label, TextEditingController controller, String? Function(String?)? validator) {
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
          validator: validator,
        ),
      ],
    );
  }

  Widget _previewWidget(File? file, String label) {
    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: file != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                    Icons.error,
                    size: 60,
                    color: AppColors.error
                );
              },
            ),
          )
              : const Icon(Icons.image, size: 60, color: AppColors.gray500),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _pickFile(label == "Foto"),
          child: Text("Subir $label"),
        ),
        // Mostrar información del archivo seleccionado
        if (file != null) ...[
          const SizedBox(height: 4),
          Text(
            file.path.split('/').last,
            style: const TextStyle(fontSize: 10, color: AppColors.gray500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
                    // Sección de archivos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(width: 150, child: _previewWidget(_foto, "Foto")),
                        SizedBox(width: 150, child: _previewWidget(_grafico, "Gráfico")),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Campos de texto con labels arriba
                    _labeledTextFormField(
                      "Nombre del edificio",
                      nombreController,
                          (v) => v == null || v.isEmpty
                          ? "Campo obligatorio"
                          : v.length > 100
                          ? "Máximo 100 caracteres"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _labeledTextFormField(
                      "Dirección",
                      direccionController,
                          (v) => v != null && v.length > 255
                          ? "Máximo 255 caracteres"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _labeledTextFormField(
                      "Código Postal",
                      codigoPostalController,
                          (v) => v != null && v.length > 10
                          ? "Máximo 10 caracteres"
                          : null,
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _siguiente,
                      child: const Text(
                        "Siguiente",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/building');
                      },
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
      ),
    );
  }
}
