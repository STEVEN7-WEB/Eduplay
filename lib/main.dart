import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart'; // 
import 'services/neon_db_service.dart';

void main() async {
  //Preparamos el motor de Flutter
  WidgetsFlutterBinding.ensureInitialized(); 
  
  //Revisamos si hay una sesión guardada en el celular
  final prefs = await SharedPreferences.getInstance();
  final bool yaInicioSesion = prefs.getBool('sesion_iniciada') ?? false;

  //Arrancamos la app pasando el dato de la sesión
  runApp(EduplayApp(iniciarDirecto: yaInicioSesion));
}

class EduplayApp extends StatelessWidget {
  final bool iniciarDirecto;

  const EduplayApp({super.key, required this.iniciarDirecto}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eduplay 2.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'ComicSans',
      ),
      home: iniciarDirecto ? const HomeScreen() : const LoginScreen(), 
    );
  }
}