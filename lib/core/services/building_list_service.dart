// building_list_service.dart - CON VALIDACIÓN DE IMÁGENES MEJORADA
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:http_parser/http_parser.dart' as http;

import '../constants/database_endpoints.dart';
import 'database_service.dart';
import '../../data/models/database_response.dart';
import '../../data/models/building_list_response.dart';

class BuildingListService {

  // OBTENER LISTA DE EDIFICIOS
  static Future<BuildingListResponse> getBuildings({
    int? limit,
    int? offset,
    String? search,
    String? inspector,
    int maxRetries = 2,
  }) async {
    int attemptCount = 0;

    while (attemptCount < maxRetries) {
      attemptCount++;

      try {
        print('BuildingListService: Intento $attemptCount/$maxRetries para obtener edificios');

        // Construir query parameters
        Map<String, String> queryParams = {};
        if (limit != null) queryParams['limit'] = limit.toString();
        if (offset != null) queryParams['offset'] = offset.toString();
        if (search != null && search.trim().isNotEmpty) {
          queryParams['search'] = search.trim();
        }
        if (inspector != null && inspector.trim().isNotEmpty) {
          queryParams['inspector'] = inspector.trim();
        }

        // Construir endpoint con query params
        String endpoint = DatabaseEndpoints.buildings;
        if (queryParams.isNotEmpty) {
          final query = queryParams.entries
              .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
              .join('&');
          endpoint = '$endpoint?$query';
        }

        final response = await DatabaseService.get<dynamic>(
          endpoint,
          requiresAuth: true,
        );

        print('Response success: ${response.success}');
        print('Response data type: ${response.data.runtimeType}');
        print('Response error: ${response.error}');

        if (response.success && response.data != null) {
          List<BuildingData> buildings = [];

          try {
            // Manejar diferentes estructuras de respuesta
            if (response.data is String) {
              final parsedData = json.decode(response.data as String);
              buildings = _parseBuildings(parsedData);
            } else if (response.data is List) {
              buildings = _parseBuildings(response.data);
            } else if (response.data is Map<String, dynamic>) {
              final dataMap = response.data as Map<String, dynamic>;
              if (dataMap.containsKey('edificios')) {
                buildings = _parseBuildings(dataMap['edificios']);
              } else if (dataMap.containsKey('data')) {
                buildings = _parseBuildings(dataMap['data']);
              } else {
                buildings = _parseBuildings([dataMap]);
              }
            }

            print('Edificios parseados exitosamente: ${buildings.length}');

            return BuildingListResponse.success(
              buildings: buildings,
              message: 'Edificios obtenidos correctamente',
              totalCount: buildings.length,
            );

          } catch (parseError) {
            print('Error parseando edificios: $parseError');
            if (attemptCount >= maxRetries) {
              return BuildingListResponse.failure(
                error: 'Error procesando datos de edificios: $parseError',
              );
            }
          }
        } else {
          // Manejar errores específicos
          if (response.statusCode != null &&
              response.statusCode! >= 400 &&
              response.statusCode! < 500) {
            print('Error del cliente (${response.statusCode})');

            String errorMessage = _getErrorMessage(response);

            return BuildingListResponse.failure(
              error: errorMessage,
              statusCode: response.statusCode,
            );
          }

          // Error de conexión, continuar con retry
          print('Intento $attemptCount falló: ${response.error}');
          if (attemptCount >= maxRetries) {
            return BuildingListResponse.failure(
              error: response.error ?? 'Error de conexión después de $maxRetries intentos',
              statusCode: response.statusCode,
            );
          }
        }
      } catch (e) {
        print('Error en intento $attemptCount: $e');

        if (attemptCount >= maxRetries) {
          return BuildingListResponse.failure(
            error: 'Error de conexión después de $maxRetries intentos: $e',
          );
        }

        // Esperar antes del retry
        if (attemptCount < maxRetries) {
          print('Esperando 1 segundo antes del retry...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    return BuildingListResponse.failure(
      error: 'Error inesperado al obtener edificios',
    );
  }

  // MÉ™TODO CORREGIDO PARA ACTUALIZAR CON VALIDACIÓN MEJORADA
  static Future<BuildingListResponse> updateBuildingWithImages({
    required int idEdificio,
    required String nombreEdificio,
    required String direccion,
    String? inspector,
    String? ciudad,
    String? codigoPostal,
    String? usoPrincipal,
    BuildingData? edificioExistente,
    File? nuevaFotoEdificio,
    File? nuevoGraficoEdificio,
    int maxRetries = 2,
    bool reloadList = false,
  }) async {
    // ===== VALIDACIONES BÁSICAS =====
    if (nombreEdificio.trim().isEmpty) {
      return BuildingListResponse.failure(error: 'El nombre del edificio es requerido');
    }
    if (direccion.trim().isEmpty) {
      return BuildingListResponse.failure(error: 'La dirección es requerida');
    }

    // ===== VALIDACIÓN DE ARCHIVOS MEJORADA =====
    String? fileValidationError = _validateImageFiles(nuevaFotoEdificio, nuevoGraficoEdificio);
    if (fileValidationError != null) {
      return BuildingListResponse.failure(error: fileValidationError);
    }

    int attemptCount = 0;

    while (attemptCount < maxRetries) {
      attemptCount++;

      try {
        print('BuildingListService: Intento $attemptCount/$maxRetries para actualizar edificio $idEdificio');

        // CREAR REQUEST MULTIPART MANUAL para manejar múltiples archivos
        final uri = Uri.parse('${DatabaseService.baseUrl}${DatabaseEndpoints.buildings}/$idEdificio');
        final request = http.MultipartRequest('PUT', uri);

        // Agregar headers de autenticación
        if (DatabaseService.hasAuthToken()) {
          request.headers['Authorization'] = 'Bearer ${DatabaseService.getAuthToken()}';
        }

        // ===== PREPARAR SOLO LOS CAMPOS QUE EL SERVIDOR ESPERA =====
        // IMPORTANTE: Solo enviar campos que existen en la tabla edificios
        Map<String, String> fields = {
          'nombre_edificio': nombreEdificio.trim(),
          'direccion': direccion.trim(),
        };

        // Agregar campos opcionales solo si el edificio existente los tiene
        if (edificioExistente != null) {
          // Campos básicos
          if (edificioExistente.ciudad != null) {
            fields['ciudad'] = edificioExistente.ciudad!;
          }
          if (edificioExistente.codigoPostal != null) {
            fields['codigo_postal'] = edificioExistente.codigoPostal!;
          }
          if (edificioExistente.usoPrincipal != null) {
            fields['uso_principal'] = edificioExistente.usoPrincipal!;
          }

          // Coordenadas
          if (edificioExistente.latitud != null) {
            fields['latitud'] = edificioExistente.latitud!.toString();
          }
          if (edificioExistente.longitud != null) {
            fields['longitud'] = edificioExistente.longitud!.toString();
          }

          // Información del edificio
          if (edificioExistente.numeroPisos != null) {
            fields['numero_pisos'] = edificioExistente.numeroPisos!.toString();
          }
          if (edificioExistente.areaTotalPiso != null) {
            fields['area_total_piso'] = edificioExistente.areaTotalPiso!.toString();
          }
          if (edificioExistente.anioConstruccion != null) {
            fields['anio_construccion'] = edificioExistente.anioConstruccion!.toString();
          }
          if (edificioExistente.anioCodigo != null) {
            fields['anio_codigo'] = edificioExistente.anioCodigo!.toString();
          }

          // Campos booleanos - CORRECCIÓN CRÍTICA: El servidor espera "1" para true y "0" para false
          if (edificioExistente.ampliacion != null) {
            fields['ampliacion'] = edificioExistente.ampliacion! ? '1' : '0';
          }
          if (edificioExistente.historico != null) {
            fields['historico'] = edificioExistente.historico! ? '1' : '0';
          }
          if (edificioExistente.albergue != null) {
            fields['albergue'] = edificioExistente.albergue! ? '1' : '0';
          }
          if (edificioExistente.gubernamental != null) {
            fields['gubernamental'] = edificioExistente.gubernamental! ? '1' : '0';
          }

          // Campos adicionales
          if (edificioExistente.anioAmpliacion != null) {
            fields['anio_ampliacion'] = edificioExistente.anioAmpliacion!.toString();
          }
          if (edificioExistente.ocupacion != null) {
            fields['ocupacion'] = edificioExistente.ocupacion!;
          }
          if (edificioExistente.unidades != null) {
            fields['unidades'] = edificioExistente.unidades!.toString();
          }
          if (edificioExistente.otrasIdentificaciones != null && edificioExistente.otrasIdentificaciones!.isNotEmpty) {
            fields['otras_identificaciones'] = edificioExistente.otrasIdentificaciones!;
          }
          if (edificioExistente.comentarios != null && edificioExistente.comentarios!.isNotEmpty) {
            fields['comentarios'] = edificioExistente.comentarios!;
          }
        }

        // AGREGAR LOS CAMPOS AL REQUEST
        request.fields.addAll(fields);

        // ===== AGREGAR ARCHIVOS SOLO SI EXISTEN =====
        if (nuevaFotoEdificio != null) {
          if (!await nuevaFotoEdificio.exists()) {
            return BuildingListResponse.failure(
                error: 'El archivo de foto del edificio no existe o no es accesible'
            );
          }

          try {
            request.files.add(await _createValidatedMultipartFile(
                nuevaFotoEdificio,
                'foto_edificio'
            ));
            print('Archivo foto_edificio agregado: ${nuevaFotoEdificio.path}');
          } catch (e) {
            return BuildingListResponse.failure(
                error: 'Error procesando foto del edificio: $e'
            );
          }
        }

        if (nuevoGraficoEdificio != null) {
          if (!await nuevoGraficoEdificio.exists()) {
            return BuildingListResponse.failure(
                error: 'El archivo de gráfico del edificio no existe o no es accesible'
            );
          }

          try {
            request.files.add(await _createValidatedMultipartFile(
                nuevoGraficoEdificio,
                'grafico_edificio'
            ));
            print('Archivo grafico_edificio agregado: ${nuevoGraficoEdificio.path}');
          } catch (e) {
            return BuildingListResponse.failure(
                error: 'Error procesando gráfico del edificio: $e'
            );
          }
        }

        print('=== UPDATE MULTIPART DATA ===');
        print('Fields enviados: ${request.fields.keys.toList()}');
        print('Número de fields: ${request.fields.length}');
        print('Archivos enviados: ${request.files.length}');
        print('- Nueva foto: ${nuevaFotoEdificio != null ? "Sí" : "No"}');
        print('- Nuevo gráfico: ${nuevoGraficoEdificio != null ? "Sí" : "No"}');
        print('============================');

        // Enviar request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('Update response success: ${response.statusCode >= 200 && response.statusCode < 300}');
        print('Update response code: ${response.statusCode}');
        print('Update response body: ${response.body}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          print('Edificio actualizado exitosamente en intento $attemptCount');

          if (reloadList) {
            try {
              final updatedListResponse = await getBuildings();
              if (updatedListResponse.success) {
                return BuildingListResponse.success(
                  buildings: updatedListResponse.buildings!,
                  message: 'Edificio actualizado correctamente',
                  totalCount: updatedListResponse.totalCount,
                );
              }
            } catch (e) {
              print('Error recargando lista después de actualizar: $e');
            }
          }

          return BuildingListResponse.success(
            buildings: [],
            message: 'Edificio actualizado correctamente',
            totalCount: 0,
          );
        } else {
          // ===== MANEJO MEJORADO DE ERRORES =====
          String errorMessage = _parseErrorResponse(response);

          print('Error en actualización: ${response.statusCode} - $errorMessage');

          if (response.statusCode >= 400 && response.statusCode < 500) {
            // Errores del cliente - no reintentar
            return BuildingListResponse.failure(
              error: errorMessage,
              statusCode: response.statusCode,
            );
          }

          // Errores del servidor - reintentar
          if (attemptCount >= maxRetries) {
            return BuildingListResponse.failure(
              error: 'Error del servidor después de $maxRetries intentos: $errorMessage',
              statusCode: response.statusCode,
            );
          }
        }
      } catch (e) {
        print('Error en actualización intento $attemptCount: $e');

        if (attemptCount >= maxRetries) {
          return BuildingListResponse.failure(
            error: 'Error de conexión después de $maxRetries intentos: $e',
          );
        }

        if (attemptCount < maxRetries) {
          print('Esperando 1 segundo antes del retry...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    return BuildingListResponse.failure(
      error: 'Error inesperado al actualizar edificio',
    );
  }

  // ELIMINAR EDIFICIO
  static Future<BuildingListResponse> deleteBuilding({
    required int idEdificio,
    int maxRetries = 2,
    bool reloadList = false,
  }) async {
    int attemptCount = 0;

    while (attemptCount < maxRetries) {
      attemptCount++;

      try {
        print('BuildingListService: Intento $attemptCount/$maxRetries para eliminar edificio $idEdificio');

        final response = await DatabaseService.delete<Map<String, dynamic>>(
          '${DatabaseEndpoints.buildings}/$idEdificio',
          requiresAuth: true,
        );

        print('Delete response success: ${response.success}');
        print('Delete response data: ${response.data}');
        print('Delete response statusCode: ${response.statusCode}');

        if (response.success) {
          print('Edificio eliminado exitosamente en intento $attemptCount');

          if (reloadList) {
            try {
              final updatedListResponse = await getBuildings();
              if (updatedListResponse.success) {
                return BuildingListResponse.success(
                  buildings: updatedListResponse.buildings!,
                  message: 'Edificio eliminado correctamente',
                  totalCount: updatedListResponse.totalCount,
                );
              }
            } catch (e) {
              print('Error recargando lista después de eliminar: $e');
            }
          }

          return BuildingListResponse.success(
            buildings: [],
            message: 'Edificio eliminado correctamente',
            totalCount: 0,
          );
        } else {
          if (response.statusCode != null &&
              response.statusCode! >= 400 &&
              response.statusCode! < 500) {
            print('Error del cliente en eliminación (${response.statusCode})');

            String errorMessage = _getErrorMessage(response);

            // Para errores 4xx específicos, no reintentar
            if (response.statusCode == 404) {
              return BuildingListResponse.failure(
                error: 'El edificio no existe o ya fue eliminado',
                statusCode: response.statusCode,
              );
            } else if (response.statusCode == 403) {
              return BuildingListResponse.failure(
                error: 'Sin permisos para eliminar este edificio',
                statusCode: response.statusCode,
              );
            } else if (response.statusCode == 409) {
              return BuildingListResponse.failure(
                error: 'No se puede eliminar: el edificio tiene dependencias activas',
                statusCode: response.statusCode,
              );
            }

            return BuildingListResponse.failure(
              error: errorMessage,
              statusCode: response.statusCode,
            );
          }

          print('Intento de eliminación $attemptCount falló: ${response.error}');
          if (attemptCount >= maxRetries) {
            return BuildingListResponse.failure(
              error: response.error ?? 'Error de conexión después de $maxRetries intentos',
              statusCode: response.statusCode,
            );
          }
        }
      } catch (e) {
        print('Error en eliminación intento $attemptCount: $e');

        if (attemptCount >= maxRetries) {
          return BuildingListResponse.failure(
            error: 'Error de conexión después de $maxRetries intentos: $e',
          );
        }

        if (attemptCount < maxRetries) {
          print('Esperando 1 segundo antes del retry...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    return BuildingListResponse.failure(
      error: 'Error inesperado al eliminar edificio',
    );
  }

  // ===== MÉTODOS PRIVADOS AUXILIARES =====

  // VALIDACIÓN DE ARCHIVOS DE IMAGEN MEJORADA
  static String? _validateImageFiles(File? fotoEdificio, File? graficoEdificio) {
    const int maxFileSize = 10 * 1024 * 1024; // 10MB
    const List<String> allowedExtensions = ['.jpg', '.jpeg', '.png'];

    if (fotoEdificio != null) {
      // Validar extensión
      final extension = fotoEdificio.path.toLowerCase().split('.').last;
      if (!allowedExtensions.contains('.$extension')) {
        return 'Formato de foto no válido. Use JPG, JPEG o PNG.';
      }

      // Validar que el archivo existe
      if (!fotoEdificio.existsSync()) {
        return 'El archivo de foto no existe o no es accesible.';
      }

      // Validar tamaño
      try {
        final fileSize = fotoEdificio.lengthSync();
        if (fileSize > maxFileSize) {
          final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          return 'La foto es demasiado grande (${sizeMB}MB). Máximo permitido: 10MB.';
        }
        if (fileSize == 0) {
          return 'El archivo de foto está vacío.';
        }
      } catch (e) {
        return 'Error al verificar el archivo de foto: $e';
      }
    }

    if (graficoEdificio != null) {
      // Validar extensión
      final extension = graficoEdificio.path.toLowerCase().split('.').last;
      if (!allowedExtensions.contains('.$extension')) {
        return 'Formato de gráfico no válido. Use JPG, JPEG o PNG.';
      }

      // Validar que el archivo existe
      if (!graficoEdificio.existsSync()) {
        return 'El archivo de gráfico no existe o no es accesible.';
      }

      // Validar tamaño
      try {
        final fileSize = graficoEdificio.lengthSync();
        if (fileSize > maxFileSize) {
          final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          return 'El gráfico es demasiado grande (${sizeMB}MB). Máximo permitido: 10MB.';
        }
        if (fileSize == 0) {
          return 'El archivo de gráfico está vacío.';
        }
      } catch (e) {
        return 'Error al verificar el archivo de gráfico: $e';
      }
    }

    return null; // Todo válido
  }

  // CREAR ARCHIVO MULTIPART CON VALIDACIÓN DE TIPO MIME
  static Future<http.MultipartFile> _createValidatedMultipartFile(File file, String fieldName) async {
    // Detectar el tipo MIME basado en la extensión
    String mimeType;
    final extension = file.path.toLowerCase();

    if (extension.endsWith('.jpg') || extension.endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (extension.endsWith('.png')) {
      mimeType = 'image/png';
    } else {
      // Fallback - intentar detectar por contenido si es posible
      mimeType = 'image/jpeg'; // Default
    }

    print('_createValidatedMultipartFile:');
    print('  Field: $fieldName');
    print('  File: ${file.path}');
    print('  MIME Type: $mimeType');
    print('  File size: ${await file.length()} bytes');

    return await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: _createMediaType(mimeType),
    );
  }

  // CREAR MEDIA TYPE COMPATIBLE
  static dynamic _createMediaType(String mimeType) {
    try {
      // Intentar usar MediaType si está disponible
      final parts = mimeType.split('/');
      if (parts.length == 2) {
        // Crear MediaType manualmente
        return http.MediaType(parts[0], parts[1]);
      }
    } catch (e) {
      print('Error creando MediaType: $e');
    }
    return null; // Usar detección automática
  }

  // PARSING MEJORADO DE ERRORES
  static String _parseErrorResponse(http.Response response) {
    String errorMessage = 'Error del servidor';

    try {
      final errorData = json.decode(response.body);
      if (errorData is Map<String, dynamic>) {
        if (errorData['error'] != null) {
          if (errorData['error'] is Map && errorData['error']['message'] != null) {
            errorMessage = errorData['error']['message'];
          } else if (errorData['error'] is String) {
            errorMessage = errorData['error'];
          }
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
      }
    } catch (e) {
      errorMessage = response.body.isNotEmpty ? response.body : 'Error desconocido';
    }

    // Mensajes específicos mejorados
    switch (response.statusCode) {
      case 400:
        if (errorMessage.isEmpty || errorMessage.contains('HTTP 400')) {
          errorMessage = 'Datos del edificio incorrectos o incompletos. Revise:\n'
              '• Nombre del edificio (mínimo 3 caracteres)\n'
              '• Todos los campos requeridos\n'
              '• Formato de archivos (JPG/PNG)\n'
              '• Valores numéricos válidos';
        }
        break;
      case 401:
        errorMessage = 'No autorizado. Inicie sesión nuevamente.';
        break;
      case 413:
        errorMessage = 'Los archivos son demasiado grandes (máximo 10MB cada uno)';
        break;
      case 415:
        errorMessage = 'Formato de archivo no válido. Use solo JPG o PNG.';
        break;
      case 422:
        if (errorMessage.isEmpty || errorMessage.contains('HTTP 422')) {
          errorMessage = 'Error de validación en los datos:\n'
              '• Verifique formatos de fecha y números\n'
              '• Campos requeridos completos\n'
              '• Rangos de valores válidos';
        }
        break;
      case 500:
        errorMessage = 'Error interno del servidor. Intente nuevamente.';
        break;
    }

    return errorMessage;
  }

  static List<BuildingData> _parseBuildings(dynamic data) {
    List<BuildingData> buildings = [];

    try {
      if (data is List) {
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            buildings.add(BuildingData.fromJson(item));
          }
        }
      } else if (data is Map<String, dynamic>) {
        buildings.add(BuildingData.fromJson(data));
      }
    } catch (e) {
      print('Error parseando edificio individual: $e');
      throw Exception('Error al procesar datos de edificios: $e');
    }

    return buildings;
  }

  static String _getErrorMessage(DatabaseResponse response) {
    String errorMessage = 'Error desconocido';

    try {
      if (response.data != null) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data['error'] != null) {
            final errorObj = data['error'];
            if (errorObj is Map<String, dynamic> && errorObj['message'] != null) {
              errorMessage = errorObj['message'];
            } else if (errorObj is String) {
              errorMessage = errorObj;
            }
          } else if (data['message'] != null) {
            errorMessage = data['message'];
          }
        } else if (data is String) {
          errorMessage = data as String;
        }
      }

      if (errorMessage == 'Error desconocido' && response.error != null) {
        errorMessage = response.error!;
      }
    } catch (e) {
      print('Error extrayendo mensaje: $e');
      errorMessage = response.error ?? 'Error de formato en la respuesta';
    }

    // Mensajes específicos por código de estado
    switch (response.statusCode) {
      case 400:
        if (errorMessage.isEmpty || errorMessage.contains('HTTP 400')) {
          errorMessage = 'Datos inválidos en la solicitud';
        }
        break;
      case 401:
        errorMessage = 'No autorizado. Inicie sesión nuevamente.';
        break;
      case 403:
        errorMessage = 'Acceso denegado';
        break;
      case 404:
        errorMessage = 'Edificio no encontrado';
        break;
      case 422:
        if (errorMessage.isEmpty || errorMessage.contains('HTTP 422')) {
          errorMessage = 'Error de validación en los datos';
        }
        break;
      case 500:
        errorMessage = 'Error interno del servidor';
        break;
    }

    return errorMessage;
  }
}