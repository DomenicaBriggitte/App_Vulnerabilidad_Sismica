import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'building_registry_2_screen.dart';
import 'home_page.dart';
import 'profile_page.dart';

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

  final supabase = Supabase.instance.client;
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
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileSize = await file.length();
    final mimeType = lookupMimeType(file.path);

    if (fileSize > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El archivo no puede superar los 10 MB")),
      );
      return;
    }

    if (isFoto) {
      if (mimeType != "image/jpeg" && mimeType != "image/png") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("La foto debe ser JPEG o PNG")),
        );
        return;
      }
    } else {
      if (!(mimeType == "image/jpeg" ||
          mimeType == "image/png" ||
          mimeType == "application/pdf")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("El gráfico debe ser JPEG, PNG o PDF")),
        );
        return;
      }
    }

    setState(() {
      if (isFoto) {
        _foto = file;
      } else {
        _grafico = file;
      }
    });
  }

  Future<String?> _uploadFile(File file, String name) async {
    final path = 'edificios/$name';
    try {
      await supabase.storage.from('edificios').upload(path, file);
      return supabase.storage.from('edificios').getPublicUrl(path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir archivo: $e")),
      );
      return null;
    }
  }

  void _siguiente() async {
    if (_formKey.currentState!.validate()) {
      if (_foto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes subir al menos una foto de la fachada")),
        );
        return;
      }

      String? fotoUrl;
      String? graficoUrl;

      if (_foto != null) {
        fotoUrl = await _uploadFile(
          _foto!,
          'foto_${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }
      if (_grafico != null) {
        graficoUrl = await _uploadFile(
          _grafico!,
          'grafico_${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuildingRegistry2Screen(
            nombre: nombreController.text,
            direccion: direccionController.text,
            codigoPostal: codigoPostalController.text,
            fotoUrl: fotoUrl,
            graficoUrl: graficoUrl,
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

  Widget _previewWidget(File? file, String label) {
    bool isPdf = file != null && file.path.toLowerCase().endsWith(".pdf");
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
              ? isPdf
              ? const Icon(Icons.picture_as_pdf, size: 60, color: AppColors.error)
              : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file, fit: BoxFit.cover),
          )
              : const Icon(Icons.image, size: 60, color: AppColors.gray500),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () => _pickFile(label == "Foto"),
          child: Text("Subir $label"),
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
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: 150, child: _previewWidget(_foto, "Foto")),
                  SizedBox(width: 150, child: _previewWidget(_grafico, "Gráfico")),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: nombreController,
                decoration: _inputDecoration("Nombre del edificio"),
                validator: (v) => v == null || v.isEmpty
                    ? "Campo obligatorio"
                    : v.length > 100
                    ? "Máximo 100 caracteres"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: direccionController,
                decoration: _inputDecoration("Dirección"),
                validator: (v) => v != null && v.length > 255
                    ? "Máximo 255 caracteres"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codigoPostalController,
                decoration: _inputDecoration("Código Postal"),
                validator: (v) =>
                v != null && v.length > 10 ? "Máximo 10 caracteres" : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/building');
                      },
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _siguiente,
                      child: const Text("Siguiente"),
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
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
      ),
    );
  }
}
