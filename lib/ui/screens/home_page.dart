import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/home_services.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/home_response.dart';
import 'buildings_screen.dart';
import 'assessed_buildings_screen.dart';
import 'profile_admin_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables
  String _userName = 'Usuario';
  String? _userId;
  String? _token;
  String? _userRole;
  bool _loading = true;
  String? _errorMessage;
  HomeStatistics? _statistics;
  UserInfo? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 🔥 CRÍTICO: Leer TODOS los datos guardados
      setState(() {
        _userName = prefs.getString('userName') ?? 'Usuario';
        _userId = prefs.getString('userId');
        _token = prefs.getString('accessToken');
        _userRole = prefs.getString('userRole') ?? 'user';
        _errorMessage = null;
      });

      // DETECTAR ORIGEN DEL USUARIO - MEJORADO
      final isFromRegistration = prefs.getBool('isFromRegistration') ?? false; // Nuevo flag
      final isFirstLogin = prefs.getBool('isFirstLogin') ?? false;
      final registrationSource = prefs.getString('registrationSource');

      debugPrint('HOME - Análisis de origen del usuario:');
      debugPrint('  - userName: $_userName');
      debugPrint('  - userId: $_userId');
      debugPrint('  - userRole: $_userRole');
      debugPrint('  - isFromRegistration: $isFromRegistration'); // Nuevo
      debugPrint('  - isFirstLogin: $isFirstLogin');
      debugPrint('  - registrationSource: $registrationSource');
      debugPrint('  - token presente: ${_token != null}');

      // Validaciones básicas
      if (_token == null || !AuthService.isLoggedIn()) {
        _handleInvalidSession('Token no válido o sesión expirada');
        return;
      }

      if (_userId == null) {
        _handleInvalidSession('ID de usuario no encontrado');
        return;
      }

      // FLUJO MEJORADO SEGÚN EL ORIGEN
      if (isFromRegistration) {
        debugPrint('🆕 DETECTADO: Usuario viene de REGISTRO RECIENTE');
        await _loadUserDataFromRegistrationWithFallback();
        // Limpiar flags después del primer uso
        await prefs.setBool('isFromRegistration', false);
        await prefs.setBool('isFirstLogin', false);
      } else if (isFirstLogin) {
        debugPrint('🔄 DETECTADO: Primer login después de registro');
        await _loadUserDataFromServerWithRegistrationFallback();
        await prefs.setBool('isFirstLogin', false);
      } else {
        debugPrint('👤 FLUJO NORMAL: Usuario con login estándar');
        await _loadUserDataFromServer();
      }

    } catch (e) {
      debugPrint('Error en _loadUserData: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Error cargando datos locales: $e';
      });
    }
  }

