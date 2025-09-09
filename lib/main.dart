import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'core/theme/app_theme.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/forgot_password_screen.dart';
import 'ui/screens/register_screen.dart';
import 'ui/screens/recovery_password.dart';
=======
import 'package:flutter_application_1/ui/screens/home_admin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ui/screens/assessed_buildings_screen.dart';
import '../../ui/screens/assign_role_screen.dart';
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
import '../../ui/screens/user_list_screen.dart';
>>>>>>> Stashed changes

void main() {
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
      initialRoute: '/', // 👈 Pantalla inicial
      routes: {
        '/': (_) => const LoginScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),
<<<<<<< Updated upstream
=======
        '/home': (context) => const HomePage(),
        '/homeAdmin': (context) => const HomeAdminScreen(),
        '/profileAdmin': (_) => const ProfileAdminScreen(),
        '/profile': (_) => const ProfilePage(),
>>>>>>> Stashed changes
        '/register': (context) => const RegisterScreen(),
        '/recovery': (context) => const RecoveryPasswordScreen(),
      },
    );
  }
}
