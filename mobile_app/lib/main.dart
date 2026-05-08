import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/splash_screen.dart'; // Importamos el Splash
import 'services/neon_db_service.dart';

void main() async {
  // Preparamos el motor de Flutter
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Revisamos si hay una sesión guardada en el celular
  final prefs = await SharedPreferences.getInstance();
  final bool yaInicioSesion = prefs.getBool('sesion_iniciada') ?? false;

  // Arrancamos la app
  runApp(EduplayApp(iniciarDirecto: yaInicioSesion));
}

class EduplayApp extends StatelessWidget {
  final bool iniciarDirecto;

  const EduplayApp({super.key, required this.iniciarDirecto}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduPlay 2.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // En lugar de ir directo a Home/Login, vamos al Splash Screen primero.
      // Le decimos al Splash a qué pantalla ir cuando termine de cargar.
      home: SplashScreen(
        destino: iniciarDirecto ? const HomeScreen() : const LoginScreen(),
      ), 
    );
  }
}