import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- AGREGA ESTA LÍNEA
import '../../models/pregunta_model.dart';
import '../../services/neon_db_service.dart';

class TestScreen extends StatefulWidget {
  final String subject; // materia que viene del Home

  const TestScreen({super.key, required this.subject});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<Pregunta> _preguntas = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  int _score = 0;
  int? _selectedAnswer; // Opción que tocó el usuario
  bool _answered = false; // Ya respondió la pregunta actual?

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

void _loadQuestions() async {
    // Para probar, forzamos el grado 1 que vemos en tu captura de Neon
    final rawPreguntas = await NeonDbService.obtenerPreguntasPorMateria(widget.subject, 1);
    
    setState(() {
      _preguntas = rawPreguntas.map((p) => Pregunta.fromDatabase(p)).toList();
      _isLoading = false;
    });
  }
  
  void _verificarRespuesta(int indexSeleccionado) {
    if (_answered) return; // Ya respondió, no hacer nada

    setState(() {
      _selectedAnswer = indexSeleccionado;
      _answered = true;
      
      // Es correcta? (Igual lógica que en JS)
      if (indexSeleccionado == _preguntas[_currentIndex].correctOption) {
        _score++;
        // Sonido de victoria si tienes implementado audio
      }
    });

    // Pequeña pausa para ver el color y pasar a la siguiente (Igual que en JS)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _answered = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Buscamos el emoji para la materia actual
    String currentEmoji = Pregunta.subjectEmojis[widget.subject] ?? '🎮';

    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFF0D1B2A), body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
    }

    if (_preguntas.isEmpty || _currentIndex >= _preguntas.length) {
      return _buildFinalScreen();
    }

    final preguntaActual = _preguntas[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Fondo Deep Dark
      body: SafeArea(
        child: Column(
          children: [
            // --- BARRA SUPERIOR DE JUEGO (Estilo Game Modal Web) ---
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent)
                  ),
                  Text(
                    "$currentEmoji Actividad", 
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const Spacer(),
                  // Botón de ayuda (Igual que el ❔ Ayuda web)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: Colors.amberAccent, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      children: [
                        Icon(Icons.help_outline, size: 16, color: Color(0xFF0D1B2A)),
                        SizedBox(width: 5),
                        Text("Ayuda", style: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // --- MARCADOR DE ESTRELLAS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    "⭐ $_score", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)
                  ),
                ),
              ),
            ),

            // --- ÁREA DE JUEGO ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // TARJETA DE PREGUNTA (Elevada como el questionText web)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      // Antes: EdgeInsets.bottom(30)
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B263B), // Tarjeta
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)), // Borde cian sutil
                        boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 15, spreadRadius: 2)],
                      ),
                      child: Text(
                        preguntaActual.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.3),
                      ),
                    ),

                    // GRILLA DE OPCIONES (Estilo Options Container Web)
                    // Usamos GridView dentro de Column con shrinkWrap
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 15, 
                        mainAxisSpacing: 15, 
                        childAspectRatio: 2
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

  Widget _buildOptionButton(Pregunta pregunta, int index) {
    Color buttonColor = const Color(0xFF1B263B); // Color por defecto
    Color textColor = Colors.white;

    if (_answered) {
      if (index == pregunta.correctOption) {
        // Esta es la correcta: ¡Verde GreenAccent!
        buttonColor = Colors.greenAccent;
        textColor = const Color(0xFF0D1B2A);
      } else if (index == _selectedAnswer) {
        // Esta la tocó el usuario y estaba mal: ¡Rosa PinkAccent!
        buttonColor = Colors.pinkAccent;
        textColor = Colors.white;
      }
    }

    return InkWell(
      onTap: () => _verificarRespuesta(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _answered && index == pregunta.correctOption ? Colors.greenAccent : const Color(0xFF334155)),
          boxShadow: [
            if (_answered && index == pregunta.correctOption)
              const BoxShadow(color: Colors.greenAccent, blurRadius: 10)
            else
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              pregunta.options[index],
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🚀", style: TextStyle(fontSize: 100)),
            const SizedBox(height: 30),
            const Text(
              "¡Actividad Completada!", 
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(20)),
              child: Text(
                "Finalizaste con ⭐ $_score estrellas", 
                style: const TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w900, fontSize: 22)
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: const Color(0xFF0D1B2A)),
              onPressed: () => Navigator.pop(context), 
              child: const Text("Volver al Menú", style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }
}