// NUEVO MÉTODO: Específico para usuarios recién registrados
  Future<void> _loadUserDataFromRegistrationWithFallback() async {
    try {
      debugPrint('REGISTRO RECIENTE - Cargando datos del usuario recién registrado...');

      final prefs = await SharedPreferences.getInstance();

      // PRIORIZAR DATOS DEL REGISTRO (que deberían estar frescos)
      final registrationEmail = prefs.getString('userEmail') ?? '';
      final registrationPhone = prefs.getString('userPhone') ?? '';
      final registrationCedula = prefs.getString('userCedula') ?? '';
      final registrationTime = prefs.getString('registrationTime') ?? '';

      debugPrint('REGISTRO RECIENTE - Datos disponibles del registro:');
      debugPrint('  - Email: $registrationEmail');
      debugPrint('  - Teléfono: $registrationPhone');
      debugPrint('  - Cédula: $registrationCedula');
      debugPrint('  - Tiempo de registro: $registrationTime');

      // INTENTAR PRIMERO EL SERVIDOR (pero no es crítico si falla)
      bool serverDataLoaded = false;
      try {
        final response = await HomeService.getUserDataWithStats(
          token: _token!,
          userId: _userId!,
          maxRetries: 1, // Solo 1 intento para no retrasar
          timeout: const Duration(seconds: 8),
        );

        if (response.success && response.data != null) {
          debugPrint('REGISTRO RECIENTE - Datos del servidor obtenidos exitosamente');
          final userData = response.data!;

          setState(() {
            if (userData.userInfo.nombre.isNotEmpty) {
              _userName = userData.userInfo.nombre;
            }
            _userInfo = userData.userInfo;
            _statistics = userData.statistics;
            _loading = false;
            _errorMessage = null;
          });

          await _updateSharedPreferences(userData.userInfo);
          serverDataLoaded = true;
        }
      } catch (e) {
        debugPrint('REGISTRO RECIENTE - Servidor no disponible: $e');
      }

      // SI EL SERVIDOR NO RESPONDIÓ, USAR DATOS DEL REGISTRO
      if (!serverDataLoaded) {
        debugPrint('REGISTRO RECIENTE - Usando datos locales del registro');

        // CREAR UserInfo CON DATOS COMPLETOS DEL REGISTRO
        final localUserInfo = UserInfo(
          idUsuario: int.tryParse(_userId ?? '0') ?? 0,
          nombre: _userName,
          email: registrationEmail,
          rol: _userRole ?? 'user',
        );

        // ESTADÍSTICAS VACÍAS (normal para usuario recién registrado)
        final emptyStatistics = HomeStatistics(
          totalEdificios: 0,
          edificiosEvaluados: 0,
          edificiosPendientes: 0,
          inspeccionesRealizadas: 0,
        );

        setState(() {
          _userInfo = localUserInfo;
          _statistics = emptyStatistics;
          _loading = false;
          _errorMessage = null;
        });

        debugPrint('REGISTRO RECIENTE - Datos locales aplicados exitosamente');

        // MENSAJE ESPECIAL PARA USUARIO RECIÉN REGISTRADO
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('¡Bienvenido $_userName! Registro completado exitosamente.'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('REGISTRO RECIENTE - Error: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Error configurando datos del usuario: $e';
      });
    }
  }


  Future<void> _loadUserDataFromServer() async {
    if (_token == null || _userId == null) {
      _handleInvalidSession('Faltan credenciales de autenticación');
      return;
    }

    try {
      debugPrint('Cargando datos del servidor...');

      // Usar HomeService para obtener datos completos del usuario
      final response = await HomeService.getUserDataWithStats(
        token: _token!,
        userId: _userId!,
        maxRetries: 2,
        timeout: const Duration(seconds: 10),
      );

      debugPrint('Respuesta del servidor: ${response.success}');
      debugPrint('Datos recibidos: ${response.data != null}');

      if (response.success && response.data != null) {
        final userData = response.data!;

        setState(() {
          // Actualizar información del usuario si viene del servidor
          if (userData.userInfo.nombre.isNotEmpty) {
            _userName = userData.userInfo.nombre;
          }

          _userInfo = userData.userInfo;
          _statistics = userData.statistics;
          _loading = false;
          _errorMessage = null;
        });

        // Actualizar SharedPreferences con los nuevos datos
        await _updateSharedPreferences(userData.userInfo);

        debugPrint('Datos cargados exitosamente');
        debugPrint('  - Usuario: $_userName');
        debugPrint('  - Rol: ${_userInfo?.rol}');
        debugPrint('  - Email: ${_userInfo?.email}');

      } else {
        debugPrint('Error en respuesta del servidor: ${response.error ?? response.message}');

        // Si es un error 404 o 401, podría ser que el token expiró
        if (response.error?.contains('404') == true || response.error?.contains('401') == true) {
          _handleInvalidSession('Sesión expirada. Por favor, inicie sesión nuevamente');
          return;
        }

        setState(() {
          _loading = false;
          _errorMessage = response.error ?? response.message;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del servidor: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  // NUEVO MÉTODO - Fallback para Post-Registro
  Future<void> _loadUserDataFromServerWithRegistrationFallback() async {
    if (_token == null || _userId == null) {
      _handleInvalidSession('Faltan credenciales de autenticación');
      return;
    }

    try {
      debugPrint('REGISTRO - Intentando cargar datos del servidor...');

      // PRIMER INTENTO: HomeService normal
      final response = await HomeService.getUserDataWithStats(
        token: _token!,
        userId: _userId!,
        maxRetries: 2,
        timeout: const Duration(seconds: 10),
      );

      debugPrint('REGISTRO - Respuesta HomeService: ${response.success}');

      if (response.success && response.data != null) {
        // ÉXITO CON HOMESERVICE
        final userData = response.data!;

        setState(() {
          if (userData.userInfo.nombre.isNotEmpty) {
            _userName = userData.userInfo.nombre;
          }
          _userInfo = userData.userInfo;
          _statistics = userData.statistics;
          _loading = false;
          _errorMessage = null;
        });

        await _updateSharedPreferences(userData.userInfo);
        debugPrint('REGISTRO - Datos del servidor cargados exitosamente');

      } else {
        // FALLÓ HOMESERVICE - USAR FALLBACK CON DATOS LOCALES
        debugPrint('REGISTRO - HomeService falló, usando fallback con datos locales');
        await _loadUserDataWithLocalFallback();
      }

    } catch (e) {
      debugPrint('REGISTRO - Error cargando del servidor: $e');
      // FALLBACK CON DATOS LOCALES
      await _loadUserDataWithLocalFallback();
    }
  }

  // NUEVO MÉTODO - Fallback con Datos Locales
  Future<void> _loadUserDataWithLocalFallback() async {
    try {
      debugPrint('REGISTRO - Aplicando fallback con datos locales...');

      final prefs = await SharedPreferences.getInstance();

      // CREAR UserInfo CON DATOS LOCALES
      final localUserInfo = UserInfo(
        idUsuario: int.tryParse(_userId ?? '0') ?? 0,
        nombre: _userName,
        email: prefs.getString('userEmail') ?? '',
        rol: _userRole ?? 'user',
      );

      // CREAR ESTADÍSTICAS VACÍAS
      final emptyStatistics = HomeStatistics(
        totalEdificios: 0,
        edificiosEvaluados: 0,
        edificiosPendientes: 0,
        inspeccionesRealizadas: 0,
      );

      setState(() {
        _userInfo = localUserInfo;
        _statistics = emptyStatistics;
        _loading = false;
        _errorMessage = null;
      });

      debugPrint('REGISTRO - Fallback aplicado exitosamente');
      debugPrint('  - Nombre: ${localUserInfo.nombre}');
      debugPrint('  - Email: ${localUserInfo.email}');
      debugPrint('  - Rol: ${localUserInfo.rol}');

      // MOSTRAR MENSAJE AL USUARIO
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Algunos datos se actualizarán en el próximo uso.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      debugPrint('REGISTRO - Error en fallback local: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Error configurando datos iniciales: $e';
      });
    }
  }

  void _handleInvalidSession(String message) {
    debugPrint('Sesión inválida: $message');
    setState(() {
      _loading = false;
      _errorMessage = message;
    });

    // Limpiar datos y redirigir al login después de un breve delay
    Future.delayed(const Duration(seconds: 2), () {
      _logout(showMessage: false);
    });
  }

  Future<void> _updateSharedPreferences(UserInfo userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Actualizar datos del usuario
      if (userInfo.nombre.isNotEmpty) {
        await prefs.setString('userName', userInfo.nombre);
      }

      // Actualizar role si viene del servidor
      if (userInfo.rol.isNotEmpty && userInfo.rol != _userRole) {
        await prefs.setString('userRole', userInfo.rol.toLowerCase());
        setState(() {
          _userRole = userInfo.rol.toLowerCase();
        });
      }

      debugPrint('SharedPreferences actualizado');
    } catch (e) {
      debugPrint('Error actualizando SharedPreferences: $e');
    }
  }

  Future<void> _logout({bool showMessage = true}) async {
    try {
      // Usar AuthService para limpiar la sesión
      AuthService.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      debugPrint('Error durante logout: $e');
      // Aun así intentar navegar
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    await _loadUserDataFromServer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SismosApp'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refreshData,
            tooltip: 'Actualizar datos',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando datos...', style: TextStyle(color: AppColors.text)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _errorMessage!.contains('sesión') || _errorMessage!.contains('token')
                        ? Icons.lock_outline
                        : Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!.contains('sesión') || _errorMessage!.contains('token')
                        ? 'Sesión expirada'
                        : 'Error al cargar datos',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_errorMessage!.contains('sesión') && !_errorMessage!.contains('token'))
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 32),
            _buildMenuOptions(),
          ],
        ),
      ),
    );
  }

  // SECCIÓN DE BIENVENIDA MEJORADA - Muestra más información
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $_userName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bienvenido a SismosApp',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withOpacity(0.7),
            ),
          ),

          // MOSTRAR INFORMACIÓN ADICIONAL SI DISPONIBLE
          if (_userInfo != null && _userInfo!.email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _userInfo!.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_userRole != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(_userRole!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getRoleColor(_userRole!).withOpacity(0.3)),
              ),
              child: Text(
                _getRoleDisplayName(_userRole!),
                style: TextStyle(
                  fontSize: 12,
                  color: _getRoleColor(_userRole!),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMenuOption(
          context,
          'Edificios registrados',
          'https://cdn-icons-png.flaticon.com/512/1441/1441359.png',
          Icons.apartment,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BuildingsScreen()),
            );
          },
        ),
        _buildMenuOption(
          context,
          'Edificios evaluados',
          'https://cdn-icons-png.flaticon.com/128/12218/12218407.png',
          Icons.assignment_turned_in,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssessedBuildingsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: AppColors.gray300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {}, // Ya estamos en home
            color: AppColors.primary,
            tooltip: 'Inicio',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: (_userId != null && _token != null)
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileAdminScreen(
                    userId: _userId,
                    token: _token,
                  ),
                ),
              );
            }
                : null,
            color: (_userId != null && _token != null)
                ? AppColors.text
                : AppColors.gray500,
            tooltip: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
      BuildContext context,
      String title,
      String imageUrl,
      IconData fallbackIcon,
      VoidCallback onTap,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                imageUrl,
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      fallbackIcon,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 60,
                    height: 60,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for role management
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'inspector':
        return Colors.blue;
      case 'ayudante':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'inspector':
        return 'Inspector';
      case 'ayudante':
        return 'Ayudante';
      default:
        return role.toUpperCase();
    }
  }
}