import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/forgot_password_screen.dart';
import 'ui/screens/register_screen.dart';
import 'ui/screens/recovery_password.dart';
import 'ui/screens/profile_page.dart';
import 'ui/screens/home_page.dart';
import 'ui/screens/buildings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://tkvjsanpnzmutlnmcued.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrdmpzYW5wbnptdXRsbm1jdWVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU4OTg4NjcsImV4cCI6MjA3MTQ3NDg2N30.uAS-I3xmiqa1btUq01wXQUSUdpBUa0gjsfYJjJbtw0I',
  );

  runApp(const SismosApp());
}

class SismosApp extends StatelessWidget {
  const SismosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SismosApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/recovery': (context) => const RecoveryPasswordScreen(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/buildings': (context) => const BuildingsPage(),
      },
    );
  }
}
