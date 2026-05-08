import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Widget destino; 
  
  const SplashScreen({super.key, required this.destino});

  @override
  // Se agrega TickerProviderStateMixin para poder usar animaciones
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final List<String> _consejos = [
    "¡Aprender cosas nuevas es una súper aventura!",
    "Recuerda descansar tus ojitos cada 20 minutos.",
    "Si te equivocas, ¡no pasa nada! Así aprendemos.",
    "¡Tu cerebro brilla como una estrella cuando estudias!",
    "Pide ayuda a tus papás o maestros si tienes dudas."
  ];
  
  late String _consejoActual;
  bool _tieneInternet = true;
  bool _verificando = true;

  // --- CONTROLADORES DE ANIMACIÓN ---
  late AnimationController _despegueController;
  late Animation<Offset> _despegueAnimation;
  late AnimationController _turbinaController;

  @override
  void initState() {
    super.initState();
    _consejoActual = _consejos[Random().nextInt(_consejos.length)];

    // 1. Animación del despegue (El cohete sube fuera de la pantalla)
    _despegueController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _despegueAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -5.0)).animate(
      CurvedAnimation(parent: _despegueController, curve: Curves.easeInBack)
    );

    // 2. Animación de la turbina/humo (Gira infinitamente)
    _turbinaController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

    _iniciarApp();
  }

  @override
  void dispose() {
    _despegueController.dispose();
    _turbinaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarApp() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _tieneInternet = false;
        _verificando = false;
      });
      return;
    }

    // Simulamos un tiempo de carga de 3 segundos mientras leen el consejo
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // ¡INICIAMOS EL DESPEGUE!
      _despegueController.forward();

      // Esperamos a que el cohete termine de salir de la pantalla
      await Future.delayed(const Duration(milliseconds: 800));

      // Pasamos a la siguiente pantalla sin transición para que se sienta continuo
      Navigator.pushReplacement(
        context, 
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => widget.destino,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151522), // Fondo oscuro espacial suave
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              // --- ZONA DEL COHETE ANIMADO ---
              SlideTransition(
                position: _despegueAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Anillo rotatorio de carga / energía de la turbina
                    RotationTransition(
                      turns: _turbinaController,
                      child: Container(
                        height: 140, width: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [Colors.transparent, Color(0xFF48CAE4), Colors.white],
                            stops: [0.2, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Fondo interior para tapar el centro del gradiente y dejar solo el anillo
                    Container(
                      height: 130, width: 130,
                      decoration: const BoxDecoration(
                        color: Color(0xFF151522),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Logo central del cohete
                    Container(
                      height: 110, width: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222232),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF48CAE4).withOpacity(0.5), blurRadius: 25, spreadRadius: 2)
                        ]
                      ),
                      child: const Icon(Icons.rocket_launch_rounded, size: 55, color: Color(0xFF48CAE4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              
              // --- MENSAJES INFERIORES ANIMADOS ---
              // AnimatedOpacity hace que el texto desaparezca justo cuando el cohete arranca
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _despegueController.isAnimating ? 0.0 : 1.0,
                child: Column(
                  children: [
                    if (_verificando || _tieneInternet) ...[
                      Text(
                        "Recuerda que...",
                        style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFFFD93D)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _consejoActual,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
                      ),
                    ] else ...[
                      const Icon(Icons.wifi_off_rounded, size: 80, color: Color(0xFFFF6B6B)),
                      const SizedBox(height: 20),
                      Text("¡Ups! Sin internet", style: GoogleFonts.fredoka(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B6B))),
                      const SizedBox(height: 10),
                      Text("Revisa tu conexión para seguir jugando.", textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70)),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48CAE4),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          setState(() { _verificando = true; _tieneInternet = true; });
                          _iniciarApp();
                        },
                        child: Text("Reintentar", style: GoogleFonts.fredoka(fontSize: 20, color: const Color(0xFF151522))),
                      )
                    ]
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}