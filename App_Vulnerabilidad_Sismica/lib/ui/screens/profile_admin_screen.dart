import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

class ProfileAdminScreen extends StatefulWidget {
  final String? userId;
  final String? token;

  const ProfileAdminScreen({super.key, this.userId, this.token});

  @override
  State<ProfileAdminScreen> createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      // Primero intentamos usar los parámetros pasados
      String? userId = widget.userId;
      String? token = widget.token;

      // Si no vienen por parámetro, los obtenemos de SharedPreferences
      if (userId == null || token == null) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('userId');
        token = prefs.getString('accessToken');
      }

      debugPrint('🔍 Datos para la petición:');
      debugPrint('  - userId: $userId');
      debugPrint('  - token: ${token?.substring(0, 20)}...');

      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage = "No se encontró información de sesión válida.";
        });
        return;
      }

      // Construir la URL correctamente
      final url = 'http://192.168.100.4:3000/users/$userId';
      debugPrint('📡 Haciendo petición GET a: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint('📊 Respuesta del servidor:');
      debugPrint('  - Status: ${response.statusCode}');
      debugPrint('  - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Manejo flexible de la estructura de respuesta
        Map<String, dynamic>? userData;

        if (data is Map<String, dynamic>) {
          // Si la respuesta tiene un campo 'user'
          if (data.containsKey('user')) {
            userData = data['user'] as Map<String, dynamic>?;
          }
          // Si la respuesta tiene un campo 'data'
          else if (data.containsKey('data')) {
            userData = data['data'] as Map<String, dynamic>?;
          }
          // Si la respuesta es directamente el usuario
          else if (data.containsKey('id') || data.containsKey('email')) {
            userData = data;
          }
        }

        debugPrint('👤 Datos del usuario procesados: $userData');

        setState(() {
          _userData = userData;
          _loading = false;
          _errorMessage = null;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _loading = false;
          _errorMessage = "Token de autenticación inválido. Por favor, inicie sesión nuevamente.";
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _loading = false;
          _errorMessage = "Usuario no encontrado.";
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = "Error del servidor: ${response.statusCode}";
        });
        debugPrint("❌ Error al cargar usuario: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = "Error de conexión: $e";
      });
      debugPrint("❌ Excepción al cargar usuario: $e");
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    await prefs.remove('userName');

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                "Cargando perfil...",
                style: TextStyle(color: AppColors.text),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _errorMessage = null;
                  });
                  _fetchUser();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            "No se encontró información del usuario.",
            style: TextStyle(color: AppColors.text),
          ),
        ),
      );
    }

    // Extraer datos del usuario con valores por defecto
    final fotoUrl = _userData!['foto'] as String?;
    final nombre = _userData!['nombre']?.toString() ??
        _userData!['name']?.toString() ??
        'Sin nombre';
    final email = _userData!['email']?.toString() ?? 'Sin correo';
    final rol = _userData!['rol']?.toString() ??
        _userData!['role']?.toString() ??
        'Sin rol';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                    ? NetworkImage(fotoUrl)
                    : const AssetImage("assets/images/avatar_placeholder.png")
                as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(color: AppColors.gray500),
            ),
            const SizedBox(height: 8),
            Text(
              "Rol: $rol",
              style: const TextStyle(color: AppColors.text),
            ),
            const Divider(height: 32, color: AppColors.gray300),

            // Información de debug (solo en desarrollo)
            if (true) // Cambia a false en producción
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Info de Debug:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("UserID recibido: ${widget.userId}"),
                    Text("Token presente: ${widget.token != null ? 'Sí' : 'No'}"),
                    Text("Datos cargados: ${_userData?.keys.join(', ')}"),
                  ],
                ),
              ),

            if (rol.toLowerCase() == "admin")
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/userList');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("Asignar rol"),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gray500,
              ),
              child: const Text("Editar perfil"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text("Cerrar sesión"),
            ),
          ],
        ),
      ),
    );
  }
}