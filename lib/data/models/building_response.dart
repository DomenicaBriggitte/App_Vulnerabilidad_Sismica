// building_response.dart
class BuildingResponse {
  final bool success;
  final int? buildingId;
  final String message;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? buildingData;

  BuildingResponse._({
    required this.success,
    this.buildingId,
    required this.message,
    this.error,
    this.statusCode,
    this.buildingData,
  });

  // Respuesta exitosa
  factory BuildingResponse.success({
    int? buildingId,
    required String message,
    Map<String, dynamic>? buildingData,
    int? statusCode,
  }) {
    return BuildingResponse._(
      success: true,
      buildingId: buildingId,
      message: message,
      buildingData: buildingData,
      statusCode: statusCode,
    );
  }

  // Respuesta de error
  factory BuildingResponse.failure({
    required String error,
    int? statusCode,
  }) {
    return BuildingResponse._(
      success: false,
      message: error,
      error: error,
      statusCode: statusCode,
    );
  }

  // Obtener ID del edificio creado
  int? get createdBuildingId => buildingId;

  // Verificar si la creación fue exitosa
  bool get wasCreatedSuccessfully => success && buildingId != null;

  // Debug: Mostrar información del building response
  Map<String, dynamic> toDebugMap() {
    return {
      'success': success,
      'buildingId': buildingId,
      'message': message,
      'error': error,
      'statusCode': statusCode,
      'buildingData': buildingData,
    };
  }

  @override
  String toString() {
    return 'BuildingResponse(success: $success, buildingId: $buildingId, message: $message)';
  }
}
