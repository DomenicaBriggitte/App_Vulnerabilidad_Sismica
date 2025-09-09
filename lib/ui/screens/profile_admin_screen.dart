import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart'; // ✅ Importar el nuevo servicio
import '../../data/models/user_response.dart';
import 'edit_profile_screen.dart';

class ProfileAdminScreen extends StatefulWidget {
  final String? userId;
  final String? token;

  const ProfileAdminScreen({super.key, this.userId, this.token});

  @override
  State<ProfileAdminScreen> createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  UserData? _userData; // ✅ Usar el modelo del servicio
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      // Obtener credenciales
      String? userId = widget.userId;
      String? token = widget.token;

      if (userId == null || token == null) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('userId');
        token = prefs.getString('accessToken');
      }

      debugPrint('🔍 Cargando perfil - userId: $userId');

      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage = "No se encontró información de sesión válida.";
        });
        return;
      }

      // ✅ Usar el nuevo servicio
      final response = await UserService.getUserById(
        token: token,
        userId: userId,
        maxRetries: 2,
        timeout: const Duration(seconds: 10),
      );

      debugPrint('📊 Respuesta del servicio: ${response.success}');

      if (response.success && response.data != null) {
        setState(() {
          _userData = response.data;
          _loading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = response.error ?? response.message;
        });
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

  Future<void> _navigateToEditProfile() async {
    String? userId = widget.userId;
    String? token = widget.token;

    if (userId == null || token == null) {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      token = prefs.getString('accessToken');
    }

    if (userId == null || token == null || _userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se puede acceder a editar perfil')),
      );
      return;
    }

    // Convertir UserData a Map para compatibilidad con EditProfileScreen
    final userDataMap = {
      'id_usuario': _userData!.idUsuario,
      'nombre': _userData!.nombre,
      'email': _userData!.email,
      'cedula': _userData!.cedula,
      'telefono': _userData!.telefono,
      'rol': _userData!.rol,
      'direccion': _userData!.direccion,
      'foto_perfil_url': _userData!.fotoPerfilUrl,
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userId: userId,
          token: token,
          userData: userDataMap,
        ),
      ),
    );

    // Recargar si hubo cambios
    if (result == true) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
      _fetchUser();
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                  ),
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
                child: const Text("Reintentar", style: TextStyle(color: Colors.white)),
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
            // Imagen de perfil
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: (_userData!.fotoPerfilUrl != null && _userData!.fotoPerfilUrl!.isNotEmpty)
                    ? NetworkImage(_userData!.fotoPerfilUrl!)
                    : const AssetImage("assets/images/avatar_placeholder.png") as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),

            // Información del usuario
            Text(
              _userData!.nombre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userData!.email,
              style: const TextStyle(color: AppColors.gray500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(_userData!.rol).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getRoleColor(_userData!.rol).withOpacity(0.3)),
              ),
              child: Text(
                "Rol: ${_getRoleDisplayName(_userData!.rol)}",
                style: TextStyle(
                  color: _getRoleColor(_userData!.rol),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Información adicional si existe
            if (_userData!.cedula != null && _userData!.cedula!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "CI: ${_userData!.cedula}",
                style: const TextStyle(color: AppColors.gray500),
              ),
            ],
            if (_userData!.telefono != null && _userData!.telefono!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                "Teléfono: ${_userData!.telefono}",
                style: const TextStyle(color: AppColors.gray500),
              ),
            ],

            const Divider(height: 32, color: AppColors.gray300),

            // Botones de acción
            if (_userData!.rol.toLowerCase() == "admin")
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/userList');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Asignar roles",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToEditProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gray500,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "Editar perfil",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Cerrar sesión"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods para colores y nombres de roles
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