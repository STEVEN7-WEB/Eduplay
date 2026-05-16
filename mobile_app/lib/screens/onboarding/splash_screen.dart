import 'dart:async';
import 'dart:math';
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
  final Random _random = Random();

  // --- ESTADOS Y CONTROLADORES ---
  VideoPlayerController? _introVideoController; 
  VideoPlayerController? _backgroundVideoController; 
  bool _mostrarFaseCarga = false; 
  bool _tieneInternet = true; 
  bool _verificandoInternet = true; 

  @override
  void initState() {
    super.initState();
    _iniciarSecuencia();
  }

  @override
  void dispose() {
    _introVideoController?.dispose();
    _backgroundVideoController?.dispose();
    _timerConsejos?.cancel();
    super.dispose();
  }

  // --- LÓGICA DE LA SECUENCIA ---
  Future<void> _iniciarSecuencia() async {
    // Limpiamos el controlador anterior por si venimos del botón "Reintentar"
    _introVideoController?.dispose();
    
    _introVideoController = VideoPlayerController.asset('assets/AppTec.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _mostrarFaseCarga = false; // Nos aseguramos de volver a la vista 1
            _verificandoInternet = true; 
          }); 
          _introVideoController!.play();
        }
      });

    _introVideoController!.addListener(() {
      final value = _introVideoController!.value;
      if (value.isInitialized && value.duration > Duration.zero) {
        if (value.position >= value.duration - const Duration(milliseconds: 100)) {
          if (!_mostrarFaseCarga) {
            _iniciarFaseCarga();
          }
        }
      }
    });
  }

  void _iniciarFaseCarga() {
    // Limpiamos el fondo anterior para evitar fugas de memoria
    _backgroundVideoController?.dispose();

    _backgroundVideoController = VideoPlayerController.asset('assets/Carga.mp4')
      ..initialize().then((_) {
        _backgroundVideoController!.setLooping(true);
        _backgroundVideoController!.play();
        if (mounted) setState(() {}); 
      });

    setState(() {
      _mostrarFaseCarga = true; 
      _indiceConsejoActual = _random.nextInt(_consejos.length); 
    });

    // Reiniciamos el timer de los consejos
    _timerConsejos?.cancel();
    _timerConsejos = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
      if (mounted) {
        setState(() {
          int nuevoIndice;
          do {
            nuevoIndice = _random.nextInt(_consejos.length);
          } while (nuevoIndice == _indiceConsejoActual && _consejos.length > 1);
          _indiceConsejoActual = nuevoIndice;
        });
      }
    });

    _verificarInternetYContinuar();
  }

  Future<void> _verificarInternetYContinuar() async {
    try {
      final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
      
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (mounted) {
          setState(() {
            _tieneInternet = false;
            _verificandoInternet = false;
          });
          _timerConsejos?.cancel(); // Detenemos los consejos para mostrar el error
        }
        return; // Detenemos la secuencia
      } else {
        if (mounted) {
          setState(() {
            _tieneInternet = true;
            _verificandoInternet = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error verificando conexión: $e");
      if (mounted) {
        setState(() {
          _tieneInternet = true;
          _verificandoInternet = false;
        });
      }
    }

    // Esperamos 12 segundos para que se lean bien los consejos
    await Future.delayed(const Duration(seconds: 12));

    if (mounted && _tieneInternet) {
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
      backgroundColor: Colors.black, 
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: _mostrarFaseCarga 
            ? _construirPantallaCargaConVideoFondo() 
            : _construirReproductorVideoIntro(),
      ),
    );
  }

  // --- VISTA 1: EL VIDEO DE INTRO ---
  Widget _construirReproductorVideoIntro() {
    if (_introVideoController != null && _introVideoController!.value.isInitialized) {
      return SizedBox.expand(
        key: const ValueKey("IntroVideo"), 
        child: FittedBox(
          fit: BoxFit.contain, 
          child: SizedBox(
            width: _introVideoController!.value.size.width,
            height: _introVideoController!.value.size.height,
            child: VideoPlayer(_introVideoController!),
          ),
        ),
      );
    } else {
      return const Center(key: ValueKey("IntroLoading"), child: SizedBox.shrink()); 
    }
  }

  // --- VISTA 2: EL VIDEO DE FONDO Y LOS CONSEJOS / ERROR ---
  Widget _construirPantallaCargaConVideoFondo() {
    return Stack(
      key: const ValueKey("PantallaCargaConVideo"), 
      fit: StackFit.expand,
      children: [
        if (_backgroundVideoController != null && _backgroundVideoController!.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover, 
              child: SizedBox(
                width: _backgroundVideoController!.value.size.width,
                height: _backgroundVideoController!.value.size.height,
                child: VideoPlayer(_backgroundVideoController!),
              ),
            ),
          )
        else
          Container(color: Colors.black),
        
        Container(color: Colors.black.withOpacity(0.5)),

        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, 
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_tieneInternet || _verificandoInternet) ...[
                        Text(
                          "💡 Sabías que...",
                          style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFFFD93D)),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            _consejos[_indiceConsejoActual],
                            key: ValueKey<int>(_indiceConsejoActual),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(color: Color(0xFF48CAE4), strokeWidth: 3),
                      ] 
                      else ...[
                        const Icon(Icons.wifi_off_rounded, size: 60, color: Color(0xFFFF6B6B)),
                        const SizedBox(height: 15),
                        Text("¡Sin Internet!", style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B6B))),
                        const SizedBox(height: 8),
                        Text("Revisa tu conexión para seguir jugando y aprendiendo.", textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF48CAE4),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () {
                            // REINICIO COMPLETO
                            _timerConsejos?.cancel();
                            _backgroundVideoController?.pause();
                            _iniciarSecuencia(); 
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                          label: Text("Reintentar", style: GoogleFonts.fredoka(fontSize: 18, color: Colors.black)),
                        )
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 50), 
              ],
            ),
          ),
        ),
      ],
    );
  }
}