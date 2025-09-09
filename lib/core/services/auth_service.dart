import '../constants/database_endpoints.dart';
import 'database_service.dart';
import '../../data/models/database_response.dart';
import '../../data/models/auth_response.dart';

class AuthService {

  // LOGIN con retry automático
  static Future<AuthResponse> login({

    required String email,
    required String password,
    int maxRetries = 2, // Máximo 2 intentos
  }) async {
    int attemptCount = 0;

    while (attemptCount < maxRetries) {
      attemptCount++;

      try {
        print('AuthService: Intento $attemptCount/$maxRetries para $email');

        final response = await DatabaseService.post<Map<String, dynamic>>(
          DatabaseEndpoints.login,
          {
            "email": email.trim(),
            "password": password,
          },
        );

        print('Response data: ${response.data}');

        if (response.success && response.data != null) {
          final data = response.data!;
          final success = data['success'] ?? false;
          final token = data['token'];
          final userId = data['userId']; // CORREGIDO: El servidor retorna userId

          print('Datos extraídos del login:');
          print('  - success: $success');
          print('  - token: ${token != null ? "${token.toString().substring(0, 10)}..." : "null"}');
          print('  - userId: $userId (tipo: ${userId.runtimeType})');

          if (success && token != null && userId != null) {
            // Guardar token automáticamente
            DatabaseService.setAuthToken(token);
            print('Login exitoso en intento $attemptCount');
            print('Token guardado: ${token.toString().substring(0, 20)}...');
            print('ID de usuario: $userId');

            return AuthResponse.success(
              token: token.toString(),
              userId: userId is int ? userId : int.tryParse(userId.toString()),
              nombre: data['nombre'], // Será null porque el login no retorna nombre
              message: '¡Login exitoso! Bienvenido',
            );
          } else {
            print('Datos incompletos en respuesta exitosa:');
            print('  - success: $success');
            print('  - token: ${token != null ? "presente" : "ausente"}');
            print('  - userId: ${userId != null ? "presente" : "ausente"}');

            return AuthResponse.failure(
              error: 'Login falló - respuesta inválida del servidor',
            );
          }
        } else {
          // Manejar estructura de error de tu servidor: { error: { code, message } }
          if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
            print('Error del cliente (${response.statusCode})');
            print('Datos de respuesta: ${response.data}'); // Debug adicional

            // Intentar extraer el mensaje de error de tu estructura específica
            String errorMessage = 'Error desconocido';

            // Tu servidor usa la estructura { error: { code, message } }
            try {
              if (response.data != null) {
                final data = response.data;

                // Caso 1: { error: { message: "..." } }
                if (data is Map<String, dynamic> && data['error'] != null) {
                  final errorObj = data['error'];
                  if (errorObj is Map<String, dynamic> && errorObj['message'] != null) {
                    errorMessage = errorObj['message'];
                  }
                }
                // Caso 2: { message: "..." } directamente
                else if (data is Map<String, dynamic> && data['message'] != null) {
                  errorMessage = data['message'];
                }
                // Caso 3: String directo
                else if (data is String) {
                  errorMessage = data as String;
                }
              }

              // Fallback al error del DatabaseResponse
              if (errorMessage == 'Error desconocido' && response.error != null) {
                errorMessage = response.error!;
              }
            } catch (e) {
              print('Error parseando mensaje: $e');
              errorMessage = response.error ?? 'Error de formato en la respuesta';
            }

            print('Mensaje de error extraído: $errorMessage');

            // Mensajes específicos según el código HTTP
            switch (response.statusCode!) {
              case 400:
              // Tu servidor devuelve 400 para credenciales incorrectas
                if (errorMessage.isEmpty || errorMessage.contains('HTTP 400')) {
                  errorMessage = 'Email o contraseña incorrectos';
                }
                break;
              case 401:
                if (errorMessage.contains('token')) {
                  errorMessage = 'Sesión expirada. Vuelve a iniciar sesión.';
                } else if (errorMessage.isEmpty || errorMessage.contains('HTTP 401')) {
                  errorMessage = 'Email o contraseña incorrectos';
                }
                break;
              case 403:
                if (errorMessage.isEmpty || errorMessage.contains('HTTP 403')) {
                  errorMessage = 'Acceso denegado. Cuenta puede estar deshabilitada.';
                }
                break;
              case 404:
                if (errorMessage.isEmpty || errorMessage.contains('HTTP 404')) {
                  errorMessage = 'Servicio de autenticación no encontrado';
                }
                break;
              case 422:
                if (errorMessage.isEmpty || errorMessage.contains('HTTP 422')) {
                  errorMessage = 'Email o contraseña con formato inválido';
                }
                break;
            }

            return AuthResponse.failure(
              error: errorMessage,
              statusCode: response.statusCode,
            );
          }

          // Error de conexión, continuar con retry
          print('Intento $attemptCount falló: ${response.error}');
          if (attemptCount >= maxRetries) {
            return AuthResponse.failure(
              error: response.error ?? 'Error de conexión después de $maxRetries intentos',
              statusCode: response.statusCode,
            );
          }
        }
      } catch (e) {
        print('Error en intento $attemptCount: $e');

        // Si es el último intento, devolver error
        if (attemptCount >= maxRetries) {
          return AuthResponse.failure(
            error: 'Error de conexión después de $maxRetries intentos: $e',
          );
        }

        // Si no es el último intento, esperar un poco antes del retry
        if (attemptCount < maxRetries) {
          print('Esperando 1 segundo antes del retry...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    // Fallback (no debería llegar aquí)
    return AuthResponse.failure(
      error: 'Error inesperado en el login',
    );
  }

  // LOGOUT - Limpiar sesión
  static void logout() {
    print('AuthService: Cerrando sesión');
    DatabaseService.clearAuthToken();
  }

  // VERIFICAR SI HAY TOKEN
  static bool isLoggedIn() {
    return DatabaseService.hasAuthToken();
  }

  // OBTENER TOKEN ACTUAL
  static String? getCurrentToken() {
    return DatabaseService.getAuthToken();
  }
}