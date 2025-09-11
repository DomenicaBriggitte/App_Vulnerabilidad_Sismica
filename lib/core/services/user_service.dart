import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/database_config.dart';
import '../../data/models/database_response.dart';
import '../../data/models/user_response.dart';
import '../constants/database_endpoints.dart';
import 'database_service.dart';

class UserService {
  /// Obtener usuario por ID - para ProfileAdminScreen
  static Future<UserResponse> getUserById({
    required String token,
    required String userId,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;

        // Establecer el token de autenticación
        DatabaseService.setAuthToken(token);

        // Usar DatabaseService para hacer la petición
        final response = await DatabaseService.get<dynamic>(
          '${DatabaseEndpoints.user}/$userId',
          requiresAuth: true,
        );

        print('UserService.getUserById - Attempt: $attempts, Success: ${response.success}');

        if (response.success && response.data != null) {
          // Manejo seguro de tipos de respuesta
          Map<String, dynamic>? userData;

          try {
            if (response.data is String) {
              // Si es String, intentar parsearlo como JSON
              final parsedData = json.decode(response.data as String);
              if (parsedData is Map<String, dynamic>) {
                userData = _extractUserData(parsedData);
              }
            } else if (response.data is Map<String, dynamic>) {
              // Manejo normal para Map
              userData = _extractUserData(response.data as Map<String, dynamic>);
            }
          } catch (parseError) {
            print('Error parsing user data: $parseError');
            if (attempts >= maxRetries) {
              return UserResponse.error('Error procesando datos del usuario: $parseError');
            }
            if (attempts < maxRetries) {
              await Future.delayed(Duration(seconds: attempts));
              continue;
            }
          }

          if (userData != null) {
            return UserResponse.success(
              UserData.fromJson(userData),
              message: 'Usuario obtenido correctamente',
            );
          } else {
            if (attempts >= maxRetries) {
              return UserResponse.error('Estructura de respuesta inválida');
            }
          }
        } else {
          // Si es un error de cliente (4xx), no reintentar
          if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
            return UserResponse.error(_getErrorMessage(response));
          }

          // Para otros errores, reintentar
          if (attempts >= maxRetries) {
            return UserResponse.error(_getErrorMessage(response));
          }
        }

        // Esperar antes del siguiente intento
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        }

      } catch (e) {
        print('Error en getUserById attempt $attempts: $e');
        if (attempts >= maxRetries) {
          return UserResponse.error('Error inesperado: $e');
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return UserResponse.error('Error después de $maxRetries intentos');
  }

  /// Actualizar usuario - para EditProfileScreen
  static Future<UserResponse> updateUser({
    required String token,
    required String userId,
    String? nombre,
    String? telefono,
    String? email,
    String? cedula,
    String? direccion,
    String? currentPassword,
    String? newPassword,
    File? imageFile,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;

        // Establecer el token de autenticación
        DatabaseService.setAuthToken(token);

        // Preparar campos para la actualización
        Map<String, String> fields = {};

        if (nombre != null && nombre.trim().isNotEmpty) {
          fields['nombre'] = nombre.trim();
        }
        if (telefono != null && telefono.trim().isNotEmpty) {
          fields['telefono'] = telefono.trim();
        }
        if (email != null && email.trim().isNotEmpty) {
          fields['email'] = email.trim();
        }
        if (cedula != null && cedula.trim().isNotEmpty) {
          fields['cedula'] = cedula.trim();
        }
        if (direccion != null && direccion.trim().isNotEmpty) {
          fields['direccion'] = direccion.trim();
        }
        if (currentPassword != null && currentPassword.trim().isNotEmpty) {
          fields['currentPassword'] = currentPassword.trim();
        }
        if (newPassword != null && newPassword.trim().isNotEmpty) {
          fields['password'] = newPassword.trim();
        }

        print('UserService.updateUser - Attempt: $attempts, Fields: ${fields.keys.toList()}');

        DatabaseResponse<Map<String, dynamic>> response;

        // LÓGICA MEJORADA PARA DECIDIR EL MÉTODO
        if (imageFile != null) {
          // Si hay archivo, SIEMPRE usar multipart
          response = await _updateUserWithFile(userId, fields, imageFile);
        } else {
          // Sin archivo, usar JSON normal (más eficiente)
          response = await _updateUserWithoutFile(userId, fields);
        }

        if (response.success && response.data != null) {
          // Extraer datos del usuario de la respuesta
          final userData = _extractUserData(response.data!);
          if (userData != null) {
            return UserResponse.success(
              UserData.fromJson(userData),
              message: 'Usuario actualizado correctamente',
            );
          } else {
            return UserResponse.error('Respuesta inválida del servidor');
          }
        } else {
          // Si es un error de cliente (4xx), no reintentar
          if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
            return UserResponse.error(_getErrorMessage(response));
          }

          // Para otros errores, reintentar
          if (attempts >= maxRetries) {
            return UserResponse.error(_getErrorMessage(response));
          }
        }

        // Esperar antes del siguiente intento
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        }

      } catch (e) {
        print('Error en updateUser attempt $attempts: $e');
        if (attempts >= maxRetries) {
          return UserResponse.error('Error inesperado: $e');
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return UserResponse.error('Error después de $maxRetries intentos');
  }

  /// Obtener lista de usuarios sin rol - para UserListScreen
  static Future<UsersListResponse> getUsersWithoutRole({
    required String token,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;

        // Establecer el token de autenticación
        DatabaseService.setAuthToken(token);

        // Usar el endpoint general /users
        final response = await DatabaseService.get<dynamic>(
          DatabaseEndpoints.user,
          requiresAuth: true,
        );

        print('UserService.getUsersWithoutRole - Attempt: $attempts, Success: ${response.success}');

        if (response.success && response.data != null) {
          List<dynamic> usersData = [];

          // Manejo seguro de tipos de respuesta
          try {
            usersData = _extractUsersArray(response.data);
          } catch (parseError) {
            print('Error parsing response data: $parseError');
            if (attempts >= maxRetries) {
              return UsersListResponse.error('Error procesando respuesta del servidor: $parseError');
            }
            if (attempts < maxRetries) {
              await Future.delayed(Duration(seconds: attempts));
              continue;
            }
          }

          // Convertir a lista de UserData y filtrar usuarios sin rol
          final users = usersData
              .map((userData) => UserData.fromJson(userData as Map<String, dynamic>))
              .where((user) => !user.hasValidRole) // Solo usuarios sin rol válido
              .toList();

          return UsersListResponse.success(
            users,
            message: 'Lista de usuarios sin rol obtenida correctamente',
          );
        } else {
          // Si es un error de cliente (4xx), no reintentar
          if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
            return UsersListResponse.error(_getErrorMessage(response));
          }

          // Para otros errores, reintentar
          if (attempts >= maxRetries) {
            return UsersListResponse.error(_getErrorMessage(response));
          }
        }

        // Esperar antes del siguiente intento
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        }

      } catch (e) {
        print('Error en getUsersWithoutRole attempt $attempts: $e');
        if (attempts >= maxRetries) {
          return UsersListResponse.error('Error inesperado: $e');
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return UsersListResponse.error('Error después de $maxRetries intentos');
  }

  /// Obtener lista de TODOS los usuarios - para gestión de roles
  static Future<UsersListResponse> getAllUsers({
    required String token,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;

        // Establecer el token de autenticación
        DatabaseService.setAuthToken(token);

        // Usar el endpoint general /users
        final response = await DatabaseService.get<dynamic>(
          DatabaseEndpoints.user,
          requiresAuth: true,
        );

        print('UserService.getAllUsers - Attempt: $attempts, Success: ${response.success}');

        if (response.success && response.data != null) {
          List<dynamic> usersData = [];

          // Manejo seguro de tipos de respuesta
          try {
            usersData = _extractUsersArray(response.data);
          } catch (parseError) {
            print('Error parsing response data: $parseError');
            if (attempts >= maxRetries) {
              return UsersListResponse.error('Error procesando respuesta del servidor: $parseError');
            }
            if (attempts < maxRetries) {
              await Future.delayed(Duration(seconds: attempts));
              continue;
            }
          }

          // Convertir a lista de UserData - SIN filtrar por rol (excepto admins si es necesario)
          final users = usersData
              .map((userData) => UserData.fromJson(userData as Map<String, dynamic>))
              .where((user) => user.rol.toLowerCase() != 'admin') // Opcional: excluir admins
              .toList();

          return UsersListResponse.success(
            users,
            message: 'Lista completa de usuarios obtenida correctamente',
          );
        } else {
          // Si es un error de cliente (4xx), no reintentar
          if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
            return UsersListResponse.error(_getErrorMessage(response));
          }

          // Para otros errores, reintentar
          if (attempts >= maxRetries) {
            return UsersListResponse.error(_getErrorMessage(response));
          }
        }

        // Esperar antes del siguiente intento
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        }

      } catch (e) {
        print('Error en getAllUsers attempt $attempts: $e');
        if (attempts >= maxRetries) {
          return UsersListResponse.error('Error inesperado: $e');
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return UsersListResponse.error('Error después de $maxRetries intentos');
  }

  /// Obtener usuarios por rol específico - método adicional
  static Future<UsersListResponse> getUsersByRole({
    required String token,
    required String role,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;

        // Establecer el token de autenticación
        DatabaseService.setAuthToken(token);

        // Usar el endpoint byRole específico
        final response = await DatabaseService.get<dynamic>(
          '${DatabaseEndpoints.user}/byRole/$role',
          requiresAuth: true,
        );

        print('UserService.getUsersByRole - Attempt: $attempts, Role: $role, Success: ${response.success}');

        if (response.success && response.data != null) {
          List<dynamic> usersData = [];

          // Manejo seguro de tipos de respuesta
          try {
            usersData = _extractUsersArray(response.data);
          } catch (parseError) {
            print('Error parsing response data: $parseError');
            if (attempts >= maxRetries) {
              return UsersListResponse.error('Error procesando respuesta del servidor: $parseError');
            }
            if (attempts < maxRetries) {
              await Future.delayed(Duration(seconds: attempts));
              continue;
            }
          }

          // Convertir a lista de UserData
          final users = usersData
              .map((userData) => UserData.fromJson(userData as Map<String, dynamic>))
              .toList();

          return UsersListResponse.success(
            users,
            message: 'Lista de usuarios con rol $role obtenida correctamente',
          );
        } else {
          // Si es un error de cliente (4xx), no reintentar
          if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
            return UsersListResponse.error(_getErrorMessage(response));
          }

          // Para otros errores, reintentar
          if (attempts >= maxRetries) {
            return UsersListResponse.error(_getErrorMessage(response));
          }
        }

        // Esperar antes del siguiente intento
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        }

      } catch (e) {
        print('Error en getUsersByRole attempt $attempts: $e');
        if (attempts >= maxRetries) {
          return UsersListResponse.error('Error inesperado: $e');
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return UsersListResponse.error('Error después de $maxRetries intentos');
  }

  /// Asignar rol a usuario - para AssignRoleScreen
  static Future<UserResponse> assignRole({
    required String token,
    required String userId,
    required String role,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;

        // Establecer el token de autenticación
        DatabaseService.setAuthToken(token);

        // Usar PATCH para asignar rol
        final response = await DatabaseService.patch<Map<String, dynamic>>(
          '${DatabaseEndpoints.user}/$userId/role',
          {'rol': role},
          requiresAuth: true,
        );

        print('UserService.assignRole - Attempt: $attempts, Success: ${response.success}');

        if (response.success && response.data != null) {
          final userData = _extractUserData(response.data!);
          if (userData != null) {
            return UserResponse.success(
              UserData.fromJson(userData),
              message: 'Rol asignado correctamente',
            );
          } else {
            return UserResponse.error('Respuesta inválida del servidor');
          }
        } else {
          // Si es un error de cliente (4xx), no reintentar
          if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
            return UserResponse.error(_getErrorMessage(response));
          }

          // Para otros errores, reintentar
          if (attempts >= maxRetries) {
            return UserResponse.error(_getErrorMessage(response));
          }
        }

        // Esperar antes del siguiente intento
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        }

      } catch (e) {
        print('Error en assignRole attempt $attempts: $e');
        if (attempts >= maxRetries) {
          return UserResponse.error('Error inesperado: $e');
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return UserResponse.error('Error después de $maxRetries intentos');
  }

  /// Método helper para validar datos antes de enviarlos
  static String? validateUserData({
    String? nombre,
    String? telefono,
    String? email,
    String? cedula,
  }) {
    if (nombre != null && nombre.trim().isNotEmpty) {
      if (nombre.trim().length < 2) {
        return 'El nombre debe tener al menos 2 caracteres';
      }
      if (nombre.trim().length > 100) {
        return 'El nombre no debe exceder 100 caracteres';
      }
      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(nombre.trim())) {
        return 'El nombre solo puede contener letras y espacios';
      }
    }

    if (telefono != null && telefono.trim().isNotEmpty) {
      // Validación formato E.164 para Ecuador (+593XXXXXXXXX)
      final phoneRegex = RegExp(r'^\+593[0-9]{9}$');
      if (!phoneRegex.hasMatch(telefono.trim())) {
        return 'Formato de teléfono inválido. Use +593XXXXXXXXX';
      }
    }

    if (email != null && email.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email.trim())) {
        return 'Formato de email inválido';
      }
    }

    if (cedula != null && cedula.trim().isNotEmpty) {
      final cedulaRegex = RegExp(r'^\d{10}$');
      if (!cedulaRegex.hasMatch(cedula.trim())) {
        return 'La cédula debe tener 10 dígitos';
      }
    }

    return null; // Sin errores
  }

  /// Método helper para validar contraseñas
  static String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      return null; // Opcional
    }

    if (password.trim().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'La contraseña debe tener al menos una letra mayúscula';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'La contraseña debe tener al menos un número';
    }

    return null; // Sin errores
  }

  // MÉTODOS PRIVADOS AUXILIARES

  /// Extraer datos de usuario de diferentes estructuras de respuesta
  static Map<String, dynamic>? _extractUserData(Map<String, dynamic> responseData) {
    // El servidor puede retornar:
    // - { user: {userData} }
    // - { data: {userData} }
    // - {userData} directamente
    if (responseData.containsKey('user')) {
      return responseData['user'] as Map<String, dynamic>;
    } else if (responseData.containsKey('data')) {
      return responseData['data'] as Map<String, dynamic>;
    } else {
      // Verificar si contiene campos de usuario directamente
      if (responseData.containsKey('id_usuario') || responseData.containsKey('nombre') || responseData.containsKey('email')) {
        return responseData;
      }
    }
    return null;
  }

  /// Extraer array de usuarios de diferentes estructuras de respuesta
  static List<dynamic> _extractUsersArray(dynamic responseData) {
    if (responseData is String) {
      final parsedData = json.decode(responseData as String);
      return _extractUsersArray(parsedData);
    } else if (responseData is List<dynamic>) {
      return responseData;
    } else if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('users')) {
        return responseData['users'] as List<dynamic>;
      } else if (responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is List<dynamic>) {
          return data;
        } else if (data is Map<String, dynamic> && data.containsKey('users')) {
          return data['users'] as List<dynamic>;
        }
      }
    }

    // Si no se puede extraer, retornar lista vacía
    return [];
  }

  /// Actualizar usuario con archivo usando multipart
  static Future<DatabaseResponse<Map<String, dynamic>>> _updateUserWithFile(
      String userId,
      Map<String, String> fields,
      File imageFile,
      ) async {
    try {
      return await DatabaseService.putWithFile<Map<String, dynamic>>(
        '/${DatabaseEndpoints.user}/$userId',
        fields,
        imageFile,
        'foto_perfil',
        requiresAuth: true,
      );
    } catch (e) {
      return DatabaseResponse.error('Error al enviar archivo: $e');
    }
  }

  /// Actualizar usuario sin archivo usando PUT
  static Future<DatabaseResponse<Map<String, dynamic>>> _updateUserWithoutFile(
      String userId,
      Map<String, String> fields,
      ) async {
    try {
      // Convertir a Map<String, dynamic>
      final data = fields.map((key, value) => MapEntry(key, value as dynamic));

      return await DatabaseService.put<Map<String, dynamic>>(
        '${DatabaseEndpoints.user}/$userId',
        data,
        requiresAuth: true,
      );
    } catch (e) {
      return DatabaseResponse.error('Error de conexión PUT: $e');
    }
  }

  /// Helper para mensajes de error consistentes
  static String _getErrorMessage(DatabaseResponse response) {
    if (response.statusCode == 404) {
      return 'Recurso no encontrado';
    } else if (response.statusCode == 401) {
      return 'Token de autenticación inválido o expirado';
    } else if (response.statusCode == 403) {
      return 'Acceso denegado. Permisos insuficientes';
    } else if (response.statusCode == 400) {
      return response.error ?? 'Datos de entrada inválidos';
    } else if (response.statusCode == 422) {
      return response.error ?? 'Error de validación de datos';
    } else if (response.statusCode != null && response.statusCode! >= 500) {
      return 'Error interno del servidor. Intente nuevamente';
    } else {
      return response.error ?? 'Error desconocido de conexión';
    }
  }

  /// Verificar si hay conexión con el servidor
  static Future<bool> checkServerConnection() async {
    try {
      final connectionResponse = await DatabaseService.checkConnection();
      return connectionResponse.success;
    } catch (e) {
      print('Error verificando conexión: $e');
      return false;
    }
  }

  /// Limpiar token de autenticación
  static void clearAuthToken() {
    DatabaseService.clearAuthToken();
  }

  /// Verificar si hay token de autenticación
  static bool hasAuthToken() {
    return DatabaseService.hasAuthToken();
  }
}