import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import '../../services/neon_db/admin_db_service.dart';

// Importa las nuevas vistas
import 'views/usuarios_view.dart';
import 'views/preguntas_view.dart';
import 'views/modelo_ia_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  void _cerrarSesion() async {
    await AdminDbService.cerrarSesion();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9);

    final List<Widget> pantallas = [
      UsuariosView(isDarkMode: isDarkMode),
      PreguntasView(isDarkMode: isDarkMode),
      ModeloIAView(isDarkMode: isDarkMode),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF222232) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("EduPlay Admin",
            style: GoogleFonts.fredoka(
                fontWeight: FontWeight.bold, color: const Color(0xFF48CAE4))),
        actions: [
          IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFFF6B6B)),
              onPressed: _cerrarSesion)
        ],
      ),
      body: pantallas[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? const Color(0xFF222232) : Colors.white,
        selectedItemColor: const Color(0xFF48CAE4),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Usuarios"),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: "Preguntas"),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: "Modelo IA"),
        ],
      ),
    );
  }
}