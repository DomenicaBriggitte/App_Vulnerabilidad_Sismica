import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/home_services.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/connection_test_android.dart';
import '../widgets/fields.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _loginBackend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      print('🔐 Iniciando login con AuthService...');

      // Usar AuthService con retry automático
      final authResponse = await AuthService.login(
        email: email.text.trim(),
        password: password.text.trim(),
        maxRetries: 2,
      );

      print('📋 Respuesta de AuthService: ${authResponse.toDebugMap()}');

      if (authResponse.success) {
        // ✅ LOGIN EXITOSO - Obtener datos completos del usuario
        final token = authResponse.token!;
        final userId = authResponse.userId!.toString();

        print('🔍 Obteniendo perfil completo del usuario...');

        // Obtener datos completos del usuario desde el servidor
        final profileResponse = await HomeService.getUserProfile(
          token: token,
          userId: userId,
        );

        String userName = 'Usuario';
        String userRole = 'user';

        if (profileResponse.success && profileResponse.data != null) {
          userName = profileResponse.data!.userInfo.nombre.isNotEmpty
              ? profileResponse.data!.userInfo.nombre
              : authResponse.userNameValue;
          userRole = profileResponse.data!.userInfo.rol.toLowerCase();
        } else {
          // Fallback a datos del AuthResponse
          userName = authResponse.userNameValue;
          print('⚠️ No se pudo obtener perfil completo, usando datos básicos');
        }

        print('👤 Datos del usuario obtenidos:');
        print('  - userName: $userName');
        print('  - userRole: $userRole');
        print('  - userId: $userId');

        // Guardar en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', token);
        await prefs.setString('userId', userId);
        await prefs.setString('userName', userName);
        await prefs.setString('userRole', userRole);

        // Verificar que se guardaron correctamente
        final savedToken = prefs.getString('accessToken');
        final savedUserId = prefs.getString('userId');
        final savedUserName = prefs.getString('userName');
        final savedUserRole = prefs.getString('userRole');

        print('✅ Datos guardados en SharedPreferences:');
        print('  - accessToken: ${savedToken?.substring(0, 10)}...');
        print('  - userId: $savedUserId');
        print('  - userName: $savedUserName');
        print('  - userRole: $savedUserRole');

        if (mounted) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Bienvenido, $userName!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // 🎯 REDIRECCIÓN SEGÚN EL ROL
          print('🎯 Redirigiendo según el rol: $userRole');

          if (userRole == 'admin') {
            print('🔧 Navegando a HomeAdminScreen...');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/homeAdmin',
                  (route) => false,
            );
          } else {
            print('👥 Navegando a HomePage...');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
                  (route) => false,
            );
          }
        }
      } else {
        // ❌ LOGIN FALLÓ
        print('❌ Login falló: ${authResponse.error}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authResponse.error ?? 'Error en el login'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Error inesperado durante login: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar con el servidor: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                  const ConnectionTestAndroid(),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Iniciar sesión',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Ingrese su correo y su contraseña para iniciar sesión',
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
                        AppPasswordField(controller: password),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot');
                            },
                            child: const Text('¿Olvidó su contraseña?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _loginBackend,
                            child: _loading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Iniciar sesión'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Aún no tienes una cuenta? ',
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color.fromARGB(255, 94, 94, 94),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Text(
                                'Registrarse',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color.fromARGB(255, 27, 27, 27),
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