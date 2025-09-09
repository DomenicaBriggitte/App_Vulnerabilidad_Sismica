import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../../core/services/register_service.dart';
import '../../data/models/register_response.dart';
import '../widgets/passwordstreng.dart';
import '../widgets/success_registration_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Form and Controllers
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  bool _passwordTouched = false;
  bool _cedulaTouched = false;
  bool _nombreTouched = false;
  bool _emailTouched = false;
  bool _telefonoTouched = false;
  bool _confirmPasswordTouched = false;
  String _completePhoneNumber = '';
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String _selectedRole = 'inspector'; // Valor por defecto

  // Constants - Ajustados según el servidor
  static const int _cedulaLength = 10;
  static const int _minNameLength = 5;
  static const int _maxNameLength = 100;
  static const int _maxEmailLength = 150;
  static const int _minPasswordLength = 6;

  // Roles disponibles
  static const Map<String, String> _availableRoles = {
    'admin': 'Administrador',
    'inspector': 'Inspector',
    'ayudante': 'Ayudante',
  };

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validation Methods
  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < _minNameLength) {
      setState(() => _usernameError = null);
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
    if (!_isValidEmail(email)) {
      setState(() => _emailError = null);
      return;
    }

    setState(() => _emailError = null);

    try {
      final isAvailable = await RegisterService.checkEmailAvailability(email);
      if (mounted) {
        setState(() {
          _emailError = isAvailable ? null : 'Este correo electrónico ya está registrado';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _emailError = null);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Registration Logic
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasValidationErrors()) return;

    if (_completePhoneNumber.isEmpty) {
      _showErrorMessage('Por favor ingrese un número de teléfono válido');
      return;
    }

    setState(() => _isLoading = true);

    _logRegistrationData();

    try {
      final registerResponse = await RegisterService.registerUser(
        cedula: _cedulaController.text.trim(),
        username: _nombreController.text.trim(),
        role: _selectedRole,
        email: _emailController.text.trim(),
        phone: _completePhoneNumber,
        password: _passwordController.text,
        maxRetries: 2,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _handleRegistrationResponse(registerResponse);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Error inesperado: $e');
      }
    }
  }

  bool _hasValidationErrors() {
    if (_usernameError != null || _emailError != null || _passwordError != null) {
      _showErrorMessage('Por favor corrija los errores antes de continuar');
      return true;
    }
    return false;
  }

  void _logRegistrationData() {
    debugPrint('📝 Datos a enviar:');
    debugPrint('  - Cédula: ${_cedulaController.text.trim()}');
    debugPrint('  - Nombre: ${_nombreController.text.trim()}');
    debugPrint('  - Rol: $_selectedRole');
    debugPrint('  - Email: ${_emailController.text.trim()}');
    debugPrint('  - Teléfono: $_completePhoneNumber');
  }

  void _handleRegistrationResponse(RegisterResponse response) {
    debugPrint('📋 Respuesta del registro: ${response.toString()}');

    if (response.success) {
      _showSuccessMessage(response.message ?? 'Registro exitoso');

      if (response.isCompleteSuccess) {
        // Registro exitoso CON login automático
        _handleSuccessfulRegistrationWithLogin(response);
      } else {
        // Registro exitoso SIN login automático - usar el widget estándar
        _showSuccessDialog(response);
      }
    } else {
      _handleRegistrationError(response);
    }
  }

  Future<void> _handleSuccessfulRegistrationWithLogin(RegisterResponse response) async {
    try {
      // Guardar datos de sesión en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', response.token!);
      await prefs.setString('userId', response.userIdValue!.toString());
      await prefs.setString('userName', response.username ?? 'Usuario');
      await prefs.setString('userRole', response.role ?? 'user');

      debugPrint('✅ Datos guardados en SharedPreferences');
      debugPrint('  - Token: ${response.token!.substring(0, 10)}...');
      debugPrint('  - UserId: ${response.userIdValue}');
      debugPrint('  - UserName: ${response.username}');
      debugPrint('  - UserRole: ${response.role}');

      // SIMPLIFICADO: Usar siempre el SuccessRegistrationDialog que maneja la navegación
      _showSuccessDialog(response);

    } catch (e) {
      debugPrint('❌ Error guardando datos de sesión: $e');
      _showSuccessDialog(response); // Fallback al diálogo normal
    }
  }

  void _showSuccessDialog(RegisterResponse response) {
    // El SuccessRegistrationDialog ahora maneja la navegación por roles automáticamente
    SuccessRegistrationDialog.show(
      context: context,
      response: response,
      // No necesitamos onContinue personalizado, el widget maneja todo
    );
  }

  void _handleRegistrationError(RegisterResponse response) {
    final errorMessage = _getFormattedErrorMessage(response);
    _showErrorMessage(errorMessage);
  }

  String _getFormattedErrorMessage(RegisterResponse response) {
    String errorMessage = response.error ?? 'Error desconocido';

    if (response.isValidationError) {
      return _getValidationErrorMessage(errorMessage);
    } else if (response.isConflictError) {
      return 'Conflicto: $errorMessage';
    } else if (response.isServerError) {
      return 'Error del servidor: $errorMessage';
    } else if (response.isConnectionError) {
      return 'Error de conexión: $errorMessage';
    }

    return errorMessage;
  }

  String _getValidationErrorMessage(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('email') || lowerError.contains('correo')) {
      return 'Error en el correo: Verifique que sea válido y no esté en uso';
    } else if (lowerError.contains('cedula')) {
      return 'Error en la cédula: Debe tener 10 dígitos y ser válida';
    } else if (lowerError.contains('nombre') || lowerError.contains('username')) {
      return 'Error en el nombre: Debe tener al menos 5 caracteres y no estar en uso';
    } else if (lowerError.contains('telefono') || lowerError.contains('phone')) {
      return 'Error en el teléfono: Ingrese un número válido';
    } else if (lowerError.contains('password') || lowerError.contains('contraseña')) {
      return 'Error en la contraseña: Debe cumplir con los requisitos de seguridad';
    }

    return 'Datos incorrectos: $errorMessage';
  }

  // UI Helper Methods
  void _showSuccessMessage(String message) {
    _showSnackBar(
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
      duration: 3,
    );
  }

  void _showErrorMessage(String message) {
    _showSnackBar(
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red,
      duration: 4,
    );
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required int duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: duration),
      ),
    );
  }

  // Form Field Builders
  Widget _buildCedulaField() {
    return TextFormField(
      controller: _cedulaController,
      decoration: InputDecoration(
        labelText: 'Cédula',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.credit_card),
        helperText: _cedulaTouched ? 'Ingrese su número de cédula de 10 dígitos' : null,
      ),
      keyboardType: TextInputType.number,
      maxLength: _cedulaLength,
      enabled: !_isLoading,
      onTap: () => setState(() => _cedulaTouched = true),
      validator: _validateCedula,
    );
  }

  Widget _buildNombreField() {
    return TextFormField(
      controller: _nombreController,
      decoration: InputDecoration(
        labelText: 'Nombre completo',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.person),
        helperText: _nombreTouched ? 'Ingrese su nombre completo (mínimo $_minNameLength caracteres)' : null,
        suffixIcon: _buildNombreSuffixIcon(),
        errorText: _usernameError,
      ),
      enabled: !_isLoading,
      onTap: () => setState(() => _nombreTouched = true),
      onChanged: _onNombreChanged,
      validator: _validateNombre,
    );
  }

  Widget? _buildNombreSuffixIcon() {
    if (_isCheckingAvailability) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_usernameError == null && _nombreController.text.length >= _minNameLength) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    return null;
  }

  void _onNombreChanged(String value) {
    if (value.length >= _minNameLength) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_nombreController.text == value && mounted) {
          _checkUsernameAvailability(value);
        }
      });
    } else {
      setState(() => _usernameError = null);
    }
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: const InputDecoration(
        labelText: 'Rol',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.work),
      ),
      items: _availableRoles.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(
            entry.value,
            style: const TextStyle(color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: _isLoading ? null : (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedRole = newValue;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione un rol';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.email),
        helperText: _emailTouched ? 'Ingrese un correo electrónico válido' : null,
        suffixIcon: _buildEmailSuffixIcon(),
        errorText: _emailError,
      ),
      keyboardType: TextInputType.emailAddress,
      enabled: !_isLoading,
      onTap: () => setState(() => _emailTouched = true),
      onChanged: _onEmailChanged,
      validator: _validateEmail,
    );
  }

  Widget? _buildEmailSuffixIcon() {
    if (_emailError == null && _isValidEmail(_emailController.text)) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    return null;
  }

  void _onEmailChanged(String value) {
    if (_isValidEmail(value)) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_emailController.text == value && mounted) {
          _checkEmailAvailability(value);
        }
      });
    } else {
      setState(() => _emailError = null);
    }
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      controller: _telefonoController,
      decoration: InputDecoration(
        labelText: 'Teléfono',
        border: const OutlineInputBorder(),
        helperText: _telefonoTouched ? 'Ingrese su número de teléfono' : null,
      ),
      initialCountryCode: 'EC',
      enabled: !_isLoading,
      onTap: () => setState(() => _telefonoTouched = true),
      onChanged: (phone) => _completePhoneNumber = phone.completeNumber,
      validator: _validatePhone,
    );
  }

  Widget _buildPasswordField() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            helperText: _passwordTouched ? 'Mínimo $_minPasswordLength caracteres, incluya mayúsculas y números' : null,
            suffixIcon: _buildPasswordSuffixIcon(),
            errorText: _passwordError,
          ),
          obscureText: true,
          enabled: !_isLoading,
          onTap: () => setState(() => _passwordTouched = true),
          onChanged: (value) {
            setState(() {
              if (_passwordError != null) {
                _passwordError = null;
              }
            });
          },
          validator: _validatePassword,
        ),
        if (_passwordController.text.isNotEmpty && _passwordTouched) ...[
          const SizedBox(height: 8),
          PasswordStrengthWidget(
            password: _passwordController.text,
            controller: _passwordController,
            labelText: 'Contraseña',
            showStrengthIndicator: true,
            onTap: () {},
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget? _buildPasswordSuffixIcon() {
    if (_passwordController.text.isNotEmpty) {
      final password = _passwordController.text;
      int strength = 0;

      if (password.length >= 6) strength++;
      if (password.length >= 8) strength++;
      if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
      if (RegExp(r'[a-z]').hasMatch(password)) strength++;
      if (RegExp(r'[0-9]').hasMatch(password)) strength++;
      if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

      IconData icon = Icons.security;
      Color color = Colors.red;

      if (strength >= 5) {
        icon = Icons.security;
        color = Colors.green;
      } else if (strength >= 4) {
        icon = Icons.security;
        color = Colors.lightGreen;
      } else if (strength >= 3) {
        icon = Icons.security;
        color = Colors.orange;
      }

      return Icon(icon, color: color);
    }
    return null;
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: InputDecoration(
        labelText: 'Confirmar contraseña',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        helperText: _confirmPasswordTouched ? 'Confirme su contraseña' : null,
        suffixIcon: _confirmPasswordController.text.isNotEmpty &&
            _confirmPasswordController.text == _passwordController.text
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
      obscureText: true,
      enabled: !_isLoading,
      onTap: () => setState(() => _confirmPasswordTouched = true),
      onChanged: (value) => setState(() {}), // Para actualizar el suffixIcon
      validator: _validateConfirmPassword,
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading || _isCheckingAvailability ? null : _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.gray300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading ? _buildLoadingButton() : _buildRegularButton(),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return const Row(
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
        Text('Registrando...', style: TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildRegularButton() {
    return const Text(
      'Registrar',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLoginLink(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta? ',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.gray500),
        ),
        GestureDetector(
          onTap: _isLoading ? null : () => Navigator.of(context).pushReplacementNamed('/login'),
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
    );
  }

  // Validation Methods
  String? _validateCedula(String? value) {
    if (value == null || value.isEmpty) {
      return 'La cédula es requerida';
    }
    if (value.length < 6) {
      return 'La cédula debe tener al menos 6 caracteres';
    }
    if (value.length != _cedulaLength) {
      return 'La cédula debe tener exactamente $_cedulaLength dígitos';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Solo se permiten números';
    }
    return null;
  }

  String? _validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.length < _minNameLength) {
      return 'El nombre debe tener al menos $_minNameLength caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'Solo se permiten letras y espacios';
    }
    if (value.length > _maxNameLength) {
      return 'El nombre no puede exceder $_maxNameLength caracteres';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    }
    if (!_isValidEmail(value)) {
      return 'El correo no es válido';
    }
    if (value.length > _maxEmailLength) {
      return 'El correo no puede exceder $_maxEmailLength caracteres';
    }
    return null;
  }

  String? _validatePhone(phone) {
    final phoneNumber = phone?.number ?? '';
    if (phoneNumber.isEmpty) {
      return 'El número de teléfono es requerido';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
      return 'Solo se permiten números';
    }
    if (phoneNumber.length > 10) {
      return 'El número de teléfono no debe superar 10 dígitos';
    }
    if (phoneNumber.length < 7) {
      return 'Número de teléfono muy corto';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < _minPasswordLength) {
      return 'La contraseña debe tener al menos $_minPasswordLength caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'La contraseña debe tener al menos una letra mayúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe tener al menos un número';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme su contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
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
                    style: textTheme.titleMedium?.copyWith(color: AppColors.text),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: AppLogo()),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Registro de usuario',
                      style: textTheme.titleLarge?.copyWith(color: AppColors.text),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Complete los campos para crear su cuenta',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.gray500),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildCedulaField(),
                        const SizedBox(height: 12),
                        _buildNombreField(),
                        const SizedBox(height: 12),
                        _buildEmailField(),
                        const SizedBox(height: 12),
                        _buildPhoneField(),
                        const SizedBox(height: 12),
                        _buildPasswordField(),
                        const SizedBox(height: 12),
                        _buildConfirmPasswordField(),
                        const SizedBox(height: 24),
                        _buildRegisterButton(),
                        const SizedBox(height: 16),
                        _buildLoginLink(textTheme),
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