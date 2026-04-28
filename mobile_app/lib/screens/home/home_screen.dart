import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/test_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Estudiante';
  String _userId = '';
  String _avatarInitial = 'U';

  @override
  void initState() {
    super.initState();
    _cargarSesion();
  }

  void _cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Estudiante';
      _userId = prefs.getString('userId') ?? '0';
      // Antes: _userName.charAt(0)
      _avatarInitial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
    });
  }

  void _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Borra todo
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Fondo Deep Dark
      body: SafeArea(
        child: Column(
          children: [
            // --- CABECERA DE PERFIL (Estilo Web Dropdown) ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text("EduPlay", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Avatar circular con acento cian
                  Container(
                    width: 45, height: 45,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent, width: 2),
                    ),
                    child: Center(
                      child: Text(_avatarInitial, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(_userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: _cerrarSesion, icon: const Icon(Icons.exit_to_app, color: Colors.pinkAccent)),
                ],
              ),
            ),

            // --- TÍTULO PRINCIPAL ---
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "🎮 Elige tu actividad",
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
              ),
            ),

            // --- GRILLA DE ACTIVIDADES (Estilo Web Cards) ---
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // 2 columnas en móvil
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                padding: const EdgeInsets.all(20),
                children: [
                  _buildActivityCard(context, 'math', 'Matemáticas', '🔢'),
                  _buildActivityCard(context, 'memory', 'Memoria', '🧠'),
                  _buildActivityCard(context, 'logic', 'Lógica', '🧩'),
                  _buildActivityCard(context, 'grammar', 'Gramática', '✍️'),
                  _buildActivityCard(context, 'english', 'Inglés', '🗣️'),
                  _buildActivityCard(context, 'geography', 'Geografía', '🌎'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, String subjectKey, String title, String emoji) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TestScreen(subject: subjectKey)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B263B), // Fondo de tarjeta
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF334155)), // Borde sutil
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}