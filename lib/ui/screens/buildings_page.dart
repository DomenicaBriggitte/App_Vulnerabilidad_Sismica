import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BuildingsPage extends StatefulWidget {
  const BuildingsPage({super.key});

  @override
  State<BuildingsPage> createState() => _BuildingsPageState();
}

class _BuildingsPageState extends State<BuildingsPage> {
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
            const Text('Edificios registrados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(thickness: 1, height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const Divider(thickness: 1, height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Número de edificios de ejemplo
                itemBuilder: (context, index) {
                  return _buildBuildingCard('Edificio ${index + 1}',
                      'Dirección del edificio ${index + 1}');
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegación a la pantalla de registro
          Navigator.pushNamed(context, '/register-building');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Registrar nuevo edificio', style: TextStyle(color: Colors.white)),
        tooltip: 'Registrar nuevo edificio',
        hoverColor: AppColors.primary.withOpacity(0.8),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingCard(String name, String address) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(address),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}