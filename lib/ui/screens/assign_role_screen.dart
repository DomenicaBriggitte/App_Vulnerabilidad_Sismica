import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

class AssignRoleScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AssignRoleScreen({super.key, required this.user});

  @override
  State<AssignRoleScreen> createState() => _AssignRoleScreenState();
}

class _AssignRoleScreenState extends State<AssignRoleScreen> {
  String? _selectedRole;

  Future<void> _saveRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    final id = widget.user['id'];

    final response = await http.patch(
      Uri.parse('http://192.168.100.4:3000/users/$id/role'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"rol": _selectedRole}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rol asignado con éxito")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final foto = user['foto_perfil_url']?.toString() ?? '';
    final nombre = user['nombre'] ?? 'Sin nombre';
    final email = user['email'] ?? 'Sin email';
    final rol = (user['rol']?.toString().isNotEmpty ?? false) ? user['rol'] : "Sin asignar";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Asignar rol"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Perfil", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: (foto.isNotEmpty && Uri.tryParse(foto)?.isAbsolute == true)
                    ? NetworkImage(foto)
                    : const AssetImage("assets/images/avatar_placeholder.png") as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),
            Text("Nombre: $nombre"),
            Text("Correo: $email"),
            Text("Rol actual: $rol"),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedRole,
              hint: const Text("Seleccionar rol"),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: "supervisor", child: Text("Supervisor")),
                DropdownMenuItem(value: "ayudante", child: Text("Ayudante")),
              ],
              onChanged: (val) => setState(() => _selectedRole = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedRole == null ? null : _saveRole,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }
}
