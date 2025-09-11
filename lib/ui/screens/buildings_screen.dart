import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/screens/profile_page.dart';
import 'home_page.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/screens/building_registry_1_screen.dart';
// NUEVOS IMPORTS - Reemplazar Supabase
import '../../core/services/building_list_service.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/building_list_response.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  // VARIABLES REFACTORIZADAS - Reemplazando Supabase
  List<BuildingData> _edificios = [];
  List<BuildingData> _filteredEdificios = [];
  bool _isLoading = false;
  String? _error;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _userName = "";
  BuildingData? _edificioEnEdicion;

  // VARIABLES CORREGIDAS PARA IMÁGENES
  File? _selectedFotoEdificio;
  File? _selectedGraficoEdificio;
  final ImagePicker _picker = ImagePicker();

  // Controladores para el formulario de edición
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _inspectorController = TextEditingController();
  int _edificioIdEnEdicion = 0;

  // MÉTODO REFACTORIZADO PARA OBTENER EDIFICIOS - Sin FutureBuilder
  Future<void> _getEdificios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await BuildingListService.getBuildings(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );

      if (response.success && response.buildings != null) {
        setState(() {
          _edificios = response.buildings!;
          _filteredEdificios = _edificios;
          _isLoading = false;
        });

        // Aplicar filtro de búsqueda si existe
        if (_searchController.text.trim().isNotEmpty) {
          _onSearchChanged();
        }
      } else {
        setState(() {
          _error = response.friendlyError;
          _isLoading = false;
        });

        _showErrorSnackBar(response.friendlyError);
      }
    } catch (e) {
      setState(() {
        _error = 'Error inesperado: $e';
        _isLoading = false;
      });

      _showErrorSnackBar('Error inesperado: $e');
    }
  }

  // MÉTODO REFACTORIZADO PARA OBTENER NOMBRE DE USUARIO
  Future<void> _getUserName() async {
    try {
      // Si tienes un AuthService configurado, podrías hacer algo como:
      // final user = await AuthService.getCurrentUser();
      // setState(() {
      //   _userName = user?.name ?? "Usuario";
      // });

      // Por ahora, usar un valor por defecto
      setState(() {
        _userName = "Usuario"; // O implementar lógica para obtener el nombre real
      });
    } catch (e) {
      print('Error obteniendo nombre de usuario: $e');
      setState(() {
        _userName = "Usuario";
      });
    }
  }

  // MÉTODO MEJORADO PARA ELIMINAR CON GESTIÓN DE ESTADO SEPARADA
  Future<void> _eliminarEdificio(int idEdificio) async {
    // Loading específico para eliminar - no interfiere con otras operaciones
    bool eliminandoEdificio = true;

    try {
      final response = await BuildingListService.deleteBuilding(
        idEdificio: idEdificio,
        reloadList: true, // Usar la nueva opción
      );

      if (response.success) {
        _showSuccessSnackBar('Edificio eliminado correctamente');

        // Si la respuesta incluye la lista actualizada, usarla
        if (response.buildings != null && response.buildings!.isNotEmpty) {
          setState(() {
            _edificios = response.buildings!;
            _filteredEdificios = _edificios;
          });
          _onSearchChanged(); // Reaplicar filtros si existen
        } else {
          // Sino, recargar manualmente
          await _getEdificios();
        }
      } else {
        _showErrorSnackBar(response.friendlyError);
      }
    } catch (e) {
      _showErrorSnackBar('Error inesperado: $e');
    } finally {
      eliminandoEdificio = false;
    }
  }

  // MÉTODO MEJORADO PARA ACTUALIZAR CON AMBAS IMÁGENES OPCIONALES
  Future<void> _actualizarEdificioConImagenes() async {
    // Validaciones locales
    if (_nombreController.text.trim().isEmpty) {
      _showErrorSnackBar('El nombre del edificio es requerido');
      return;
    }
    if (_direccionController.text.trim().isEmpty) {
      _showErrorSnackBar('La dirección es requerida');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // AGREGAR LOGS DE DEBUG:
      print('=== UPDATE WITH IMAGES DEBUG ===');
      print('ID Edificio: $_edificioIdEnEdicion');
      print('Nombre: ${_nombreController.text.trim()}');
      print('Dirección: ${_direccionController.text.trim()}');
      print('Tiene foto nueva: ${_selectedFotoEdificio != null}');
      print('Tiene gráfico nuevo: ${_selectedGraficoEdificio != null}');
      print('Edificio existente: ${_edificioEnEdicion?.toString()}');
      print('===============================');

      final response = await BuildingListService.updateBuildingWithImages(
        idEdificio: _edificioIdEnEdicion,
        nombreEdificio: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        inspector: _inspectorController.text.trim(),
        edificioExistente: _edificioEnEdicion,
        nuevaFotoEdificio: _selectedFotoEdificio,
        nuevoGraficoEdificio: _selectedGraficoEdificio,
        reloadList: true,
      );

      // AGREGAR LOG DE RESPUESTA:
      print('=== UPDATE RESPONSE ===');
      print('Success: ${response.success}');
      print('Error: ${response.friendlyError}');
      print('======================');

      setState(() => _isLoading = false);

      if (response.success) {
        _showSuccessSnackBar('Edificio actualizado correctamente');

        // Limpiar imágenes seleccionadas
        _selectedFotoEdificio = null;
        _selectedGraficoEdificio = null;

        if (response.buildings != null && response.buildings!.isNotEmpty) {
          setState(() {
            _edificios = response.buildings!;
            _filteredEdificios = _edificios;
          });
          _onSearchChanged();
        } else {
          await _getEdificios();
        }
      } else {
        _showErrorSnackBar(response.friendlyError);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error inesperado: $e');
    }
  }

  // MÉTODOS DE UI HELPERS
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarDialogoConfirmacion(int idEdificio, String nombreEdificio) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Está seguro que quiere eliminar el registro "$nombreEdificio"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                _eliminarEdificio(idEdificio); // Eliminar registro
              },
              child: const Text('Aceptar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoEdicion(BuildingData edificio) {
    // IMPORTANTE: Guardar el edificio completo para mantener otros datos
    _edificioEnEdicion = edificio;

    // Limpiar imágenes seleccionadas anteriores
    _selectedFotoEdificio = null;
    _selectedGraficoEdificio = null;

    // Llenar los controladores con los datos actuales del edificio
    _nombreController.text = edificio.nombreEdificio;
    _direccionController.text = edificio.direccion ?? '';
    _inspectorController.text = edificio.inspector ?? '';
    _edificioIdEnEdicion = edificio.idEdificio;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Edificio'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Edificio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _inspectorController,
                      decoration: const InputDecoration(
                        labelText: 'Inspector',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SECCIÓN DE FOTO DEL EDIFICIO
                    _buildImageSection(
                      title: 'Foto del Edificio',
                      currentImageUrl: edificio.fotoUrl,
                      selectedImage: _selectedFotoEdificio,
                      onImageSelected: (File? image) {
                        setState(() {
                          _selectedFotoEdificio = image;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // SECCIÓN DE GRÁFICO/PLANO DEL EDIFICIO
                    _buildImageSection(
                      title: 'Gráfico/Plano del Edificio',
                      currentImageUrl: edificio.graficoUrl,
                      selectedImage: _selectedGraficoEdificio,
                      onImageSelected: (File? image) {
                        setState(() {
                          _selectedGraficoEdificio = image;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _selectedFotoEdificio = null;
                    _selectedGraficoEdificio = null;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).pop();
                    _actualizarEdificioConImagenes();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Guardar Cambios'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Widget helper para las secciones de imagen
  Widget _buildImageSection({
    required String title,
    String? currentImageUrl,
    File? selectedImage,
    required Function(File?) onImageSelected,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          // Mostrar imagen actual o nueva
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                selectedImage,
                fit: BoxFit.cover,
              ),
            )
                : (currentImageUrl != null && currentImageUrl.isNotEmpty)
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                currentImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: Colors.grey.shade500,
                  );
                },
              ),
            )
                : Icon(
              Icons.add_photo_alternate,
              size: 40,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),

          // Botones para cambiar imagen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    onImageSelected(File(image.path));
                  }
                },
                icon: Icon(Icons.camera_alt, size: 16),
                label: Text('Cámara', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: () async {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    onImageSelected(File(image.path));
                  }
                },
                icon: Icon(Icons.photo_library, size: 16),
                label: Text('Galería', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          if (selectedImage != null)
            TextButton.icon(
              onPressed: () {
                onImageSelected(null);
              },
              icon: Icon(Icons.clear, size: 16, color: Colors.red),
              label: Text(
                'Mantener imagen actual',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getEdificios(); // Reemplaza _futureEdificios = _getEdificios();
    _getUserName();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEdificios = _edificios.where((edificio) {
        final nombre = edificio.displayName.toLowerCase();
        final inspector = edificio.displayInspector.toLowerCase();
        return nombre.contains(query) || inspector.contains(query);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // CORRECCIÓN: Usar AppBar en lugar de manejo manual de SafeArea
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false, // Desactivar flecha automática
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.text),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const Text(
              "Edificios Registrados",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        titleSpacing: 0, // Eliminar espaciado extra
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensaje "Hola, usuario"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Hola, $_userName",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ),

          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por nombre de edificio o inspector...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),

          // Botón Nuevo registro +
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/buildingRegistry1');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Nuevo registro +",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Lista de edificios - EXPANDIDO PARA USAR TODO EL ESPACIO DISPONIBLE
          Expanded(
            child: _buildBuildingsList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

// WIDGET OPTIMIZADO PARA LA LISTA DE EDIFICIOS
  Widget _buildBuildingsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Cargando edificios...",
              style: TextStyle(color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getEdificios,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text("Reintentar", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredEdificios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apartment,
                size: 48,
                color: AppColors.gray500,
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.trim().isNotEmpty
                    ? "No se encontraron edificios con esos criterios"
                    : "No hay edificios registrados",
                style: const TextStyle(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
              if (_searchController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                  child: const Text("Limpiar búsqueda"),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _getEdificios,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredEdificios.length,
        itemBuilder: (context, index) {
          final edificio = _filteredEdificios[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto del edificio
                  _buildBuildingImage(edificio),
                  const SizedBox(width: 12),
                  // Información del edificio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edificio.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          edificio.displayDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Inspector: ${edificio.displayInspector}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          edificio.displayAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Iconos de acciones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Icono Editar
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: _isLoading ? null : () {
                                _mostrarDialogoEdicion(edificio);
                              },
                              color: AppColors.primary,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            // Icono PDF
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, size: 20),
                              onPressed: () {
                                // Aquí va la lógica para generar PDF
                                print('Generar PDF para: ${edificio.idEdificio}');
                              },
                              color: Colors.red,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            // Icono Borrar
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: _isLoading ? null : () {
                                _mostrarDialogoConfirmacion(
                                  edificio.idEdificio,
                                  edificio.displayName,
                                );
                              },
                              color: Colors.red,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // WIDGET PARA MOSTRAR LA IMAGEN DEL EDIFICIO
  Widget _buildBuildingImage(BuildingData edificio) {
    // DEBUGGING: Verificar qué datos llegan
    print('=== DEBUG IMAGE ===');
    print('Edificio ID: ${edificio.idEdificio}');
    print('Nombre: ${edificio.nombreEdificio}');
    print('fotoUrl raw: ${edificio.fotoUrl}');
    print('hasPhoto: ${edificio.hasPhoto}');
    print('===================');

    if (edificio.hasPhoto && edificio.fotoUrl != null) {
      final imageUrl = edificio.fotoUrl!;

      print('Intentando cargar imagen: $imageUrl');

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          height: 100,
          width: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('ERROR cargando imagen: $error');
            print('URL que falló: $imageUrl');
            return Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.gray500.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_not_supported,
                    color: Colors.red,
                    size: 30,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Error',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('Imagen cargada exitosamente: $imageUrl');
              return child;
            }

            return Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.gray500.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.gray500.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray500, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.apartment,
              color: AppColors.gray500,
              size: 30,
            ),
            const SizedBox(height: 4),
            Text(
              'Sin foto',
              style: TextStyle(
                color: AppColors.gray500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _inspectorController.dispose();
    super.dispose();
  }
}