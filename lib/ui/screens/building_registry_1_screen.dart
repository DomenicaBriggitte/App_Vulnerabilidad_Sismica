import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ui/screens/building_registry_2_screen.dart';
import '../../ui/screens/home_page.dart';
import '../../ui/screens/profile_page.dart';

class RegistroEdificio1Page extends StatefulWidget {
  const RegistroEdificio1Page({super.key});

  @override
  State<RegistroEdificio1Page> createState() => _RegistroEdificio1PageState();
}

class _RegistroEdificio1PageState extends State<RegistroEdificio1Page> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final direccionController = TextEditingController();
  final codigoPostalController = TextEditingController();
  final usoController = TextEditingController();
  final latitudController = TextEditingController();
  final longitudController = TextEditingController();
  final inspectorController = TextEditingController();
  final fechaHoraController = TextEditingController();
  File? _foto;
  File? _grafico;
  final supabase = Supabase.instance.client;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      ).then((_) => setState(() => _selectedIndex = 0));
    }
  }

  Future<void> _pickFile(bool isFoto) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al subir archivo: $e")));
      return null;
    }
  }

  void _siguiente() async {
    if (_formKey.currentState!.validate()) {
      if (_foto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes subir al menos una foto de la fachada"),
          ),
        );
        return;
      }
      if (fechaHoraController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes seleccionar la fecha y hora")),
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
          builder: (context) => RegistroEdificio2Page(
            nombre: nombreController.text,
            direccion: direccionController.text,
            codigoPostal: codigoPostalController.text,
            uso: usoController.text,
            latitud: latitudController.text,
            longitud: longitudController.text,
            inspector: inspectorController.text,
            fechaHora: fechaHoraController.text,
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
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3D3D3), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3D3D3), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0095EB), width: 2),
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
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: file != null
              ? isPdf
                    ? const Icon(
                        Icons.picture_as_pdf,
                        size: 60,
                        color: Colors.red,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(file, fit: BoxFit.cover),
                      )
              : const Icon(Icons.image, size: 60, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: label == "Foto"
                ? const Color(0xFF19DBE6)
                : const Color(0xFF199BE6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _pickFile(label == "Foto"),
          child: Text("Subir $label"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF195AE6),
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
                  _previewWidget(_foto, "Foto"),
                  _previewWidget(_grafico, "Gráfico"),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: usoController,
                decoration: _inputDecoration("Uso del edificio"),
                validator: (v) =>
                    v != null && v.length > 50 ? "Máximo 50 caracteres" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: latitudController,
                decoration: _inputDecoration("Latitud"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final regex = RegExp(r'^-?\d{1,3}\.\d{1,6}$');
                  return !regex.hasMatch(v) ? "Formato inválido (9,6)" : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: longitudController,
                decoration: _inputDecoration("Longitud"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final regex = RegExp(r'^-?\d{1,3}\.\d{1,6}$');
                  return !regex.hasMatch(v) ? "Formato inválido (9,6)" : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: inspectorController,
                decoration: _inputDecoration("Inspector"),
                validator: (v) => v != null && v.length > 100
                    ? "Máximo 100 caracteres"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fechaHoraController,
                decoration: _inputDecoration("Fecha y hora"),
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        fechaHoraController.text =
                            "${pickedDate.toLocal().toString().split(' ')[0]} ${time.format(context)}";
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19E6AC),
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
      ),
    );
  }
}
