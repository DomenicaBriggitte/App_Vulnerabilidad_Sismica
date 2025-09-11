// building_list_response.dart
class BuildingListResponse {
  final bool success;
  final List<BuildingData>? buildings;
  final String message;
  final String? error;
  final int? statusCode;
  final int? totalCount;

  BuildingListResponse._({
    required this.success,
    this.buildings,
    required this.message,
    this.error,
    this.statusCode,
    this.totalCount,
  });

  // Respuesta exitosa
  factory BuildingListResponse.success({
    required List<BuildingData> buildings,
    required String message,
    int? totalCount,
    int? statusCode,
  }) {
    return BuildingListResponse._(
      success: true,
      buildings: buildings,
      message: message,
      totalCount: totalCount ?? buildings.length,
      statusCode: statusCode,
    );
  }

  // Respuesta de error
  factory BuildingListResponse.failure({
    required String error,
    int? statusCode,
  }) {
    return BuildingListResponse._(
      success: false,
      message: error,
      error: error,
      statusCode: statusCode,
    );
  }

  // Getters útiles
  bool get hasBuildings => buildings != null && buildings!.isNotEmpty;
  int get buildingCount => buildings?.length ?? 0;
  
  // Verificar si es un error específico
  bool get isAuthError => statusCode == 401 || statusCode == 403;
  bool get isNotFoundError => statusCode == 404;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  // Obtener mensaje de error amigable
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
        return 'Recursos no encontrados';
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

  @override
  String toString() {
    if (success) {
      return 'BuildingListResponse.success(buildings: ${buildingCount}, message: $message)';
    } else {
      return 'BuildingListResponse.failure(error: $error, statusCode: $statusCode)';
    }
  }
}

class BuildingData {
  final int idEdificio;
  final String nombreEdificio;
  final String? direccion;
  final String? inspector;
  final String? fechaHora;
  final String? fotoUrl;
  final String? ciudad;
  final String? codigoPostal;
  final String? usoPrincipal;
  final double? latitud;
  final double? longitud;
  final int? numeroPisos;
  final double? areaTotalPiso;
  final int? anioConstruccion;
  final int? anioCodigo;
  final bool? ampliacion;
  final int? anioAmpliacion;
  final String? ocupacion;
  final bool? historico;
  final bool? albergue;
  final bool? gubernamental;
  final int? unidades;
  final String? otrasIdentificaciones;
  final String? comentarios;
  final String? graficoUrl;

  BuildingData({
    required this.idEdificio,
    required this.nombreEdificio,
    this.direccion,
    this.inspector,
    this.fechaHora,
    this.fotoUrl,
    this.ciudad,
    this.codigoPostal,
    this.usoPrincipal,
    this.latitud,
    this.longitud,
    this.numeroPisos,
    this.areaTotalPiso,
    this.anioConstruccion,
    this.anioCodigo,
    this.ampliacion,
    this.anioAmpliacion,
    this.ocupacion,
    this.historico,
    this.albergue,
    this.gubernamental,
    this.unidades,
    this.otrasIdentificaciones,
    this.comentarios,
    this.graficoUrl,
  });

