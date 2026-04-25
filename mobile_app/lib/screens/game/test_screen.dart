import 'package:flutter/material.dart';
import '../../services/neon_db_service.dart';
import '../../models/pregunta_model.dart';

class TestScreen extends StatefulWidget {
  final String materia;
  final int gradoUsuario;
  final Color accentColor;

  const TestScreen({super.key, required this.materia, required this.gradoUsuario, required this.accentColor});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int _preguntaActual = 0;
  int _puntos = 0;
  late List<Pregunta> _preguntasFiltradas;

  @override
  void initState() {
    super.initState();
    // Seleccionamos el banco según la materia
    List<Pregunta> bancoCompleto = [];
    if (widget.materia == 'MATEMÁTICAS') bancoCompleto = bancoMatematicas;
    else if (widget.materia == 'ESPAÑOL') bancoCompleto = bancoEspanol;
    // Añade el resto de los bancos aquí...

    // Filtramos por grado
    _preguntasFiltradas = bancoCompleto.where((p) => p.gradoMinimo <= widget.gradoUsuario).toList();
    // Mezclamos las preguntas al azar
    _preguntasFiltradas.shuffle();
  }

  void _responder(int index) {
    if (index == _preguntasFiltradas[_preguntaActual].respuestaCorrecta) {
      _puntos += 10;
    }

    if (_preguntaActual < _preguntasFiltradas.length - 1) {
      setState(() => _preguntaActual++);
    } else {
      _finalizarJuego();
    }
  }

  void _finalizarJuego() async {
    await NeonDbService.guardarPuntaje(widget.materia, _puntos);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: widget.accentColor)),
        title: Text("¡FIN DEL RETO!", style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold)),
        content: Text("Ganaste $_puntos puntos en ${widget.materia} 🏆", style: const TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("SALIR AL MENÚ", style: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_preguntasFiltradas.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: Text("Pronto habrá más preguntas para tu grado 🚧", style: TextStyle(color: Colors.white, fontSize: 18))),
      );
    }

    final pregunta = _preguntasFiltradas[_preguntaActual];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(widget.materia, style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.accentColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: (_preguntaActual + 1) / _preguntasFiltradas.length, color: widget.accentColor, backgroundColor: const Color(0xFF1B263B)),
            const SizedBox(height: 50),
            Text(pregunta.enunciado, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 50),
            ...List.generate(pregunta.opciones.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B263B),
                      side: BorderSide(color: widget.accentColor.withOpacity(0.5), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => _responder(index),
                    child: Text(pregunta.opciones[index], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}