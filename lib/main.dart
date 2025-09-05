import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';
import '../../ui/screens/assessed_buildings_screen.dart';
import '../../ui/screens/building_registry_1_screen.dart ';
import '../../ui/screens/building_registry_2_screen.dart';
import '../../ui/screens/building_registry_3_screen.dart';
import '../../ui/screens/building_registry_4_screen.dart';
import '../../ui/screens/buildings_screen.dart';
import '../../ui/screens/exten_revis.dart';
import '../../ui/screens/forgot_password_screen.dart';
import '../../ui/screens/home_page.dart';
import '../../ui/screens/login_screen.dart';
import '../../ui/screens/profile_admin_screen.dart';
import '../../ui/screens/profile_page.dart';
import '../../ui/screens/recovery_password.dart';
import '../../ui/screens/register_screen.dart';

void main() async {
  await Supabase.initialize(
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrdmpzYW5wbnptdXRsbm1jdWVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU4OTg4NjcsImV4cCI6MjA3MTQ3NDg2N30.uAS-I3xmiqa1btUq01wXQUSUdpBUa0gjsfYJjJbtw0I",
    url: "https://tkvjsanpnzmutlnmcued.supabase.co",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SismosApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/', // 👈 Pantalla inicial
      routes: {
        '/': (_) => const LoginScreen(),
        '/assessed': (_) => const AssessedBuildingsPage(),
        '/buildingRegistry1': (_) => const BuildingRegistry1Screen(),
        '/buildingRegistry2': (_) => const BuildingRegistry2Screen(),
        '/buildingRegistry3': (_) => const BuildingRegistry3Screen(),
        '/buildingRegistry4': (_) => const BuildingRegistry4Screen(),
        '/building': (_) => const BuildingsScreen(),
        '/exten': (_) => const ExtensionRevisionPage(),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/home': (context) => const HomePage(),
        '/profileAdmin': (_) => const ProfileAdminScreen(),
        '/profile': (_) => const ProfilePage(),
        '/register': (context) => const RegisterScreen(),
        '/recovery': (context) => const RecoveryPasswordScreen(),

      },
    );
  }
}
