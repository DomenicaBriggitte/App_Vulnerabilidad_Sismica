import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/fields.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Alineado al diccionario (Tokens de recuperación/Usuarios)
  final TextEditingController email = TextEditingController();
  String? telefono; //  (VARCHAR(20))

  final _formKey = GlobalKey<FormState>();

  bool _isValidPhone(String? p) {
    if (p == null || p.isEmpty) return false;
    // E.164: + y de 8 a 15 dígitos aprox. (el campo permite hasta 20)
    final exp = RegExp(r'^\+[1-9]\d{7,19}$');
    return exp.hasMatch(p) && p.length <= 20;
  }

  void _send() {
    final emailOk = _formKey.currentState!.validate();
    final phoneOk = telefono != null && _isValidPhone(telefono);

    if (!emailOk && !phoneOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un correo válido o teléfono')),
      );
      return;
    }

    final msg = (email.text.trim().isNotEmpty)
        ? 'Enlace enviado a ${email.text.trim()}'
        : 'Código enviado a $telefono';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    // Aquí luego crearías un registro en tokens de recuperación en backend
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
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
                      'Restablecer contraseña usando correo o número telefónico',
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
                        AppEmailField(controller: email),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'o',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Teléfono E.164 (VARCHAR 20)
                        IntlPhoneField(
                          decoration: const InputDecoration(
                            hintText: 'Teléfono',
                          ),
                          initialCountryCode: 'EC',
                          disableLengthCheck:
                              true, // validamos nosotros según E.164 + límite 20
                          onChanged: (phone) => telefono = phone.completeNumber,
                          onCountryChanged: (c) {
                            // Reinicia valor si cambia país para no dejar un formato inválido
                            telefono = null;
                          },
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _send,
                                child: const Text('Enviar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                            ),
                          ],
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
