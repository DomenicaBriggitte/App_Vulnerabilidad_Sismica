import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'buildings_page.dart'; // Importa tu pantalla aquí
import 'profile_page.dart';
import 'assessed_buildings_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SismosApp'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hola, Usuario',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuOption(
                  context,
                  'Edificios registrados',
                  'https://cdn-icons-png.flaticon.com/512/1441/1441359.png',
                      () {
                    // Navegar a building_registry_1_screen.dart sin ruta nombrada
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuildingsPage(),
                      ),
                    );
                  },
                ),
                _buildMenuOption(
                  context,
                  'Edificios evaluados',
                  'https://cdn-icons-png.flaticon.com/128/12218/12218407.png',
                      () {
                    // Si quieres puedes dejar Navigator.pushNamed aquí
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AssessedBuildingsPage(),
                          ),
                        );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                // Ya estamos en home
              },
              color: AppColors.primary,
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
      BuildContext context, String title, String imageUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.network(imageUrl, width: 80, height: 80),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