  factory BuildingData.fromJson(Map<String, dynamic> json) {
    // AGREGAR ESTOS LOGS AL INICIO:
    print('=== PARSING BUILDING DATA ===');
    print('JSON keys: ${json.keys.toList()}');
    print('foto_edificio_url value: ${json['foto_edificio_url']}');
    print('foto_edificio_url type: ${json['foto_edificio_url'].runtimeType}');
    print('grafico_edificio_url value: ${json['grafico_edificio_url']}');
    print('=============================');

    return BuildingData(
      idEdificio: _parseInt(json['id_edificio']) ?? 0,
      nombreEdificio: _parseString(json['nombre_edificio']) ?? 'Sin nombre',
      direccion: _parseString(json['direccion']),
      inspector: _parseString(json['inspector']),
      fechaHora: _parseString(json['fecha_hora']) ?? _parseString(json['fecha_registro_edificio']),
      // FIX: Usar los nombres correctos del servidor
      fotoUrl: _parseString(json['foto_edificio_url']),
      ciudad: _parseString(json['ciudad']),
      codigoPostal: _parseString(json['codigo_postal']),
      usoPrincipal: _parseString(json['uso_principal']),
      latitud: _parseDouble(json['latitud']),
      longitud: _parseDouble(json['longitud']),
      numeroPisos: _parseInt(json['numero_pisos']),
      areaTotalPiso: _parseDouble(json['area_total_piso']),
      anioConstruccion: _parseInt(json['anio_construccion']),
      anioCodigo: _parseInt(json['anio_codigo']),
      ampliacion: _parseBool(json['ampliacion']),
      anioAmpliacion: _parseInt(json['anio_ampliacion']),
      ocupacion: _parseString(json['ocupacion']),
      historico: _parseBool(json['historico']),
      albergue: _parseBool(json['albergue']),
      gubernamental: _parseBool(json['gubernamental']),
      unidades: _parseInt(json['unidades']),
      otrasIdentificaciones: _parseString(json['otras_identificaciones']),
      comentarios: _parseString(json['comentarios']),
      // FIX: Usar el nombre correcto del servidor
      graficoUrl: _parseString(json['grafico_edificio_url']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id_edificio': idEdificio,
      'nombre_edificio': nombreEdificio,
      'direccion': direccion,
      'inspector': inspector,
      'fecha_hora': fechaHora,
      // CORREGIDO: Usar nombres correctos del servidor
      'foto_edificio_url': fotoUrl,
      'ciudad': ciudad,
      'codigo_postal': codigoPostal,
      'uso_principal': usoPrincipal,
      'latitud': latitud,
      'longitud': longitud,
      'numero_pisos': numeroPisos,
      'area_total_piso': areaTotalPiso,
      'anio_construccion': anioConstruccion,
      'anio_codigo': anioCodigo,
      'ampliacion': ampliacion,
      'anio_ampliacion': anioAmpliacion,
      'ocupacion': ocupacion,
      'historico': historico,
      'albergue': albergue,
      'gubernamental': gubernamental,
      'unidades': unidades,
      'otras_identificaciones': otrasIdentificaciones,
      'comentarios': comentarios,
      // CORREGIDO: Usar nombre correcto del servidor
      'grafico_edificio_url': graficoUrl,
    };
  }

  // Convertir a Map compatible con Supabase (por compatibilidad)
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id_edificio': idEdificio,
      'nombre_edificio': nombreEdificio,
      'direccion': direccion ?? '',
      'inspector': inspector ?? 'Desconocido',
      'fecha_hora': fechaHora ?? DateTime.now().toIso8601String(),
      'foto_url': fotoUrl,
      // Agregar otros campos según sea necesario
    };
  }

  // Getters útiles
  String get displayName => nombreEdificio.isNotEmpty ? nombreEdificio : 'Sin nombre';
  String get displayInspector => inspector ?? 'Desconocido';
  String get displayAddress => direccion ?? 'Sin dirección';
  String get displayDate => fechaHora ?? 'Sin fecha';
  
  bool get hasPhoto => fotoUrl != null && fotoUrl!.isNotEmpty;
  bool get hasGraphic => graficoUrl != null && graficoUrl!.isNotEmpty;
  
  // Información de ubicación
  bool get hasLocation => latitud != null && longitud != null;
  String get locationString {
    if (hasLocation) {
      return '${latitud!.toStringAsFixed(4)}, ${longitud!.toStringAsFixed(4)}';
    }
    return 'Sin ubicación';
  }

  // Información básica
  String get basicInfo {
    List<String> info = [];
    if (numeroPisos != null) info.add('$numeroPisos pisos');
    if (areaTotalPiso != null) info.add('${areaTotalPiso!.toStringAsFixed(0)} m²');
    if (anioConstruccion != null) info.add('Construido en $anioConstruccion');
    return info.isEmpty ? 'Sin información adicional' : info.join(' • ');
  }

  // Método para copiar con cambios
  BuildingData copyWith({
    int? idEdificio,
    String? nombreEdificio,
    String? direccion,
    String? inspector,
    String? fechaHora,
    String? fotoUrl,
  }) {
    return BuildingData(
      idEdificio: idEdificio ?? this.idEdificio,
      nombreEdificio: nombreEdificio ?? this.nombreEdificio,
      direccion: direccion ?? this.direccion,
      inspector: inspector ?? this.inspector,
      fechaHora: fechaHora ?? this.fechaHora,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      ciudad: ciudad,
      codigoPostal: codigoPostal,
      usoPrincipal: usoPrincipal,
      latitud: latitud,
      longitud: longitud,
      numeroPisos: numeroPisos,
      areaTotalPiso: areaTotalPiso,
      anioConstruccion: anioConstruccion,
      anioCodigo: anioCodigo,
      ampliacion: ampliacion,
      anioAmpliacion: anioAmpliacion,
      ocupacion: ocupacion,
      historico: historico,
      albergue: albergue,
      gubernamental: gubernamental,
      unidades: unidades,
      otrasIdentificaciones: otrasIdentificaciones,
      comentarios: comentarios,
      graficoUrl: graficoUrl,
    );
  }

  @override
  String toString() {
    return 'BuildingData{idEdificio: $idEdificio, nombreEdificio: $nombreEdificio, inspector: $inspector}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuildingData && other.idEdificio == idEdificio;
  }

  @override
  int get hashCode => idEdificio.hashCode;

  // Métodos de parsing seguros
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString().trim().isEmpty ? null : value.toString().trim();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }
    return double.tryParse(value.toString());
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed == 'true' || trimmed == '1' || trimmed == 'yes') return true;
      if (trimmed == 'false' || trimmed == '0' || trimmed == 'no') return false;
      return null;
    }
    if (value is int) return value != 0;
    return null;
  }
}