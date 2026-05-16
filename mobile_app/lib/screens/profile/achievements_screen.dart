import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/neon_db_service.dart';

class AchievementsScreen extends StatelessWidget {
  final int userId;
  const AchievementsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151522),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF151522),
            flexibleSpace: FlexibleSpaceBar(
              title: Text("SALA DE TROFEOS", 
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, letterSpacing: 2)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9D4EDD), Color(0xFF151522)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: NeonDbService.obtenerLogrosUsuario(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              final logros = snapshot.data ?? [];
              
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final l = logros[index];
                      final bool isLocked = !l['desbloqueado'];
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.black26 : const Color(0xFF222232),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isLocked ? Colors.transparent : const Color(0xFFFFD93D),
                            width: 2
                          ),
                          boxShadow: isLocked ? [] : [
                            BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.2), blurRadius: 10)
                          ]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l['icono'], style: TextStyle(fontSize: 50, color: isLocked ? Colors.grey : null)),
                            const SizedBox(height: 10),
                            Text(l['titulo'], 
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                color: isLocked ? Colors.white38 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              )
                            ),
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(l['descripcion'],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(color: Colors.white54, fontSize: 10)
                              ),
                            ),
                            if (isLocked)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text("Faltan ⭐ ${l['requisito']}", 
                                  style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    },
                    childCount: logros.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}