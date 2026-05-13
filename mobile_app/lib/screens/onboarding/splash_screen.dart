import 'dart:async';
import 'dart:math'; // <-- Importamos math para la aleatoriedad
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart'; 

class SplashScreen extends StatefulWidget {
  final Widget destino; 
  
  const SplashScreen({super.key, required this.destino});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // --- LISTA DE CONSEJOS ---
  final List<String> _consejos = [
    "¡Aprender cosas nuevas es una súper aventura!",
    "Recuerda descansar tus ojitos cada 20 minutos.",
    "Si te equivocas, ¡no pasa nada! Así aprendemos.",
    "¡Tu cerebro brilla como una estrella cuando estudias!",
    "Pide ayuda a tus papás o maestros si tienes dudas."
  ];
  
  int _indiceConsejoActual = 0;
  Timer? _timerConsejos;
  final Random _random = Random(); // <-- Generador de números aleatorios

  // --- ESTADOS Y CONTROLADORES ---
  VideoPlayerController? _videoController;
  bool _mostrarGif = false; 
  bool _tieneInternet = true;
  bool _verificando = true;

  @override
  void initState() {
    super.initState();
    _iniciarSecuencia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _timerConsejos?.cancel();
    super.dispose();
  }

  // --- LÓGICA DE LA SECUENCIA ---
  Future<void> _iniciarSecuencia() async {
    // 1. Inicializamos y reproducimos el Video
    _videoController = VideoPlayerController.asset('assets/AppTec.mp4')
      ..initialize().then((_) {
        setState(() {}); // Actualiza la UI cuando el video está listo
        _videoController!.play();
      });

    // 2. Escuchamos cuándo termina el video
    _videoController!.addListener(() {
      if (_videoController!.value.position >= _videoController!.value.duration) {
        if (!_mostrarGif) {
          // El video terminó, pasamos a la fase del GIF
          _iniciarFaseGif();
        }
      }
    });
  }

  void _iniciarFaseGif() {
    setState(() {
      _mostrarGif = true; 
      // Elegimos el primer consejo al azar
      _indiceConsejoActual = _random.nextInt(_consejos.length); 
    });

    // 3. Iniciamos el rotador de consejos (Cambia cada 3.5 segundos)
    _timerConsejos = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted) {
        setState(() {
          int nuevoIndice;
          // Buscamos un nuevo consejo aleatorio que NO sea igual al actual
          do {
            nuevoIndice = _random.nextInt(_consejos.length);
          } while (nuevoIndice == _indiceConsejoActual && _consejos.length > 1);
          
          _indiceConsejoActual = nuevoIndice;
        });
      }
    });

    // 4. Verificamos internet y procedemos al destino
    _verificarYContinuar();
  }

  Future<void> _verificarYContinuar() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _tieneInternet = false;
        _verificando = false;
      });
      // Detenemos los consejos si no hay internet para que lean el error
      _timerConsejos?.cancel(); 
      return;
    }

    // Le damos tiempo al usuario de ver el GIF y leer un par de consejos (ej. 7 segundos)
    await Future.delayed(const Duration(seconds: 7));

    if (mounted) {
      // 5. Navegamos a la siguiente pantalla (Login o Juego)
      Navigator.pushReplacement(
        context, 
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.destino,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro ideal para la transición del video
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800), // Fundido suave entre el Video y el GIF
        child: _mostrarGif 
            ? _construirPantallaGifYConsejos() 
            : _construirReproductorVideo(),
      ),
    );
  }

  // --- VISTA 1: EL VIDEO ---
  Widget _construirReproductorVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain, // Mantiene la proporción del video
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    } else {
      // Pantalla negra de carga rápida antes de que el video inicie
      return const Center(child: SizedBox.shrink()); 
    }
  }

  // --- VISTA 2: EL GIF Y LOS CONSEJOS ---
  Widget _construirPantallaGifYConsejos() {
    return Stack(
      key: const ValueKey("PantallaGif"), // Clave para que AnimatedSwitcher sepa que cambió
      fit: StackFit.expand,
      children: [
        // 1. El GIF de Fondo
        Image.asset(
          'assets/fondo_aventura.gif', 
          fit: BoxFit.cover,
        ),
        
        // 2. Capa oscura semitransparente para que el texto resalte
        Container(
          color: Colors.black.withOpacity(0.4),
        ),

        // 3. El cuadro de Consejos / Error de Red
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // Lo empujamos hacia abajo
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6), // Efecto cristal oscuro
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_verificando || _tieneInternet) ...[
                        Text(
                          "💡 Sabías que...",
                          style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFFFD93D)),
                        ),
                        const SizedBox(height: 16),
                        // AnimatedSwitcher para hacer un fundido cuando cambia el texto del consejo
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            _consejos[_indiceConsejoActual],
                            key: ValueKey<int>(_indiceConsejoActual), // Importante para la animación
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Pequeño indicador de carga
                        const CircularProgressIndicator(
                          color: Color(0xFF48CAE4),
                          strokeWidth: 3,
                        ),
                      ] else ...[
                        const Icon(Icons.wifi_off_rounded, size: 60, color: Color(0xFFFF6B6B)),
                        const SizedBox(height: 15),
                        Text("¡Ups! Sin internet", style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B6B))),
                        const SizedBox(height: 8),
                        Text("Revisa tu conexión para seguir jugando y aprendiendo.", textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 16, color: Colors.white70)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF48CAE4),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () {
                            setState(() { _verificando = true; _tieneInternet = true; });
                            // Si recupera el internet, reanudamos la fase del GIF y consejos
                            _iniciarFaseGif(); 
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                          label: Text("Reintentar", style: GoogleFonts.fredoka(fontSize: 18, color: Colors.black)),
                        )
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 50), // Espacio desde abajo
              ],
            ),
          ),
        ),
      ],
    );
  }
}