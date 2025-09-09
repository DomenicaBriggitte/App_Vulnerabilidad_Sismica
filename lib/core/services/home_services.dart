import 'dart:convert';
import 'dart:io';
import 'package:flutter_application_1/core/config/database_config.dart';
import 'package:http/http.dart' as http;

import '../../data/models/home_response.dart';

class HomeService {
  static const String _baseUrl = DatabaseConfig.baseUrl;

  /// Método principal: obtiene datos del usuario usando el endpoint correcto
  static Future<HomeResponse> getUserDataWithStats({
    required String token,
    required String userId,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Usar directamente el endpoint /users/:id
      final profileResponse = await getUserProfile(
        token: token,
        userId: userId,
        maxRetries: maxRetries,
        timeout: timeout,
      );

      if (!profileResponse.success) {
        return profileResponse;
      }

      // Las estadísticas pueden agregarse aquí si se implementa el endpoint
      // Por ahora usar estadísticas por defecto
      return profileResponse;

    } catch (e) {
      return HomeResponse.error('Error al obtener datos del usuario: $e');
    }
  }

  /// Obtiene el perfil del usuario usando /users/:id
  static Future<HomeResponse> getUserProfile({
    required String token,
    required String userId,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;

        final response = await http.get(
          Uri.parse('$_baseUrl/users/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(timeout);

        print('Profile response status: ${response.statusCode}');
        print('Profile response body: ${response.body}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          // El servidor retorna directamente los datos del usuario
          final homeData = HomeData(
            userInfo: UserInfo.fromJson(responseData),
            statistics: HomeStatistics(
              totalEdificios: 0,
              edificiosEvaluados: 0,
              edificiosPendientes: 0,
              inspeccionesRealizadas: 0,
            ),
          );

          return HomeResponse.success(homeData, message: 'Perfil obtenido correctamente');

        } else if (response.statusCode == 404) {
          return HomeResponse.error('Usuario no encontrado con ID: $userId');
        } else {
          String errorMessage;
          try {
            final errorData = json.decode(response.body);
            // Adaptarse a la estructura de error del servidor
            if (errorData['error'] != null && errorData['error']['message'] != null) {
              errorMessage = errorData['error']['message'];
            } else {
              errorMessage = errorData['message'] ?? 'Error al obtener perfil';
            }
          } catch (e) {
            errorMessage = 'Error ${response.statusCode}';
          }

          return HomeResponse.error(errorMessage);
        }

      } on SocketException catch (e) {
        print('SocketException in getUserProfile: ${e.message}');
        if (attempts >= maxRetries) {
          return HomeResponse.error('Error de conexión: ${e.message}');
        }
        await Future.delayed(Duration(seconds: attempts));

      } catch (e) {
        print('General error in getUserProfile: $e');
        if (attempts >= maxRetries) {
          return HomeResponse.error('Error inesperado: $e');
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return HomeResponse.error('Error después de $maxRetries intentos');
  }

  /// OPCIONAL: Obtener estadísticas si se implementa el endpoint
  static Future<HomeResponse> getUserStatistics({
    required String token,
    required String userId,
    int maxRetries = 1,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return HomeResponse.fromJson(responseData);
      } else {
        // Si no existe el endpoint, retornar estadísticas por defecto
        return HomeResponse.success(
            HomeData(
              userInfo: UserInfo(idUsuario: 0, nombre: '', email: '', rol: ''),
              statistics: HomeStatistics(
                totalEdificios: 0,
                edificiosEvaluados: 0,
                edificiosPendientes: 0,
                inspeccionesRealizadas: 0,
              ),
            )
        );
      }
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      // Retornar estadísticas vacías si falla
      return HomeResponse.success(
          HomeData(
            userInfo: UserInfo(idUsuario: 0, nombre: '', email: '', rol: ''),
            statistics: HomeStatistics(
              totalEdificios: 0,
              edificiosEvaluados: 0,
              edificiosPendientes: 0,
              inspeccionesRealizadas: 0,
            ),
          )
      );
    }
  }

  /// DEPRECATED: Método anterior usando /users/inspectors
  /// Mantener solo para compatibilidad si es necesario
  @Deprecated('Usar getUserProfile con userId específico')
  static Future<HomeResponse> getHomeData({
    required String token,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Este método ya no debería usarse
    return HomeResponse.error('Método obsoleto. Usar getUserProfile con userId específico.');
  }
}