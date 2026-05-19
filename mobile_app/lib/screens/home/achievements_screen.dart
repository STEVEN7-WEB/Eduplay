import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/neon_db/game_db_service.dart';

class AchievementsScreen extends StatefulWidget {
  final int userId;
  const AchievementsScreen({super.key, required this.userId});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with TickerProviderStateMixin {
  late AnimationController _neonAnimController;
  late Animation<double> _bgFloatAnimation;

  @override
  void initState() {
    super.initState();
    // Controlador de animación para el movimiento cósmico del fondo y las tarjetas
    _neonAnimController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 4)
    )..repeat(reverse: true);

    _bgFloatAnimation = Tween<double>(begin: -12.0, end: 12.0).animate(
      CurvedAnimation(parent: _neonAnimController, curve: Curves.easeInOutSine)
    );
  }

  @override
  void dispose() {
    _neonAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sincronizado con la paleta oscura espacial del HomeScreen
    const Color bgColor = Color(0xFF0D0D1A);
    const Color cardColor = Color(0xFF222232);
    const Color accentColor = Color(0xFFFFD93D);

    return Scaffold(
      backgroundColor: bgColor, 
      body: Stack(
        children: [
          // ======================================================================
          // 🌌 NEBULOSAS DE FONDO EN MOVIMIENTO (IGUAL QUE EL HOME)
          // ======================================================================
          AnimatedBuilder(
            animation: _neonAnimController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -40 + _bgFloatAnimation.value, 
                    left: -80,
                    child: Container(
                      width: 260, 
                      height: 260, 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF48CAE4).withOpacity(0.18), 
                            blurRadius: 110
                          )
                        ]
                      )
                    ),
                  ),
                  Positioned(
                    bottom: 80 - _bgFloatAnimation.value, 
                    right: -80,
                    child: Container(
                      width: 300, 
                      height: 300, 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9D4EDD).withOpacity(0.18), 
                            blurRadius: 130
                          )
                        ]
                      )
                    ),
                  ),
                ],
              );
            },
          ),

          // ======================================================================
          // 🏆 VISTA DE SCROLL Y CUADRÍCULA DE MEDALLAS
          // ======================================================================
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                backgroundColor: const Color(0xFF151522).withOpacity(0.4),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "SALA DE TROFEOS 🏆", 
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 20, color: Colors.white)
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF9D4EDD), Color(0xFF5E60CE), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Icon(Icons.stars_rounded, size: 65, color: Colors.white.withOpacity(0.12)),
                      ),
                    ),
                  ),
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: GameDbService.obtenerLogrosUsuario(widget.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF48CAE4)))
                    );
                  }
                  final logros = snapshot.data ?? [];
                  
                  // Filtramos el Logro Oculto ID 99 (Viajero del tiempo)
                  final logrosVisibles = logros.where((item) {
                    if (item['id'] == 99 && item['desbloqueado'] == false) {
                      return false; 
                    }
                    return true; 
                  }).toList();
                  
                  if (logrosVisibles.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text("¡No hay trofeos registrados en el cosmos!", style: GoogleFonts.nunito(color: Colors.white54, fontSize: 16))
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 25, bottom: 40),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.70, 
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final l = logrosVisibles[index]; 
                          final bool isLocked = !l['desbloqueado'];
                          
                          return AnimatedBuilder(
                            animation: _neonAnimController,
                            builder: (context, child) {
                              // Generamos un flote asincrónico usando ondas de seno basadas en el índice
                              final double delay = index * 0.6;
                              final double floatOffset = math.sin((_neonAnimController.value * math.pi * 2) + delay) * 5.0;

                              return Transform.translate(
                                offset: Offset(0, floatOffset),
                                child: TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 350 + (index * 80)),
                                  curve: Curves.easeOutBack,
                                  builder: (context, scaleValue, child) => Transform.scale(scale: scaleValue, child: child),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isLocked 
                                              ? Colors.black.withOpacity(0.4) 
                                              : cardColor.withOpacity(0.75),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: isLocked 
                                                ? Colors.white10 
                                                : accentColor.withOpacity(0.6),
                                            width: isLocked ? 1.5 : 2.5
                                          ),
                                          boxShadow: isLocked ? [] : [
                                            BoxShadow(
                                              color: accentColor.withOpacity(0.12), 
                                              blurRadius: 15, 
                                              spreadRadius: 1
                                            )
                                          ]
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Opacity(
                                              opacity: isLocked ? 0.25 : 1.0,
                                              child: Container(
                                                padding: const EdgeInsets.all(12), 
                                                decoration: BoxDecoration(
                                                  color: isLocked ? Colors.transparent : accentColor.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                  boxShadow: isLocked ? [] : [
                                                    BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 10)
                                                  ]
                                                ),
                                                child: Text(l['icono'], style: const TextStyle(fontSize: 42)), 
                                              ),
                                            ),
                                            const SizedBox(height: 12), 
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                              child: Text(
                                                l['titulo'], 
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis, 
                                                style: GoogleFonts.fredoka(
                                                  color: isLocked ? Colors.white38 : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15 
                                                )
                                              ),
                                            ),
                                            const SizedBox(height: 6), 
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 14),
                                              child: Text(
                                                l['descripcion'],
                                                textAlign: TextAlign.center,
                                                maxLines: 3, 
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.nunito(
                                                  color: isLocked ? Colors.white24 : Colors.white60, 
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.2
                                                )
                                              ),
                                            ),
                                            if (isLocked)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 10), 
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFF6B6B).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(10)
                                                  ),
                                                  child: Text(
                                                    "Faltan ⭐ ${l['requisito']}", 
                                                    style: GoogleFonts.fredoka(color: const Color(0xFFFF6B6B), fontSize: 10, fontWeight: FontWeight.bold)
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: logrosVisibles.length, 
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}