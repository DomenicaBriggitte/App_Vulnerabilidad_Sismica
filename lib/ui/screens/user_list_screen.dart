import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import 'assign_role_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse('http://192.168.100.4:3000/users'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> usersData = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('users')) {
            usersData = responseData['users'] as List<dynamic>;
          } else if (responseData.containsKey('data')) {
            usersData = responseData['data'] as List<dynamic>;
          }
        } else if (responseData is List<dynamic>) {
          usersData = responseData;
        }

        final filtered = usersData.where((u) {
          final user = u as Map<String, dynamic>;
          final rol = user['rol']?.toString().trim() ?? '';
          return rol.isEmpty || rol.toLowerCase() == 'null' || rol.toLowerCase() == 'sin asignar';
        }).map((e) => e as Map<String, dynamic>).toList();

        setState(() {
          _users = filtered;
          _filteredUsers = filtered;
          _loading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = 'Error al cargar usuarios: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredUsers = _users.where((user) {
        final nombre = user['nombre']?.toString().toLowerCase() ?? '';
        final cedula = user['cedula']?.toString().toLowerCase() ?? '';
        final queryLower = query.toLowerCase();
        return nombre.contains(queryLower) || cedula.contains(queryLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Usuarios sin rol")),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Usuarios sin rol'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar usuario",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final foto = user['foto_perfil_url']?.toString() ?? '';
                final nombre = user['nombre'] ?? 'Sin nombre';
                final cedula = user['cedula'] ?? 'Sin CI';
                final rol = (user['rol']?.toString().isNotEmpty ?? false)
                    ? user['rol']
                    : "Sin asignar";

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (foto.isNotEmpty && Uri.tryParse(foto)?.isAbsolute == true)
                        ? NetworkImage(foto)
                        : const AssetImage("assets/images/avatar_placeholder.png") as ImageProvider,
                  ),
                  title: Text(nombre),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("CI: $cedula"),
                      Text("Rol: $rol"),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignRoleScreen(user: user),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
