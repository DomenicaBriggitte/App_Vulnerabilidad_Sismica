import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/ui/screens/login_screen.dart';
import '../../core/theme/app_colors.dart';

class ProfileAdminScreen extends StatefulWidget {
  final String? userId;
  const ProfileAdminScreen({super.key, this.userId});

  @override
  State<ProfileAdminScreen> createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    if (widget.userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.4:3000/users/${widget.userId}'),
        headers: {"Content-Type": "application/json"},
      );


      if (response.statusCode == 200) {
        setState(() {
          _userData = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      debugPrint("Error al cargar usuario: $e");
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_userData == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No se encontró información del usuario.",
            style: TextStyle(color: AppColors.text),
          ),
        ),
      );
    }

    final fotoUrl = _userData!['foto'] as String?;
    final nombre = _userData!['nombre'] ?? 'Sin nombre';
    final email = _userData!['email'] ?? 'Sin correo';
    final rol = _userData!['rol'] ?? 'Sin rol';

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
            if (rol == "admin")
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/roles/assign');
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
