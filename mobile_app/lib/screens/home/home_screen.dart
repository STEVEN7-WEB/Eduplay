import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart'; 
import '../game/test_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_settings_screen.dart';
import 'achievements_screen.dart';
import '../../services/neon_db/user_db_service.dart'; 
import '../../services/neon_db/auth_db_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userName = 'Estudiante'; 
  String _userId = '';
  int _userIdInt = 0; 
  String _userAvatar = 'assets/avatars/avatar1.png'; 
  bool _isDarkMode = true;
  
  int _misionesCompletadas = 0;
  String _materiaFuerte = "";
  Map<String, int> _puntajesPorMateria = {}; 
  
  bool _isLoading = true;

  late AnimationController _mainAnimController;
  late Animation<double> _bgFloatAnimation;

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeBD();
    _mainAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bgFloatAnimation = Tween<double>(begin: -15.0, end: 15.0).animate(CurvedAnimation(parent: _mainAnimController, curve: Curves.easeInOutSine));
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
      _userIdInt = userIdInt;
      
      final perfilData = await UserDbService.obtenerPerfilUsuario(userIdInt);
      final resumen = await UserDbService.obtenerResumenActividad(userIdInt);

      if (mounted) {
        setState(() {
          if (perfilData != null) {
            _userName = perfilData['name'] ?? 'Estudiante'; 
            _userAvatar = perfilData['avatar'] ?? 'assets/avatars/avatar1.png'; 
          }
          if (resumen != null) {
            _misionesCompletadas = resumen['total_misiones'] ?? 0;
            _materiaFuerte = resumen['materia_top'] ?? "";
            _puntajesPorMateria = resumen['tabla_puntajes'] ?? {}; 
          }
          _isLoading = false;
        });
      }
    } else {
      _cerrarSesion();
    }
  }

  void _cerrarSesion() async {
    await AuthDbService.cerrarSesion();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = !_isDarkMode);
    themeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  void _mostrarModalMaterias() {
    final modalBgColor = _isDarkMode ? const Color(0xFF222232) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E1E2E);

    final misionesLista = [
      {'key': 'math', 'title': 'Matemáticas', 'emoji': '🔢'},
      {'key': 'memory', 'title': 'Memoria', 'emoji': '🧠'},
      {'key': 'logic', 'title': 'Lógica', 'emoji': '🧩'},
      {'key': 'grammar', 'title': 'Gramática', 'emoji': '✍️'},
      {'key': 'english', 'title': 'Inglés', 'emoji': '🗣️'},
      {'key': 'geography', 'title': 'Geografía', 'emoji': '🌎'},
      {'key': 'art', 'title': 'Arte', 'emoji': '🎨'},
      {'key': 'science', 'title': 'Ciencia', 'emoji': '🔬'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: modalBgColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: Color(0xFF9D4EDD), width: 1.5)),
          title: Text("Bitácora de Materias 📚", textAlign: TextAlign.center, style: GoogleFonts.fredoka(color: const Color(0xFF9D4EDD), fontSize: 24, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: misionesLista.length,
              itemBuilder: (context, index) {
                final mat = misionesLista[index];
                int estrellas = _puntajesPorMateria[mat['key']] ?? 0;
                bool completada = estrellas >= 10;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Text(mat['emoji']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(mat['title']!, style: GoogleFonts.nunito(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Text(
                        "$estrellas / 10 🌟", 
                        style: GoogleFonts.fredoka(color: completada ? const Color(0xFFFFD93D) : Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(width: 8),
                      Text(completada ? "✅" : "🚀", style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () => Navigator.pop(context),
                child: Text("¡Entendido!", style: GoogleFonts.fredoka(color: Colors.white)),
              ),
            )
          ],
        );
      }
    );
  }

  // PANEL INTERACTIVO DE CABINA INTERNA "COMANDO"
  void _mostrarPanelComando() {
    final modalBgColor = _isDarkMode ? const Color(0xFF151522) : Colors.white;
    final accentColor = const Color(0xFF4ECDC4);
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E1E2E);
    
    String keyMateriaTop = _materiaFuerte.toLowerCase().trim();
    int estrellasTop = _puntajesPorMateria[keyMateriaTop] ?? 0;
    double porcentajeMateria = (estrellasTop / 10).clamp(0.0, 1.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBgColor.withOpacity(0.95),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(30),
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            children: [
              Container(width: 60, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text("CENTRO DE COMANDO 🛸", style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 1)),
              const SizedBox(height: 25),
              
              _materiaFuerte.isEmpty
                ? Expanded(
                    child: Center(
                      child: Text("Sistemas en espera. ¡Completa tu primer juego para activar los propulsores!", textAlign: TextAlign.center, style: GoogleFonts.nunito(color: Colors.grey, fontSize: 16)),
                    ),
                  )
                : Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.radar_rounded, color: accentColor, size: 28),
                            const SizedBox(width: 10),
                            Text("Sector Inteligente:", style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                              child: Text("Estable", style: GoogleFonts.fredoka(color: accentColor, fontSize: 12)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("¡$_materiaFuerte dominado!", style: GoogleFonts.fredoka(fontSize: 22, color: textColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 30),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Energía de este Sector:", style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.bold)),
                            Text("$estrellasTop / 10 Estrellas", style: GoogleFonts.fredoka(color: const Color(0xFFFFD93D), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Barra interactiva animada
                        Stack(
                          children: [
                            Container(height: 20, width: double.infinity, decoration: BoxDecoration(color: _isDarkMode ? const Color(0xFF222232) : Colors.grey.shade300, borderRadius: BorderRadius.circular(15))),
                            FractionallySizedBox(
                              widthFactor: porcentajeMateria,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF48CAE4)]),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 10)]
                                ),
                              ),
                            )
                          ],
                        ),
                        const Spacer(),
                        
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: _isDarkMode ? const Color(0xFF222232) : Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: accentColor.withOpacity(0.2))),
                          child: Row(
                            children: [
                              const Text("🤖", style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  porcentajeMateria >= 1.0 
                                      ? "¡Sector completado! Es hora de desplegar tu conocimiento en otros planetas de estudio."
                                      : "Consejo del sistema: Juega un examen de $_materiaFuerte para recolectar las estrellas que te faltan.", 
                                  style: GoogleFonts.nunito(fontSize: 13, color: _isDarkMode ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  )
            ],
          ),
        );
      }
    );
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
      return Scaffold(backgroundColor: bgColor, body: Center(child: CircularProgressIndicator(color: titleNeonColor)));
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
        builder: (context, value, child) => Transform.translate(offset: Offset(0, value), child: Opacity(opacity: (1 - (value / 50)).clamp(0.0, 1.0), child: child)),
        child: _buildFloatingDock(cardColor, borderColor),
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _mainAnimController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -50 + _bgFloatAnimation.value, left: -100,
                    child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF48CAE4).withOpacity(_isDarkMode ? 0.2 : 0.1), blurRadius: 120)])),
                  ),
                  Positioned(
                    bottom: 100 - _bgFloatAnimation.value, right: -100,
                    child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(_isDarkMode ? 0.2 : 0.1), blurRadius: 150)])),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) => Opacity(opacity: value, child: child),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("¡Misión iniciada,", style: GoogleFonts.nunito(color: secondaryTextColor, fontSize: 16, fontWeight: FontWeight.w800)),
                            Row(
                              children: [
                                Text("$_userName! ", style: GoogleFonts.fredoka(color: primaryTextColor, fontSize: 26, fontWeight: FontWeight.bold)),
                                const Text("🚀", style: TextStyle(fontSize: 22)),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        
                        // NUEVO BOTÓN DE CERRAR SESIÓN
                        _buildTopIcon(
                          icon: Icons.logout_rounded,
                          color: const Color(0xFFFF6B6B), // Un color rojizo para salir
                          cardColor: cardColor,
                          onTap: _cerrarSesion,
                        ),
                        const SizedBox(width: 12),
                        
                        // BOTÓN DE TEMA
                        _buildTopIcon(
                          icon: _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: _isDarkMode ? const Color(0xFFFFD93D) : const Color(0xFF5E60CE),
                          cardColor: cardColor,
                          onTap: _toggleTheme,
                        ),
                        const SizedBox(width: 12),
                        
                        AnimatedBuilder(
                          animation: _mainAnimController,
                          builder: (context, child) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileSettingsScreen())).then((_) => _cargarDatosDesdeBD()); 
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                width: 55, height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF9D4EDD), width: 2),
                                  boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity((_isDarkMode ? 0.6 : 0.3) * _mainAnimController.value), blurRadius: 15, spreadRadius: 2)]
                                ),
                                child: CircleAvatar(backgroundColor: cardColor, backgroundImage: AssetImage(_userAvatar)),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text("Elige tu destino espacial ✨", style: GoogleFonts.fredoka(color: titleNeonColor, fontSize: 22, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 110),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: 1.15,
                    ),
                    itemCount: misiones.length,
                    itemBuilder: (context, index) {
                      final mision = misiones[index];
                      final String mKey = mision['key'] as String;
                      
                      int puntosMateria = _puntajesPorMateria[mKey] ?? 0;
                      bool estaMisionBloqueada = puntosMateria >= 10;

                      return AnimatedBuilder(
                        animation: _mainAnimController,
                        builder: (context, child) {
                          final delay = index * 0.5;
                          final floatOffset = estaMisionBloqueada ? 0.0 : math.sin((_mainAnimController.value * math.pi * 2) + delay) * 6.0;
                          return Transform.translate(
                            offset: Offset(0, floatOffset),
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 400 + (index * 100)),
                              curve: Curves.easeOutBack,
                              builder: (context, scaleValue, child) => Transform.scale(scale: scaleValue, child: child),
                              child: _BouncingActivityCard(
                                subjectKey: mKey, 
                                title: mision['title'] as String,
                                emoji: mision['emoji'] as String, 
                                accentColor: mision['color'] as Color,
                                cardColor: cardColor, 
                                textColor: primaryTextColor, 
                                isDarkMode: _isDarkMode,
                                isLocked: estaMisionBloqueada, 
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
            border: Border.all(color: color.withOpacity(0.5), width: 1.5)
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
            color: cardColor.withOpacity(_isDarkMode ? 0.7 : 0.9), borderRadius: BorderRadius.circular(40),
            border: Border.all(color: borderColor.withOpacity(0.5), width: 2), 
            boxShadow: [BoxShadow(color: _isDarkMode ? Colors.black87 : Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockAction(Icons.emoji_events_rounded, "Logros", const Color(0xFFFFD93D), () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => AchievementsScreen(userId: _userIdInt))
                ).then((_) => _cargarDatosDesdeBD());
              }),
              _buildDockAction(Icons.library_books_rounded, "Materias", const Color(0xFF9D4EDD), () {
                _mostrarModalMaterias();
              }),
              // CAMBIO DE AVANCE POR "COMANDO 🛸" INTERACTIVO
              _buildDockAction(Icons.rocket_launch_rounded, "Comando", const Color(0xFF4ECDC4), () {
                _mostrarPanelComando();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Icon(icon, color: color, size: 30), 
            const SizedBox(height: 6), 
            Text(label, style: GoogleFonts.nunito(color: color, fontSize: 13, fontWeight: FontWeight.bold))
          ]
        ),
      ),
    );
  }
}

