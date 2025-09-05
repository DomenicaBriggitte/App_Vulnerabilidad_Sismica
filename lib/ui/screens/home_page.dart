import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'buildings_screen.dart';
import 'assessed_buildings_screen.dart';
import 'profile_admin_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Recibimos los argumentos pasados desde login_screen
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final userId = args?['userId'];
    final userName = args?['userName'] ?? 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SismosApp'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Cerrar sesión y volver al login
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $userName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuOption(
                  context,
                  'Edificios registrados',
                  'https://cdn-icons-png.flaticon.com/512/1441/1441359.png',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuildingsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuOption(
                  context,
                  'Edificios evaluados',
                  'https://cdn-icons-png.flaticon.com/128/12218/12218407.png',
                      () {
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
        color: AppColors.gray300,
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
                // Navegar a perfil con userId
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileAdminScreen(userId: userId),
                    ),
                  );
                }
              },
              color: AppColors.text,
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
