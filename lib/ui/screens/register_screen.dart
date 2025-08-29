import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_logo.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedula = TextEditingController();
  final _nombre = TextEditingController();
  final _rol = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _passwordHash = TextEditingController();
  final _confirmPasswordHash = TextEditingController();
  String _completePhoneNumber = '';

  @override
  void dispose() {
    _cedula.dispose();
    _nombre.dispose();
    _rol.dispose();
    _email.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _passwordHash.dispose();
    _confirmPasswordHash.dispose();
    super.dispose();
  }

  void _registerUser() {
    if (_formKey.currentState!.validate()) {
      // Datos a enviar al backend según el diccionario de datos:
      final userData = {
        'cedula': _cedula.text,
        'nombre': _nombre.text,
        'email': _email.text,
        'telefono': _completePhoneNumber.isNotEmpty
            ? _completePhoneNumber
            : _telefono.text,
        'direccion': _direccion.text,
        'password_hash':
            _passwordHash.text, // Este valor será hasheado en el backend
        'rol': _rol.text,
        'activo': true, // Por defecto activo
        'photo_perfil': null, // Se puede agregar posteriormente
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario registrado exitosamente (UI demo)'),
        ),
      );
      // Aquí se debe conectar la lógica de registro con el backend
      print('Datos a enviar: $userData');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SismosApp',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: AppLogo()),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Registro de usuario',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Complete los campos para crear su cuenta',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Campo de cédula. Enviar como 'cedula' al backend (API de registro)
                        TextFormField(
                          controller: _cedula,
                          decoration: const InputDecoration(
                            labelText: 'Cédula',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su cédula';
                            }
                            if (value.length != 10) {
                              return 'La cédula debe tener 10 dígitos';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'Solo se permiten números';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Campo de nombre completo. Enviar como 'nombre' al backend (API de registro)
                        TextFormField(
                          controller: _nombre,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su nombre completo';
                            }
                            if (!RegExp(
                              r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
                            ).hasMatch(value)) {
                              return 'Solo se permiten letras y espacios';
                            }
                            if (value.length > 100) {
                              return 'El nombre no puede exceder 100 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Campo de selección de rol. Enviar como 'rol' al backend (API de registro)
                        DropdownButtonFormField<String>(
                          value: _rol.text.isNotEmpty ? _rol.text : null,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text(
                                'Admin',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'inspector',
                              child: Text(
                                'Inspector',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ayudante',
                              child: Text(
                                'Ayudante',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _rol.text = value ?? '';
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Seleccione un rol';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Campo de correo electrónico. Enviar como 'email' al backend (API de registro)
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese un correo electrónico';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Ingrese un correo válido';
                            }
                            if (value.length > 150) {
                              return 'El correo no puede exceder 150 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Campo de teléfono con país. Enviar como 'telefono' al backend (API de registro)
                        IntlPhoneField(
                          controller: _telefono,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                          ),
                          initialCountryCode: 'EC',
                          onChanged: (phone) {
                            // Almacenar el número completo con país en formato E.164
                            _completePhoneNumber = phone.completeNumber;
                          },
                          validator: (value) {
                            final phoneNumber = value?.number ?? '';
                            if (phoneNumber.isEmpty) {
                              return 'Ingrese su número de teléfono';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
                              return 'Solo se permiten números';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Campo de dirección. Enviar como 'direccion' al backend (API de registro)
                        TextFormField(
                          controller: _direccion,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su dirección';
                            }
                            if (value.length > 255) {
                              return 'La dirección no puede exceder 255 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Campo de contraseña. Enviar como 'password_hash' al backend (API de registro)
                        TextFormField(
                          controller: _passwordHash,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese una contraseña';
                            }
                            // Debe tener al menos 8 caracteres, un símbolo y un carácter especial
                            if (value.length < 8) {
                              return 'Debe tener al menos 8 caracteres';
                            }
                            if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                              return 'Debe contener al menos un símbolo (!@#\$&*~)';
                            }
                            if (!RegExp(r'[A-Za-z0-9]').hasMatch(value)) {
                              return 'Debe contener letras y números';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Campo de confirmar contraseña. Solo para validación local, no se envía al backend
                        TextFormField(
                          controller: _confirmPasswordHash,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar contraseña',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirme su contraseña';
                            }
                            if (value != _passwordHash.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Botón para enviar datos al backend (API de registro)
                        ElevatedButton(
                          onPressed:
                              _registerUser, // Aquí se debe conectar la lógica de registro con el backend
                          child: const Text('Registrar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
