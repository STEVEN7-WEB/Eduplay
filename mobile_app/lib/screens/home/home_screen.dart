import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart'; 
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
  String _userAvatar = 'assets/avatars/avatar1.png';
  bool _isDarkMode = true;

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
      _userAvatar = prefs.getString('userAvatar') ?? 'assets/avatars/avatar1.png';
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  void _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    themeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    // Paleta dinámica con énfasis en el neón para modo oscuro
    final bgColor = _isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final cardColor = _isDarkMode ? const Color(0xFF222232) : Colors.white;
    final primaryTextColor = _isDarkMode ? Colors.white : const Color(0xFF1E1E2E);
    final secondaryTextColor = _isDarkMode ? Colors.white54 : Colors.black54;
    final borderColor = _isDarkMode ? const Color(0xFF333344) : Colors.grey.shade300;
    final titleNeonColor = _isDarkMode ? const Color(0xFF48CAE4) : const Color(0xFF0096C7);

    // Lista de misiones para generar la grilla dinámicamente
    final misiones = [
      {'key': 'math', 'title': 'Matemáticas', 'emoji': '🔢', 'color': const Color(0xFFFF6B6B)},
      {'key': 'memory', 'title': 'Memoria', 'emoji': '🧠', 'color': const Color(0xFF4ECDC4)},
      {'key': 'logic', 'title': 'Lógica', 'emoji': '🧩', 'color': const Color(0xFFA0D468)},
      {'key': 'grammar', 'title': 'Gramática', 'emoji': '✍️', 'color': const Color(0xFF9D4EDD)},
      {'key': 'english', 'title': 'Inglés', 'emoji': '🗣️', 'color': const Color(0xFF48CAE4)},
      {'key': 'geography', 'title': 'Geografía', 'emoji': '🌎', 'color': const Color(0xFFFF9F43)},
      {'key': 'art', 'title': 'Arte', 'emoji': '🎨', 'color': const Color(0xFFFF66C4)},
      {'key': 'science', 'title': 'Ciencia', 'emoji': '🔬', 'color': const Color(0xFF5E60CE)},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: TweenAnimationBuilder(
        // Animación de entrada para el Dock flotante (Sube desde abajo)
        tween: Tween<double>(begin: 50, end: 0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),
            child: Opacity(
              opacity: (1 - (value / 50)).clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: _buildFloatingDock(cardColor, borderColor),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CABECERA DE PERFIL ANIMADA ---
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) => Opacity(opacity: value, child: child),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "¡Hola,",
                          style: GoogleFonts.nunito(color: secondaryTextColor, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Row(
                          children: [
                            Text(
                              "$_userName! ",
                              style: GoogleFonts.fredoka(color: primaryTextColor, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const Text("👋", style: TextStyle(fontSize: 22)),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildTopIcon(
                      icon: _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: _isDarkMode ? const Color(0xFFFFD93D) : const Color(0xFF5E60CE),
                      cardColor: cardColor,
                      onTap: _toggleTheme,
                    ),
                    const SizedBox(width: 8),
                    _buildTopIcon(
                      icon: Icons.logout_rounded,
                      color: const Color(0xFFFF6B6B),
                      cardColor: cardColor,
                      onTap: _cerrarSesion,
                    ),
                    const SizedBox(width: 12),
                    // Avatar con leve resplandor
                    Container(
                      width: 55, height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF9D4EDD), width: 2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(_isDarkMode ? 0.6 : 0.2), blurRadius: 15, offset: const Offset(0, 4))
                        ]
                      ),
                      child: CircleAvatar(
                        backgroundColor: cardColor,
                        backgroundImage: AssetImage(_userAvatar),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- TÍTULO PRINCIPAL ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text(
                "¿Qué misión haremos hoy?",
                style: GoogleFonts.fredoka(color: titleNeonColor, fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),

            // --- GRILLA DE ACTIVIDADES CON ANIMACIÓN ESCALONADA ---
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 110),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.9,
                ),
                itemCount: misiones.length,
                itemBuilder: (context, index) {
                  final mision = misiones[index];
                  return TweenAnimationBuilder(
                    // Retraso dinámico basado en el índice para efecto cascada
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    curve: Curves.easeOutBack,
                    builder: (context, scaleValue, child) {
                      return Transform.scale(
                        scale: scaleValue,
                        child: child,
                      );
                    },
                    child: _BouncingActivityCard(
                      subjectKey: mision['key'] as String,
                      title: mision['title'] as String,
                      emoji: mision['emoji'] as String,
                      accentColor: mision['color'] as Color,
                      cardColor: cardColor,
                      textColor: primaryTextColor,
                      isDarkMode: _isDarkMode,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Refactor de los botones superiores
  Widget _buildTopIcon({required IconData icon, required Color color, required Color cardColor, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: IconButton(
        onPressed: onTap, 
        icon: Icon(icon, color: color, size: 22)
      ),
    );
  }

  Widget _buildFloatingDock(Color cardColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: borderColor, width: 2), 
        boxShadow: [
          BoxShadow(
            color: _isDarkMode ? Colors.black87 : Colors.black.withOpacity(0.1), 
            blurRadius: 25, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDockAction(Icons.emoji_events_rounded, "Logros", const Color(0xFFFFD93D), () {
            _mostrarModal("Tus Logros 🏆", "¡Sigue así, $_userName! Has completado 5 misiones esta semana.", const Color(0xFFFFD93D));
          }),
          _buildDockAction(Icons.trending_up_rounded, "Avance", const Color(0xFF4ECDC4), () {
            _mostrarModal("Tu Avance 📈", "Tu materia más fuerte es Matemáticas. ¡Tu cerebro se está haciendo poderoso!", const Color(0xFF4ECDC4));
          }),
          _buildDockAction(Icons.stars_rounded, "Metas", const Color(0xFF9D4EDD), () {
            _mostrarModal("Nuevas Metas 🚀", "Meta del día: Completa 1 misión de Ciencia para ganar una insignia.", const Color(0xFF9D4EDD));
          }),
        ],
      ),
    );
  }

  Widget _buildDockAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
    // ... Tu código actual de _mostrarModal se mantiene exactamente igual ...
    // (Lo omito para no saturar, pero mantén el que ya tenías)
  }
}

// --- NUEVO WIDGET: TARJETA CON EFECTO REBOTE ---
class _BouncingActivityCard extends StatefulWidget {
  final String subjectKey;
  final String title;
  final String emoji;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final bool isDarkMode;

  const _BouncingActivityCard({
    required this.subjectKey,
    required this.title,
    required this.emoji,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.isDarkMode,
  });

  @override
  State<_BouncingActivityCard> createState() => _BouncingActivityCardState();
}

class _BouncingActivityCardState extends State<_BouncingActivityCard> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.93); // Se encoge ligeramente al presionar
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0); // Vuelve a su tamaño
    // Navegamos con un ligero retraso para permitir que termine la animación visual
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TestScreen(subject: widget.subjectKey)),
        );
      }
    });
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100), // Velocidad del rebote
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: widget.accentColor.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                // Mayor intensidad de resplandor en modo oscuro
                color: widget.accentColor.withOpacity(widget.isDarkMode ? 0.25 : 0.08),
                blurRadius: widget.isDarkMode ? 20 : 15, 
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
                  color: widget.accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(widget.emoji, style: const TextStyle(fontSize: 35)),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}