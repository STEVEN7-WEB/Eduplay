import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'services/neon_db/auth_db_service.dart';
import 'services/notification_service.dart'; // Importa tu servicio

// --- NOTIFICADOR GLOBAL DE TEMA ---
// Esta variable la podrá ver cualquier pantalla de tu app
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  // Preparamos el motor de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Servicio de notificaciones: inicializamos y pedimos permisos 
  await NotificationService.inicializar();
  // Revisamos si hay una sesión guardada y el tema preferido
  final prefs = await SharedPreferences.getInstance();
  final bool yaInicioSesion = prefs.getBool('sesion_iniciada') ?? false;
  final bool esModoOscuro = prefs.getBool('isDarkMode') ?? true; // Por defecto oscuro

  // Configuramos el notificador antes de arrancar la app
  themeNotifier.value = esModoOscuro ? ThemeMode.dark : ThemeMode.light;

  // Arrancamos la app
  runApp(EduplayApp(iniciarDirecto: yaInicioSesion));
}

class EduplayApp extends StatelessWidget {
  final bool iniciarDirecto;

  const EduplayApp({super.key, required this.iniciarDirecto}); 

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder "escucha" los cambios en themeNotifier
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'EduPlay 2.0',
          debugShowCheckedModeBanner: false,
          
          // --- CONFIGURACIÓN GLOBAL MODO CLARO ---
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F6F9),
            primaryColor: const Color(0xFF0096C7),
          ),
          
          // --- CONFIGURACIÓN GLOBAL MODO OSCURO ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF151522),
            primaryColor: const Color(0xFF48CAE4),
          ),
          
          // Le decimos a Flutter que use el modo del notificador
          themeMode: currentMode,
          
          home: SplashScreen(
            destino: iniciarDirecto ? const HomeScreen() : const LoginScreen(),
          ), 
        );
      },
    );
  }
}