class _BouncingActivityCard extends StatefulWidget {
  final String subjectKey; final String title; final String emoji; final Color accentColor; final Color cardColor; final Color textColor; final bool isDarkMode; final bool isLocked; 
  const _BouncingActivityCard({required this.subjectKey, required this.title, required this.emoji, required this.accentColor, required this.cardColor, required this.textColor, required this.isDarkMode, required this.isLocked});
  @override
  State<_BouncingActivityCard> createState() => _BouncingActivityCardState();
}

class _BouncingActivityCardState extends State<_BouncingActivityCard> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  void _onTapDown(TapDownDetails details) { if (!widget.isLocked) setState(() => _scale = 0.90); }
  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    if (widget.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("¡Excelente! Conseguiste las 10 estrellas de ${widget.title}. 🌟", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFFF9F43), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), duration: const Duration(seconds: 2),
      ));
      return;
    }
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) { Navigator.push(context, MaterialPageRoute(builder: (context) => TestScreen(subject: widget.subjectKey))); }
    });
  }
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown, onTapUp: _onTapUp, onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale, duration: const Duration(milliseconds: 100), curve: Curves.easeInOut,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: widget.isLocked ? 0.4 : 1.0, 
              child: Container(
                width: double.infinity, height: double.infinity, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [widget.cardColor.withOpacity(widget.isDarkMode ? 0.8 : 1.0), widget.accentColor.withOpacity(widget.isDarkMode ? 0.2 : 0.1)]),
                  borderRadius: BorderRadius.circular(40), border: Border.all(color: widget.accentColor.withOpacity(0.5), width: 2),
                  boxShadow: [BoxShadow(color: widget.accentColor.withOpacity(widget.isDarkMode ? 0.3 : 0.15), blurRadius: 20, offset: const Offset(0, 5))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: widget.accentColor.withOpacity(0.15), shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.accentColor.withOpacity(0.3), blurRadius: 15)]),
                      child: Text(widget.emoji, style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.title, textAlign: TextAlign.center, style: GoogleFonts.fredoka(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 17))),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isLocked)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: widget.isDarkMode ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.8), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD93D), size: 38), 
              ),
          ],
        ),
      ),
    );
  }
}