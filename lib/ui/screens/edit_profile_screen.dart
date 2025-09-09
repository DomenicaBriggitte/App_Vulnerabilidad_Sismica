import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();

  String? _originalNombre;
  String? _originalTelefono;
  String? _originalEmail;
  String? _originalCedula;
  String? _originalFoto;
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
      _originalNombre = widget.userData!['nombre']?.toString() ?? '';
      _originalTelefono = widget.userData!['telefono']?.toString() ?? '';
      _originalEmail = widget.userData!['email']?.toString() ?? '';
      _originalCedula = widget.userData!['cedula']?.toString() ?? '';
      _originalFoto = widget.userData!['foto_perfil_url']?.toString() ?? '';

      _nombreController.text = _originalNombre ?? '';
      _telefonoController.text = _originalTelefono ?? '';
      _emailController.text = _originalEmail ?? '';
      _cedulaController.text = _originalCedula ?? '';

      // Listeners para detectar cambios
      _nombreController.addListener(_checkForChanges);
      _telefonoController.addListener(_checkForChanges);
      _emailController.addListener(_checkForChanges);
      _cedulaController.addListener(_checkForChanges);
    }
  }

  void _checkForChanges() {
    final hasNameChange = _nombreController.text.trim() != (_originalNombre ?? '');
    final hasPhoneChange = _telefonoController.text.trim() != (_originalTelefono ?? '');
    final hasEmailChange = _emailController.text.trim() != (_originalEmail ?? '');
    final hasCedulaChange = _cedulaController.text.trim() != (_originalCedula ?? '');
    final hasImageChange = _selectedImage != null;

    setState(() {
      _hasChanges = hasNameChange || hasPhoneChange || hasEmailChange || hasCedulaChange || hasImageChange;
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
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
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

    final phone = value.trim();

    // Validar que solo contenga dígitos
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'El teléfono solo debe contener números';
    }

    // Validar que tenga exactamente 10 dígitos
    if (phone.length != 10) {
      return 'El teléfono debe tener exactamente 10 dígitos';
    }

    // Validar que empiece con 0 (formato ecuatoriano)
    if (!phone.startsWith('0')) {
      return 'El teléfono debe empezar con 0';
    }

    // Validar formatos válidos ecuatorianos:
    // Móviles: 09XXXXXXXX (Claro, Movistar, CNT)
    // Fijos: 0[2-7]XXXXXXX (según provincia)
    if (phone.startsWith('09')) {
      // Teléfono móvil - validar que el tercer dígito sea válido
      final thirdDigit = phone[2];
      if (!['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'].contains(thirdDigit)) {
        return 'Formato de móvil inválido';
      }
    } else {
      // Teléfono fijo - validar código de área
      final areaCode = phone[1];
      if (!['2', '3', '4', '5', '6', '7'].contains(areaCode)) {
        return 'Código de área inválido. Use 02-07 para fijos o 09 para móviles';
      }
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Formato de email inválido';
    }
    return null;
  }

  String? _validateCedula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Campo opcional
    }
    final cedulaRegex = RegExp(r'^\d{10}$');
    if (!cedulaRegex.hasMatch(value.trim())) {
      return 'La cédula debe tener 10 dígitos';
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

      debugPrint('Actualizando usuario $userId');

      // Usar el nuevo servicio
      final response = await UserService.updateUser(
        token: token,
        userId: userId,
        nombre: _nombreController.text.trim() != _originalNombre
            ? _nombreController.text.trim()
            : null,
        telefono: _telefonoController.text.trim() != _originalTelefono
            ? _telefonoController.text.trim()
            : null,
        email: _emailController.text.trim() != _originalEmail
            ? _emailController.text.trim()
            : null,
        cedula: _cedulaController.text.trim() != _originalCedula
            ? _cedulaController.text.trim()
            : null,
        imageFile: _selectedImage,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Regresar con indicador de éxito
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al actualizar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("Error al actualizar perfil: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _cedulaController.dispose();
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
              // Campo Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  hintText: 'Ingrese su nombre completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                maxLength: 100,
                validator: _validateNombre,
                style: const TextStyle(color: AppColors.text),
              ),

              const SizedBox(height: 16),
              // Campo Teléfono - ACTUALIZADO
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  hintText: '0987654321 o 0234567890',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  helperText: 'Móvil: 09XXXXXXXX, Fijo: 0[2-7]XXXXXXX',
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10, // Cambiado a 10
                validator: _validateTelefono,
                style: const TextStyle(color: AppColors.text),
              ),

              const SizedBox(height: 16),


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
                    'Guardar Cambios',
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