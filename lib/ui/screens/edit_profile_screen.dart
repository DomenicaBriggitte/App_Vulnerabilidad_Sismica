import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final String? userId;
  final String? token;
  final Map<String, dynamic>? userData;

  const EditProfileScreen({
    super.key,
    this.userId,
    this.token,
    this.userData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  String? _originalNombre;
  String? _originalTelefono;
  String? _originalFoto;
  String? _newFotoUrl;
  File? _selectedImage;
  bool _loading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.userData != null) {
      _originalNombre = widget.userData!['nombre']?.toString() ??
          widget.userData!['name']?.toString() ?? '';
      _originalTelefono = widget.userData!['telefono']?.toString() ??
          widget.userData!['phone']?.toString() ?? '';
      _originalFoto = widget.userData!['foto']?.toString() ?? '';

      _nombreController.text = _originalNombre ?? '';
      _telefonoController.text = _originalTelefono ?? '';

      // Listeners para detectar cambios
      _nombreController.addListener(_checkForChanges);
      _telefonoController.addListener(_checkForChanges);
    }
  }

  void _checkForChanges() {
    final hasNameChange = _nombreController.text.trim() != (_originalNombre ?? '');
    final hasPhoneChange = _telefonoController.text.trim() != (_originalTelefono ?? '');
    final hasImageChange = _selectedImage != null || _newFotoUrl != _originalFoto;

    setState(() {
      _hasChanges = hasNameChange || hasPhoneChange || hasImageChange;
    });
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        _checkForChanges();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value.trim())) {
      return 'Solo se permiten letras y espacios';
    }
    if (value.trim().length > 100) {
      return 'El nombre no debe exceder 100 caracteres';
    }
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Campo opcional
    }

    // Validación formato E.164 para Ecuador (+593XXXXXXXXX)
    final phoneRegex = RegExp(r'^\+593[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Formato inválido. Use +593XXXXXXXXX';
    }

    if (value.trim().length > 20) {
      return 'El teléfono no debe exceder 20 caracteres';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) return;

    setState(() => _loading = true);

    try {
      String? userId = widget.userId;
      String? token = widget.token;

      if (userId == null || token == null) {
        throw Exception('Datos de sesión no válidos');
      }

      // Preparar los datos a enviar (solo los campos modificados)
      Map<String, dynamic> updateData = {};

      if (_nombreController.text.trim() != (_originalNombre ?? '')) {
        updateData['nombre'] = _nombreController.text.trim();
      }

      if (_telefonoController.text.trim() != (_originalTelefono ?? '')) {
        updateData['telefono'] = _telefonoController.text.trim();
      }

      // TODO: Implementar subida de imagen si es necesario
      if (_selectedImage != null) {
        // Aquí deberías implementar la lógica para subir la imagen
        // Por ejemplo, usando multipart/form-data o un servicio de storage
        // updateData['foto'] = urlDeImagenSubida;

        // Por ahora, mostramos un mensaje informativo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidad de cambio de imagen pendiente de implementar'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      debugPrint('🔄 Actualizando usuario $userId con datos: $updateData');

      final url = 'http://192.168.100.4:3000/usuarios/$userId';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(updateData),
      );

      debugPrint('📊 Respuesta del servidor:');
      debugPrint('  - Status: ${response.statusCode}');
      debugPrint('  - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Regresar a la pantalla anterior
        Navigator.of(context).pop(true); // true indica que hubo cambios

      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión expirada. Por favor, inicie sesión nuevamente')),
        );
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no encontrado')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Error desconocido';

        if (errorData['error'] != null) {
          if (errorData['error'] is Map && errorData['error']['message'] != null) {
            errorMessage = errorData['error']['message'];
          } else if (errorData['error'] is String) {
            errorMessage = errorData['error'];
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
      debugPrint("❌ Error al actualizar perfil: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen de perfil con botón flotante
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (_originalFoto != null && _originalFoto!.isNotEmpty
                        ? NetworkImage(_originalFoto!)
                        : const AssetImage("assets/images/avatar_placeholder.png")),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _selectImage,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Campo Nombre de usuario
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  hintText: 'Ingrese su nombre de usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                maxLength: 100,
                validator: _validateNombre,
                style: const TextStyle(color: AppColors.text),
              ),

              const SizedBox(height: 16),

              // Campo Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: '+593XXXXXXXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 20,
                validator: _validateTelefono,
                style: const TextStyle(color: AppColors.text),
              ),

              const SizedBox(height: 32),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_hasChanges && !_loading) ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasChanges ? AppColors.primary : AppColors.gray300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'Guardar',
                    style: TextStyle(
                      color: _hasChanges ? Colors.white : AppColors.gray500,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información adicional
              if (!_hasChanges)
                const Text(
                  'Modifica algún campo para habilitar el botón Guardar',
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}