import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/fields.dart';

class RecoveryPasswordScreen extends StatefulWidget {
  const RecoveryPasswordScreen({super.key});
  @override
  State<RecoveryPasswordScreen> createState() => _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends State<RecoveryPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordHash = TextEditingController();
  final _confirmPasswordHash = TextEditingController();

  @override
  void dispose() {
    _passwordHash.dispose();
    _confirmPasswordHash.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña restablecida exitosamente.')),
      );
      // Aquí puedes agregar la lógica para enviar el password_hash al backend (API de recuperación)
      // Los datos a enviar serían:
      // {
      //   "password_hash": _passwordHash.text, // Este valor será hasheado en el backend
      // }
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
                      'Recuperar contraseña',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Ingrese su nueva contraseña y confírmela',
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
                        // Campo de nueva contraseña. Enviar como 'password_hash' al backend (API de recuperación)
                        TextFormField(
                          controller: _passwordHash,
                          decoration: const InputDecoration(
                            labelText: 'Nueva contraseña',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese la nueva contraseña';
                            }
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
                        // Campo de confirmar nueva contraseña. Solo para validación local, no se envía al backend
                        TextFormField(
                          controller: _confirmPasswordHash,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar nueva contraseña',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirme la nueva contraseña';
                            }
                            if (value != _passwordHash.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Botón para enviar la nueva password_hash al backend (API de recuperación)
                        ElevatedButton(
                          onPressed:
                              _resetPassword, // Aquí se debe conectar la lógica con el backend
                          child: const Text('Restablecer contraseña'),
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
