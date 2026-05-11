import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // Importa para poder regresar al login al cerrar sesión

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E1E2E);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Panel de Tutor", 
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: textColor)
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.query_stats_rounded, size: 80, color: const Color(0xFF48CAE4)),
              const SizedBox(height: 20),
              Text(
                "¡Bienvenido al seguimiento de misiones!",
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 15),
              Text(
                "Próximamente aquí verás el progreso, las materias destacadas y las estadísticas de tu explorador.",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  // Limpiar preferencias y volver a Login
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => const LoginScreen()), 
                      (route) => false
                    );
                  }
                }, 
                icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
                label: Text("Cerrar Sesión", style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
              )
            ],
          ),
        ),
      ),
    );
  }
}