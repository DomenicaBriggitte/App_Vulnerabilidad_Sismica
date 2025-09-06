import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../../core/services/register_service.dart';
import '../../data/models/register_response.dart';
import '../widgets/passwordstreng.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedula = TextEditingController();
  final _nombre = TextEditingController(); // Changed from _username to match original
  final _rol = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _passwordHash = TextEditingController();
  final _confirmPasswordHash = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  String _completePhoneNumber = '';
  String? _usernameError;
  String? _emailError;

  @override
  void dispose() {
    _cedula.dispose();
    _nombre.dispose();
    _rol.dispose();
    _email.dispose();
    _telefono.dispose();
    _passwordHash.dispose();
    _confirmPasswordHash.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < 3) {
      setState(() {
        _usernameError = null;
      });
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
      _usernameError = null;
    });

    try {
      final isAvailable = await RegisterService.checkUsernameAvailability(username);
      if (mounted) {
        setState(() {
          _usernameError = isAvailable ? null : 'Este nombre de usuario ya está en uso';
          _isCheckingAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameError = null;
          _isCheckingAvailability = false;
        });
      }
    }
  }

  Future<void> _checkEmailAvailability(String email) async {
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _emailError = null;
      });
      return;
    }

    setState(() {
      _emailError = null;
    });

    try {
      final isAvailable = await RegisterService.checkEmailAvailability(email);
      if (mounted) {
        setState(() {
          _emailError = isAvailable ? null : 'Este correo electrónico ya está registrado';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailError = null;
        });
      }
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_usernameError != null || _emailError != null) {
      _showErrorMessage('Por favor corrija los errores antes de continuar');
      return;
    }

    if (_completePhoneNumber.isEmpty) {
      _showErrorMessage('Por favor ingrese un número de teléfono válido');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Debug information
    print('Datos a enviar:');
    print('Cédula: ${_cedula.text.trim()}');
    print('Nombre: ${_nombre.text.trim()}');
    print('Rol: ${_rol.text.trim()}');
    print('Email: ${_email.text.trim()}');
    print('Teléfono: $_completePhoneNumber');

    try {
      final registerResponse = await RegisterService.registerUser(
        cedula: _cedula.text.trim(),
        username: _nombre.text.trim(), // Using nombre as username
        role: _rol.text.trim(),
        email: _email.text.trim(),
        phone: _completePhoneNumber,
        password: _passwordHash.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (registerResponse.success) {
          _showSuccessMessage(registerResponse.message ?? '¡Registro exitoso!');
          _showSuccessDialog(registerResponse);
        } else {
          _handleRegistrationError(registerResponse);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Error inesperado: $e');
      }
    }
  }

  void _handleRegistrationError(RegisterResponse response) {
    String errorMessage = response.error ?? 'Error desconocido';

    if (response.isValidationError) {
      errorMessage = '📋 $errorMessage';
    } else if (response.isConflictError) {
      errorMessage = '⚠️ $errorMessage';
    } else if (response.isServerError) {
      errorMessage = '🔧 $errorMessage';
    } else if (response.isConnectionError) {
      errorMessage = '🌐 $errorMessage';
    }

    _showErrorMessage(errorMessage);
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessDialog(RegisterResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 400,
              minWidth: 280,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.celebration,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '¡Bienvenido a SismosApp!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Success message
                const Text(
                  'Su cuenta ha sido creada exitosamente.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // User data section
                if (response.hasUserData) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('👤', 'Usuario', response.username ?? ''),
                        const SizedBox(height: 8),
                        _buildInfoRow('📧', 'Email', response.email ?? ''),
                        const SizedBox(height: 8),
                        _buildInfoRow('🏷️', 'Rol', response.role ?? ''),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Bottom message
                const Text(
                  'Ya puede comenzar a usar todas las funciones de la aplicación.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
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
                        // Campo de cédula
                        TextFormField(
                          controller: _cedula,
                          decoration: const InputDecoration(
                            labelText: 'Cédula',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          enabled: !_isLoading,
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

                        // Campo de nombre completo con verificación
                        TextFormField(
                          controller: _nombre,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person),
                            suffixIcon: _isCheckingAvailability
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                                : _usernameError == null && _nombre.text.length >= 3
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                            errorText: _usernameError,
                          ),
                          enabled: !_isLoading,
                          onChanged: (value) {
                            if (value.length >= 3) {
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (_nombre.text == value) {
                                  _checkUsernameAvailability(value);
                                }
                              });
                            } else {
                              setState(() {
                                _usernameError = null;
                              });
                            }
                          },
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
                        // Campo de correo electrónico con verificación
                        TextFormField(
                          controller: _email,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.email),
                            suffixIcon: _emailError == null &&
                                RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email.text)
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                            errorText: _emailError,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          onChanged: (value) {
                            if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              Future.delayed(const Duration(milliseconds: 800), () {
                                if (_email.text == value) {
                                  _checkEmailAvailability(value);
                                }
                              });
                            } else {
                              setState(() {
                                _emailError = null;
                              });
                            }
                          },
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

                        // Campo de teléfono con país
                        IntlPhoneField(
                          controller: _telefono,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                          ),
                          initialCountryCode: 'EC',
                          enabled: !_isLoading,
                          onChanged: (phone) {
                            // Store complete number with country code in E.164 format
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
                            if (phoneNumber.length < 7) {
                              return 'Número de teléfono muy corto';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Campo de contraseña con indicador de fortaleza
                        TextFormField(
                          controller: _passwordHash,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: _passwordHash.text.isNotEmpty
                                ? Icon(
                              PasswordStrengthHelper.getPasswordStrengthIcon(_passwordHash.text),
                              color: PasswordStrengthHelper.getPasswordStrengthColor(_passwordHash.text),
                            )
                                : null,
                          ),
                          obscureText: true,
                          enabled: !_isLoading,
                          onChanged: (value) {
                            setState(() {}); // Update strength indicator
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese una contraseña';
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

                        // Password strength indicator
                        if (_passwordHash.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          PasswordStrengthWidget(
                            password: _passwordHash.text,
                            controller: _passwordHash,
                            labelText: 'Contraseña',
                            showStrengthIndicator: true,
                          ),
                          const SizedBox(height: 4),
                        ],

                        const SizedBox(height: 12),

                        // Campo de confirmar contraseña con widget personalizado
                        PasswordStrengthWidget(
                          password: _confirmPasswordHash.text,
                          controller: _confirmPasswordHash,
                          labelText: 'Confirmar contraseña',
                          prefixIcon: Icons.lock_outline,
                          enabled: !_isLoading,
                          matchPassword: _passwordHash.text, // Para mostrar el check verde
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
                        const SizedBox(height: 24),


                        // Botón de registro
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading || _isCheckingAvailability ? null : _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.gray300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Registrando...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            )
                                : const Text(
                              'Registrar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Link para ir al login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes una cuenta? ',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading ? null : () {
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                              child: Text(
                                'Inicia sesión',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
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