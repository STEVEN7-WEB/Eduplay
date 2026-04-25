import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/neon_db_service.dart';
import '../auth/login_screen.dart';
import '../game/test_screen.dart'; // <-- Importamos la pantalla de juego

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('EDUPLAY 2.0', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.pinkAccent),
            onPressed: () async {
              await NeonDbService.cerrarSesion();
              if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _buildCard(context, 'MATEMÁTICAS', Icons.calculate, Colors.cyanAccent),
            _buildCard(context, 'ESPAÑOL', Icons.abc, Colors.yellowAccent),
            _buildCard(context, 'CIENCIAS', Icons.science, Colors.greenAccent),
            _buildCard(context, 'GEOGRAFÍA', Icons.public, Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () async {
            // SACAMOS EL GRADO DEL NIÑO Y NAVEGAMOS
            final prefs = await SharedPreferences.getInstance();
            int grado = prefs.getInt('grado_usuario') ?? 1;
            
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TestScreen(materia: title, gradoUsuario: grado, accentColor: accentColor)),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: accentColor),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}