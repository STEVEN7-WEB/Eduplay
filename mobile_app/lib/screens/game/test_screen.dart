import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pregunta_model.dart';
import '../../services/neon_db_service.dart';

class TestScreen extends StatefulWidget {
  final String subject;

  const TestScreen({super.key, required this.subject});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<Pregunta> _preguntas = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  int _score = 0;
  int? _selectedAnswer; 
  bool _answered = false; 
  
  double _scoreScale = 1.0;

  // --- VARIABLES DEL TEMPORIZADOR ---
  Timer? _timer;
  final int _tiempoMaximo = 15;
  int _tiempoRestante = 15;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  void _loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final int gradoActual = prefs.getInt('grado_usuario') ?? 1;

    final rawPreguntas = await NeonDbService.obtenerPreguntasPorMateria(widget.subject, gradoActual);
    
    setState(() {
      _preguntas = rawPreguntas.map((p) => Pregunta.fromDatabase(p)).toList();
      _isLoading = false;
    });

    _iniciarTemporizador();
  }

  void _iniciarTemporizador() {
    _timer?.cancel();
    setState(() => _tiempoRestante = _tiempoMaximo);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tiempoRestante > 0) {
        setState(() => _tiempoRestante--);
      } else {
        _timer?.cancel();
        _verificarRespuesta(-1); // Tiempo Agotado
      }
    });
  }
  
  void _verificarRespuesta(int indexSeleccionado) {
    if (_answered) return; 
    
    _timer?.cancel();

    setState(() {
      _selectedAnswer = indexSeleccionado;
      _answered = true;
      
      if (indexSeleccionado != -1 && indexSeleccionado == _preguntas[_currentIndex].correctOption) {
        _score++;
        _scoreScale = 1.4; 
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _scoreScale = 1.0);
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _answered = false;
        });
        
        if (_currentIndex < _preguntas.length) {
          _iniciarTemporizador();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentEmoji = Pregunta.subjectEmojis[widget.subject] ?? '🎮';

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF151522), 
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF48CAE4), strokeWidth: 6)
        )
      );
    }

    if (_preguntas.isEmpty || _currentIndex >= _preguntas.length) {
      return _buildFinalScreen();
    }

    final preguntaActual = _preguntas[_currentIndex];
    Color colorReloj = _tiempoRestante > 5 ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B);

    return Scaffold(
      backgroundColor: const Color(0xFF151522),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingDock(),
      body: SafeArea(
        child: Column(
          children: [
            // --- BARRA SUPERIOR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF222232),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF6B6B), width: 1.5),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context), 
                      icon: const Icon(Icons.close_rounded, color: Color(0xFFFF6B6B), size: 24)
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "$currentEmoji Misión Activa", 
                      style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
            
            // --- MARCADOR Y RELOJ ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pregunta ${_currentIndex + 1} / ${_preguntas.length}",
                    style: GoogleFonts.nunito(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  AnimatedScale(
                    scale: _scoreScale,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD93D), 
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.5), blurRadius: 10)]
                      ),
                      child: Text(
                        "⭐ $_score", 
                        style: GoogleFonts.fredoka(color: const Color(0xFF151522), fontWeight: FontWeight.w900, fontSize: 16)
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- BARRA DE TIEMPO ANIMADA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.timer_rounded, key: ValueKey(colorReloj), color: colorReloj, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: colorReloj.withOpacity(0.5), blurRadius: 10)]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(color: Color(0xFF222232)),
                          child: FractionallySizedBox(
                            widthFactor: _tiempoRestante / _tiempoMaximo,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorReloj,
                                borderRadius: BorderRadius.circular(10)
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 55,
                    child: Text(
                      "00:${_tiempoRestante.toString().padLeft(2, '0')}",
                      style: GoogleFonts.fredoka(color: colorReloj, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // --- ÁREA DE JUEGO ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // MUESTRA ALERTA SI SE ACABÓ EL TIEMPO (CON ANIMACIÓN)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: (_answered && _selectedAnswer == -1)
                        ? Container(
                            key: const ValueKey("timeout"),
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: const Color(0xFFFF6B6B)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer_off_rounded, color: Color(0xFFFF6B6B)),
                                const SizedBox(width: 10),
                                Text("¡Se acabó el tiempo!", style: GoogleFonts.nunito(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey("notimeout")),
                    ),

                    // TARJETA DE PREGUNTA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222232),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Text(
                        preguntaActual.text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),

                    // OPCIONES
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 15, 
                        mainAxisSpacing: 15, 
                        childAspectRatio: 1.5 
                      ),
                      itemCount: preguntaActual.options.length,
                      itemBuilder: (context, index) {
                        return _buildOptionButton(preguntaActual, index);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DOCK FLOTANTE ---
  Widget _buildFloatingDock() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF222232).withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFF48CAE4).withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDockAction(Icons.emoji_events_rounded, "Logros", const Color(0xFFFFD93D), () => _mostrarModalLogros()),
          _buildDockAction(Icons.lightbulb_rounded, "Pista", const Color(0xFF4ECDC4), () => _mostrarModalPista()),
          _buildDockAction(Icons.sos_rounded, "Ayuda", const Color(0xFFFF6B6B), () => _mostrarModalAyuda()),
        ],
      ),
    );
  }

  Widget _buildDockAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.nunito(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- BOTONES DE OPCIÓN ---
  Widget _buildOptionButton(Pregunta pregunta, int index) {
    Color cardColor = const Color(0xFF222232);
    Color textColor = Colors.white;
    Color borderColor = const Color(0xFF333344);
    double elevate = 0.0;
    Color shadowColor = Colors.transparent;
    double scale = 1.0; // Controla si se infla o se hunde

    if (_answered) {
      if (index == pregunta.correctOption) {
        cardColor = const Color(0xFF4ECDC4);
        textColor = const Color(0xFF151522);
        borderColor = const Color(0xFF4ECDC4);
        shadowColor = const Color(0xFF4ECDC4);
        elevate = 15.0;
        scale = 1.05; // Crece hacia adelante (Pop)
      } else if (index == _selectedAnswer) {
        cardColor = const Color(0xFFFF6B6B);
        textColor = Colors.white;
        borderColor = const Color(0xFFFF6B6B);
        shadowColor = const Color(0xFFFF6B6B);
        elevate = 0.0; 
        scale = 0.95; // Se hunde al equivocarse
      } else {
        cardColor = const Color(0xFF1A1A2A);
        textColor = Colors.white38;
      }
    }

    return GestureDetector(
      onTap: () => _verificarRespuesta(index),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: borderColor, width: 2),
            // SOLUCIÓN AL ERROR ROJO: La sombra siempre existe, solo se apaga su color
            boxShadow: [
              BoxShadow(
                color: shadowColor == Colors.transparent ? Colors.transparent : shadowColor.withOpacity(0.5), 
                blurRadius: elevate, 
                offset: const Offset(0, 0)
              )
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              // Añadido FittedBox para evitar que textos muy largos rompan el cuadro
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  pregunta.options[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarModalLogros() {
    _mostrarDialogoBase("Tus Logros 🏆", "Has desbloqueado el nivel 'Explorador Espacial'. ¡Sigue sumando estrellas!", const Color(0xFFFFD93D));
  }
  void _mostrarModalPista() {
    _mostrarDialogoBase("Pista de la Misión 💡", "Lee la pregunta cuidadosamente. ¡Tú puedes lograrlo!", const Color(0xFF4ECDC4));
  }
  void _mostrarModalAyuda() {
    _mostrarDialogoBase("¿Necesitas Ayuda? 🆘", "Pide apoyo para que te guíen en esta misión intergaláctica.", const Color(0xFFFF6B6B));
  }

  void _mostrarDialogoBase(String titulo, String mensaje, Color colorNeon) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222232),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: colorNeon.withOpacity(0.5), width: 2)),
          title: Text(titulo, textAlign: TextAlign.center, style: GoogleFonts.fredoka(color: colorNeon, fontWeight: FontWeight.bold)),
          content: Text(mensaje, textAlign: TextAlign.center, style: GoogleFonts.nunito(color: Colors.white, fontSize: 16)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorNeon, foregroundColor: const Color(0xFF151522), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: () => Navigator.pop(context),
              child: Text("¡Entendido!", style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
            )
          ],
        );
      }
    );
  }

  Widget _buildFinalScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF151522),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: const Color(0xFF222232), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD93D), width: 3), boxShadow: [BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.4), blurRadius: 40, spreadRadius: 5)]),
              child: const Text("🏆", style: TextStyle(fontSize: 90)),
            ),
            const SizedBox(height: 40),
            Text("¡Misión Cumplida!", style: GoogleFonts.fredoka(color: const Color(0xFF48CAE4), fontSize: 36, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text("¡Eres genial!", style: GoogleFonts.nunito(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(color: const Color(0xFFFFD93D), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]),
              child: Text("Ganaste ⭐ $_score puntos", style: GoogleFonts.fredoka(color: const Color(0xFF151522), fontWeight: FontWeight.w900, fontSize: 24)),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: () => Navigator.pop(context), 
              child: Text("Volver a la Base", style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }
}