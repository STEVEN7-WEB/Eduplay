import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

void main() {
  // Esta línea es necesaria si luego agregamos plugins como shared_preferences
  WidgetsFlutterBinding.ensureInitialized(); 
  
  runApp(const EduplayApp());
}

class EduplayApp extends StatelessWidget {
  const EduplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eduplay 2.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Si descargas una fuente como 'Fredoka One' o 'Nunito', ponla aquí
        fontFamily: 'ComicSans', 
        primarySwatch: Colors.blue,
      ),
      // Apunta directamente a tu carpeta de auth
      home: const LoginScreen(), 
    );
  }
}