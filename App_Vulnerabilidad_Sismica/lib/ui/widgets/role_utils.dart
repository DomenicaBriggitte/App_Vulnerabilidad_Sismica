// lib/utils/role_utils.dart
import 'package:shared_preferences/shared_preferences.dart';

class RoleUtils {
  // Verificar si el usuario actual es admin
  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole') ?? 'user';
    return userRole == 'admin';
  }

  // Obtener el rol del usuario actual
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? 'user';
  }

  // Limpiar datos de sesión (para logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userRole');
  }

  // Verificar si hay sesión activa
  static Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    return token != null && token.isNotEmpty;
  }
}