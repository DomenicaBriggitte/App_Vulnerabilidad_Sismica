import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ui/screens/login_screen.dart';
import '../core/theme/app_theme.dart'; // 👈 Importar AppTheme

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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const LoginScreen(),
    );
  }
}
