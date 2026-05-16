import 'dart:ui';
import 'dart:math' as math; // <-- Necesario para la animación flotante
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart'; 
import '../game/test_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_settings_screen.dart';
import '../../services/neon_db_service.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Variables que se llenarán con la base de datos
  String _userName = 'Estudiante'; 
  String _userId = '';
  String _userAvatar = 'assets/avatars/avatar1.png'; 
  bool _isDarkMode = true;
  
  int _misionesCompletadas = 0;
  String _materiaFuerte = "";
  
  bool _isLoading = true;

  // Controladores de animación para el fondo y las tarjetas flotantes
  late AnimationController _mainAnimController;
  late Animation<double> _bgFloatAnimation;

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeBD();

    // Controlador principal que durará 4 segundos y se repetirá en bucle
    _mainAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    
    // Animación suave para las luces de fondo
    _bgFloatAnimation = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _mainAnimController, curve: Curves.easeInOutSine)
    );
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    super.dispose();
  }

  void _cargarDatosDesdeBD() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userIdInt = prefs.getInt('id_usuario'); 
    
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;

    if (userIdInt != null) {
      _userId = userIdInt.toString();
      
      // 1. Extraemos el Perfil Principal (name, avatar)
      final perfilData = await NeonDbService.obtenerPerfilUsuario(userIdInt);
      
      // 2. Extraemos el resumen (misiones, materia top)
      final resumen = await NeonDbService.obtenerResumenActividad(userIdInt);

      if (mounted) {
        setState(() {
          if (perfilData != null) {
            _userName = perfilData['name'] ?? 'Estudiante'; 
            _userAvatar = perfilData['avatar'] ?? 'assets/avatars/avatar1.png'; 
          }
          if (resumen != null) {
            _misionesCompletadas = resumen['total_misiones'] ?? 0;
            _materiaFuerte = resumen['materia_top'] ?? "";
          }
          _isLoading = false;
        });
      }
    } else {
      _cerrarSesion();
    }
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
    final bgColor = _isDarkMode ? const Color(0xFF0D0D1A) : const Color(0xFFF4F6F9);
    final cardColor = _isDarkMode ? const Color(0xFF222232) : Colors.white;
    final primaryTextColor = _isDarkMode ? Colors.white : const Color(0xFF1E1E2E);
    final secondaryTextColor = _isDarkMode ? Colors.white54 : Colors.black54;
    final borderColor = _isDarkMode ? const Color(0xFF333344) : Colors.grey.shade300;
    final titleNeonColor = _isDarkMode ? const Color(0xFF48CAE4) : const Color(0xFF0096C7);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: titleNeonColor)),
      );
    }

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
        tween: Tween<double>(begin: 50, end: 0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),
            child: Opacity(opacity: (1 - (value / 50)).clamp(0.0, 1.0), child: child),
          );
        },
        child: _buildFloatingDock(cardColor, borderColor),
      ),
      body: Stack(
        children: [
          // --- FONDOS DE NEÓN ANIMADOS ---
          AnimatedBuilder(
            animation: _mainAnimController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -50 + _bgFloatAnimation.value, left: -100,
                    child: Container(
                      width: 300, height: 300,
                      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF48CAE4).withOpacity(_isDarkMode ? 0.2 : 0.1), blurRadius: 120)]),
                    ),
                  ),
                  Positioned(
                    bottom: 100 - _bgFloatAnimation.value, right: -100,
                    child: Container(
                      width: 350, height: 350,
                      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(_isDarkMode ? 0.2 : 0.1), blurRadius: 150)]),
                    ),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CABECERA DE PERFIL ---
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
                              "¡Misión iniciada,",
                              style: GoogleFonts.nunito(color: secondaryTextColor, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            Row(
                              children: [
                                Text(
                                  "$_userName! ",
                                  style: GoogleFonts.fredoka(color: primaryTextColor, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const Text("🚀", style: TextStyle(fontSize: 22)),
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
                        
                        // --- AVATAR ANIMADO ---
                        AnimatedBuilder(
                          animation: _mainAnimController,
                          builder: (context, child) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
                                ).then((_) => _cargarDatosDesdeBD()); 
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                width: 55, height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF9D4EDD), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9D4EDD).withOpacity((_isDarkMode ? 0.6 : 0.3) * _mainAnimController.value), 
                                      blurRadius: 15, 
                                      spreadRadius: 2
                                    )
                                  ]
                                ),
                                child: CircleAvatar(
                                  backgroundColor: cardColor,
                                  backgroundImage: AssetImage(_userAvatar),
                                ),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Text(
                    "Elige tu destino espacial ✨",
                    style: GoogleFonts.fredoka(color: titleNeonColor, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                
                // --- CUADRÍCULA DE MISIONES FLOTANTES ---
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 110),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: 1.15, // <-- MÁS CORTOS (antes 0.9)
                    ),
                    itemCount: misiones.length,
                    itemBuilder: (context, index) {
                      final mision = misiones[index];
                      
                      return AnimatedBuilder(
                        animation: _mainAnimController,
                        builder: (context, child) {
                          // Matemáticas mágicas para que cada tarjeta flote a distinto ritmo
                          final delay = index * 0.5;
                          final floatOffset = math.sin((_mainAnimController.value * math.pi * 2) + delay) * 6.0;

                          return Transform.translate(
                            offset: Offset(0, floatOffset),
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 400 + (index * 100)),
                              curve: Curves.easeOutBack,
                              builder: (context, scaleValue, child) {
                                return Transform.scale(scale: scaleValue, child: child);
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
                            ),
                          );
                        }
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcon({required IconData icon, required Color color, required Color cardColor, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: IconButton(onPressed: onTap, icon: Icon(icon, color: color, size: 22)),
        ),
      ),
    );
  }

  Widget _buildFloatingDock(Color cardColor, Color borderColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 25),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(_isDarkMode ? 0.7 : 0.9),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: borderColor.withOpacity(0.5), width: 2), 
            boxShadow: [
              BoxShadow(color: _isDarkMode ? Colors.black87 : Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockAction(Icons.emoji_events_rounded, "Logros", const Color(0xFFFFD93D), () {
                String msg = _misionesCompletadas == 0 
                    ? "¡Empecemos la aventura hoy! Aún no tienes logros." 
                    : "¡Sigue así, $_userName! Has completado $_misionesCompletadas misiones.";
                _mostrarModal("Tus Logros 🏆", msg, const Color(0xFFFFD93D));
              }),
              _buildDockAction(Icons.trending_up_rounded, "Avance", const Color(0xFF4ECDC4), () {
                String msg = _materiaFuerte.isEmpty
                    ? "Aún no has empezado. ¡Juega un poco para descubrir tu materia más fuerte!" 
                    : "Tu materia más fuerte es $_materiaFuerte. ¡Tu cerebro se está haciendo poderoso!";
                _mostrarModal("Tu Avance 📈", msg, const Color(0xFF4ECDC4));
              }),
              _buildDockAction(Icons.stars_rounded, "Metas", const Color(0xFF9D4EDD), () {
                List<String> metasDiarias = [
                  "Lunes: Completa 1 misión de Matemáticas para calentar motores. 🔢",
                  "Martes: Gana 3 estrellas en Inglés. 🗣️",
                  "Miércoles: Explora el mundo en Geografía. 🌎",
                  "Jueves: Pon a prueba tu Lógica hoy. 🧩",
                  "Viernes: Conviértete en científico completando un examen. 🔬",
                  "Sábado: Día de repasar Memoria. 🧠",
                  "Domingo: ¡Rompe tu propio récord! 🚀"
                ];
                int diaActual = DateTime.now().weekday - 1; 
                _mostrarModal("Nuevas Metas 🚀", metasDiarias[diaActual], const Color(0xFF9D4EDD));
              }),
            ],
          ),
        ),
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
    final modalBgColor = _isDarkMode ? const Color(0xFF222232) : Colors.white;
    final modalTextColor = _isDarkMode ? Colors.white70 : Colors.black87;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: modalBgColor.withOpacity(0.9),
          elevation: 20,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: colorNeon.withOpacity(0.5), width: 2)),
          title: Text(titulo, textAlign: TextAlign.center, style: GoogleFonts.fredoka(color: colorNeon, fontSize: 24, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: colorNeon.withOpacity(0.15), shape: BoxShape.circle, boxShadow: [BoxShadow(color: colorNeon.withOpacity(0.2), blurRadius: 20)]),
                child: Icon(Icons.auto_awesome_rounded, size: 50, color: colorNeon),
              ),
              const SizedBox(height: 20),
              Text(mensaje, textAlign: TextAlign.center, style: GoogleFonts.nunito(color: modalTextColor, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorNeon, foregroundColor: const Color(0xFF151522), 
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
}

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

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.90);

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TestScreen(subject: widget.subjectKey)),
        );
      }
    });
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            // --- DEGRADADO ESTILO GEMA/CRISTAL ---
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.cardColor.withOpacity(widget.isDarkMode ? 0.8 : 1.0),
                widget.accentColor.withOpacity(widget.isDarkMode ? 0.2 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(40), // <-- MÁS REDONDOS (antes 25)
            border: Border.all(color: widget.accentColor.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(color: widget.accentColor.withOpacity(widget.isDarkMode ? 0.3 : 0.15), blurRadius: 20, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.15), 
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: widget.accentColor.withOpacity(0.3), blurRadius: 15)]
                ),
                child: Text(widget.emoji, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 17),
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