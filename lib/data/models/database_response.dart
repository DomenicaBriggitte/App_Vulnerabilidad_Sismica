class DatabaseResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  DatabaseResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  /// Constructor para respuesta exitosa
  factory DatabaseResponse.success(T data, {int? statusCode}) {
    return DatabaseResponse._(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  /// Constructor para respuesta de error
  factory DatabaseResponse.error(String error, [int? statusCode]) {
    return DatabaseResponse._(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }

  /// Constructor para falla con datos opcionales
  DatabaseResponse.failure({
    required this.error,
    this.statusCode,
    this.data,
  }) : success = false;

  /// Método helper para reintentos automáticos
  static Future<DatabaseResponse<T>> retryRequest<T>(
      Future<DatabaseResponse<T>> Function() request, {
        int maxRetries = 2,
      }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      attempts++;
      try {
        final result = await request();

        // Si es exitoso o es un error de cliente (4xx), no reintentar
        if (result.success ||
            (result.statusCode != null &&
                result.statusCode! >= 400 &&
                result.statusCode! < 500)) {
          return result;
        }

        // Si es el último intento, devolver el resultado
        if (attempts >= maxRetries) {
          return result;
        }

        // Esperar antes del siguiente intento
        print('Retry ${attempts + 1} en ${attempts} segundos...');
        await Future.delayed(Duration(seconds: attempts));

      } catch (e) {
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    throw Exception('Max retries reached');
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error,
      'statusCode': statusCode,
    };
  }

  /// Crear desde JSON
  factory DatabaseResponse.fromJson(Map<String, dynamic> json) {
    return DatabaseResponse._(
      success: json['success'] ?? false,
      data: json['data'] as T?,
      error: json['error']?.toString(),
      statusCode: json['statusCode'] as int?,
    );
  }

  /// Verificar si es un error de autenticación
  bool get isAuthError {
    return statusCode == 401 || statusCode == 403;
  }

  /// Verificar si es un error de cliente (4xx)
  bool get isClientError {
    return statusCode != null && statusCode! >= 400 && statusCode! < 500;
  }

  /// Verificar si es un error de servidor (5xx)
  bool get isServerError {
    return statusCode != null && statusCode! >= 500;
  }

  /// Obtener mensaje de error amigable
  String get friendlyError {
    if (error != null) return error!;

    switch (statusCode) {
      case 400:
        return 'Datos de entrada inválidos';
      case 401:
        return 'Sesión expirada. Inicie sesión nuevamente';
      case 403:
        return 'Acceso denegado';
      case 404:
        return 'Recurso no encontrado';
      case 422:
        return 'Error de validación de datos';
      case 500:
        return 'Error interno del servidor';
      case 502:
        return 'Servidor no disponible';
      case 503:
        return 'Servicio temporalmente no disponible';
      default:
        return 'Error de conexión desconocido';
    }
  }

  /// Transformar los datos de la respuesta
  DatabaseResponse<U> transform<U>(U Function(T data) transformer) {
    if (success && data != null) {
      try {
        final transformedData = transformer(data!);
        return DatabaseResponse.success(transformedData, statusCode: statusCode);
      } catch (e) {
        return DatabaseResponse.error('Error transforming data: $e', statusCode);
      }
    } else {
      return DatabaseResponse.error(error ?? 'No data to transform', statusCode);
    }
  }

  /// Mapear a otro tipo de DatabaseResponse
  DatabaseResponse<U> map<U>(U? data) {
    if (success) {
      return DatabaseResponse.success(data as U, statusCode: statusCode);
    } else {
      return DatabaseResponse.error(error ?? 'Error mapping response', statusCode);
    }
  }

  /// Combinar con otra respuesta
  DatabaseResponse<List<T>> combine(DatabaseResponse<T> other) {
    if (success && other.success && data != null && other.data != null) {
      return DatabaseResponse.success([data!, other.data!]);
    } else {
      final combinedError = [error, other.error]
          .where((e) => e != null)
          .join('; ');
      return DatabaseResponse.error(combinedError.isNotEmpty ? combinedError : 'Combined error');
    }
  }

  @override
  String toString() {
    return 'DatabaseResponse{success: $success, data: $data, error: $error, statusCode: $statusCode}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DatabaseResponse<T> &&
        other.success == success &&
        other.data == data &&
        other.error == error &&
        other.statusCode == statusCode;
  }

  @override
  int get hashCode {
    return success.hashCode ^
    data.hashCode ^
    error.hashCode ^
    statusCode.hashCode;
  }
}

/// Extensión para facilitar el manejo de listas de respuestas
extension DatabaseResponseList<T> on List<DatabaseResponse<T>> {
  /// Verificar si todas las respuestas son exitosas
  bool get allSuccessful => every((response) => response.success);

  /// Obtener solo las respuestas exitosas
  List<DatabaseResponse<T>> get successful => where((response) => response.success).toList();

  /// Obtener solo las respuestas con error
  List<DatabaseResponse<T>> get failed => where((response) => !response.success).toList();

  /// Obtener todos los datos de respuestas exitosas
  List<T> get successfulData =>
      successful.map((response) => response.data).where((data) => data != null).cast<T>().toList();

  /// Obtener todos los errores
  List<String> get errors =>
      failed.map((response) => response.error).where((error) => error != null).cast<String>().toList();
}

/// Typedef para facilitar el uso con tipos específicos
typedef StringDatabaseResponse = DatabaseResponse<String>;
typedef MapDatabaseResponse = DatabaseResponse<Map<String, dynamic>>;
typedef ListDatabaseResponse<T> = DatabaseResponse<List<T>>;
typedef IntDatabaseResponse = DatabaseResponse<int>;
typedef BoolDatabaseResponse = DatabaseResponse<bool>;