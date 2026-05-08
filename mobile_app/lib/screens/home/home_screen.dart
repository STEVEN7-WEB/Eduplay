import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // Se reemplaza la inicial por la ruta del avatar por defecto
  String _userAvatar = 'assets/avatars/avatar1.png';

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
      // Obtenemos la ruta del avatar guardada (o ponemos uno por defecto)
      _userAvatar = prefs.getString('userAvatar') ?? 'assets/avatars/avatar1.png';
    });
  }

  void _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151522),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingDock(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CABECERA DE PERFIL ---
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "¡Hola,",
                        style: GoogleFonts.nunito(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: [
                          Text(
                            "$_userName! ",
                            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const Text("👋", style: TextStyle(fontSize: 22)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Botón de salir
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF222232),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.5), width: 1.5),
                    ),
                    child: IconButton(
                      onPressed: _cerrarSesion, 
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 22)
                    ),
                  ),
                  const SizedBox(width: 12),
                  // --- AVATAR SELECCIONADO ---
                  Container(
                    width: 55, height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF9D4EDD), width: 2), // Borde morado para que combine
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4))
                      ]
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF222232),
                      backgroundImage: AssetImage(_userAvatar),
                    ),
                  ),
                ],
              ),
            ),

            // --- TÍTULO PRINCIPAL ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text(
                "¿Qué misión haremos hoy?",
                style: GoogleFonts.fredoka(color: const Color(0xFF48CAE4), fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),

            // --- GRILLA DE ACTIVIDADES ---
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, 
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 0.9,
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 110),
                physics: const BouncingScrollPhysics(), 
                children: [
                  _buildActivityCard(context, 'math', 'Matemáticas', '🔢', const Color(0xFFFF6B6B)), 
                  _buildActivityCard(context, 'memory', 'Memoria', '🧠', const Color(0xFF4ECDC4)), 
                  _buildActivityCard(context, 'logic', 'Lógica', '🧩', const Color(0xFFA0D468)),
                  _buildActivityCard(context, 'grammar', 'Gramática', '✍️', const Color(0xFF9D4EDD)), 
                  _buildActivityCard(context, 'english', 'Inglés', '🗣️', const Color(0xFF48CAE4)), 
                  _buildActivityCard(context, 'geography', 'Geografía', '🌎', const Color(0xFFFF9F43)), 
                  _buildActivityCard(context, 'art', 'Arte', '🎨', const Color(0xFFFF66C4)),
                  _buildActivityCard(context, 'science', 'Ciencia', '🔬', const Color(0xFF5E60CE)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DEL DOCK INFERIOR (Sin cambios) ---
  Widget _buildFloatingDock() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFF333344), width: 2), 
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDockAction(Icons.emoji_events_rounded, "Logros", const Color(0xFFFFD93D), () {
            _mostrarModal(
              "Tus Logros 🏆", 
              "¡Sigue así, $_userName! Has completado 5 misiones esta semana. ¡Eres un explorador estrella!", 
              const Color(0xFFFFD93D)
            );
          }),
          _buildDockAction(Icons.trending_up_rounded, "Avance", const Color(0xFF4ECDC4), () {
            _mostrarModal(
              "Tu Avance 📈", 
              "Tu materia más fuerte es Matemáticas. ¡Tu cerebro se está haciendo súper poderoso!", 
              const Color(0xFF4ECDC4)
            );
          }),
          _buildDockAction(Icons.stars_rounded, "Metas", const Color(0xFF9D4EDD), () {
            _mostrarModal(
              "Nuevas Metas 🚀", 
              "Meta del día: Completa 1 misión de Ciencia para ganar una insignia espacial.", 
              const Color(0xFF9D4EDD)
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDockAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.nunito(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _mostrarModal(String titulo, String mensaje, Color colorNeon) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222232),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), 
            side: BorderSide(color: colorNeon.withOpacity(0.5), width: 2)
          ),
          title: Text(
            titulo, 
            textAlign: TextAlign.center, 
            style: GoogleFonts.fredoka(color: colorNeon, fontSize: 24, fontWeight: FontWeight.bold)
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorNeon.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome_rounded, size: 50, color: colorNeon),
              ),
              const SizedBox(height: 20),
              Text(
                mensaje, 
                textAlign: TextAlign.center, 
                style: GoogleFonts.nunito(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorNeon, 
                foregroundColor: const Color(0xFF151522), 
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("¡Genial!", style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18)),
            )
          ],
        );
      }
    );
  }

  Widget _buildActivityCard(BuildContext context, String subjectKey, String title, String emoji, Color accentColor) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TestScreen(subject: subjectKey)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF222232),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 15, 
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 35)),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}