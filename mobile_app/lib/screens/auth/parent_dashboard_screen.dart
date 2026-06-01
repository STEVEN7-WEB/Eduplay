import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; 
import '../../services/neon_db/user_db_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  List<Map<String, dynamic>> _estudiantes = [];
  bool _isLoading = true;
  String _correoTutor = "";

  @override
  void initState() {
    super.initState();
    _cargarDatosHijos();
  }

  Future<void> _cargarDatosHijos() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('parentEmail') ?? '';

    setState(() {
      _correoTutor = email;
    });

    if (email.isNotEmpty) {
      final estudiantesDb = await UserDbService.obtenerEstudiantesDelPadre(email);
      
      if (mounted) {
        setState(() {
          _estudiantes = estudiantesDb;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  // --- MODAL PARA VER EL PROGRESO Y RESULTADO KNN DEL NIÑO ---
  void _mostrarDetallesDelNino(int studentId, String nombre, String avatarPath) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF222232) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Para que el borde redondeado se vea bien
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            return FutureBuilder<Map<String, dynamic>?>(
              future: UserDbService.obtenerResumenActividad(studentId),
              builder: (context, snapshot) {
                
                // 1. ESTADO DE CARGA
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(35))
                    ),
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFF48CAE4))),
                  );
                }

                // 2. ESTADO DE ERROR DE CONEXIÓN
                if (snapshot.hasError || snapshot.data == null) {
                  return Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(35))
                    ),
                    child: Center(
                      child: Text(
                        "Error al conectar con la base de datos 🔌",
                        style: GoogleFonts.nunito(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  );
                }

                final stats = snapshot.data!;
                
                final misiones = stats['total_misiones'] ?? 0;
                final materiaTop = (stats['materia_top'] == null || stats['materia_top'].toString().isEmpty) 
                                    ? "Por descubrir" 
                                    : stats['materia_top'];
                
                // Extraemos el mapa de puntajes de todas las materias
                final Map<String, dynamic> mapaPuntajes = stats['tabla_puntajes'] ?? {};
                
                final resultadoKnn = stats['knn_resultado'] ?? "Analizando datos..."; 
                final promedioKnn = stats['knn_promedio'] ?? "N/A"; 
                final recomendacionKnn = stats['knn_recomendacion'] ?? "Juega más misiones para evaluar."; 

                // 3. UI DEL MODAL COMPLETO
                return Container(
                  height: MediaQuery.of(context).size.height * 0.85, // Ocupa el 85% de la pantalla
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(35))
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      // Barrita superior arrastrable
                      Container(
                        width: 50, height: 5,
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                      ),
                      
                      // Contenido scrolleable
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: isDarkMode ? const Color(0xFF151522) : Colors.grey.shade100,
                                backgroundImage: AssetImage(avatarPath),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "Expediente de $nombre", 
                                textAlign: TextAlign.center,
                                style: GoogleFonts.fredoka(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)
                              ),
                              const SizedBox(height: 25),
                              
                              // --- BLOQUE 1: ESTADÍSTICAS BÁSICAS ---
                              Row(
                                children: [
                                  Expanded(child: _buildStatCard("Misiones", misiones.toString(), Icons.rocket_launch_rounded, const Color(0xFF9D4EDD), isDarkMode)),
                                  const SizedBox(width: 15),
                                  Expanded(child: _buildStatCard("Materia Top", materiaTop, Icons.star_rounded, const Color(0xFFFFD93D), isDarkMode)),
                                ],
                              ),
                              const SizedBox(height: 25),

                              // --- BLOQUE 2: DESGLOSE COMPLETO POR MATERIAS ---
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Desglose de Materias",
                                  style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ),
                              const SizedBox(height: 10),
                              
                              if (mapaPuntajes.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Aún no hay puntuaciones registradas. ¡Es hora de jugar!",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(color: isDarkMode ? Colors.white54 : Colors.black54),
                                  ),
                                )
                              else
                                ...mapaPuntajes.entries.map((entry) {
                                  // Asigna iconos dependiendo de la materia (puedes agregar más)
                                  IconData iconoMateria = Icons.menu_book_rounded;
                                  if (entry.key.contains("mate")) iconoMateria = Icons.calculate_rounded;
                                  if (entry.key.contains("español")) iconoMateria = Icons.sort_by_alpha_rounded;
                                  if (entry.key.contains("historia")) iconoMateria = Icons.account_balance_rounded;
                                  if (entry.key.contains("ciencia")) iconoMateria = Icons.science_rounded;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: isDarkMode ? const Color(0xFF333344) : Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(iconoMateria, color: const Color(0xFF48CAE4), size: 24),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Text(
                                            entry.key[0].toUpperCase() + entry.key.substring(1), 
                                            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                          ),
                                        ),
                                        Text(
                                          "${entry.value} pts",
                                          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFFD93D)),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              
                              const SizedBox(height: 25),

                              // --- BLOQUE 3: ANÁLISIS DE IA (KNN) ---
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F0FF).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.4), width: 1.5),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.psychology_rounded, color: Color(0xFF00F0FF), size: 28),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Análisis de IA (KNN)", 
                                          style: GoogleFonts.fredoka(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Nivel de Aprendizaje Detectado:", 
                                      style: GoogleFonts.nunito(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 13)
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      resultadoKnn.toString(), 
                                      style: GoogleFonts.fredoka(color: const Color(0xFF00F0FF), fontSize: 22, fontWeight: FontWeight.bold), 
                                      textAlign: TextAlign.center
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      recomendacionKnn.toString(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.nunito(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 14, fontStyle: FontStyle.italic),
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.analytics_outlined, color: Colors.grey, size: 16),
                                        const SizedBox(width: 5),
                                        Text("Promedio general: $promedioKnn", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    )
                                  ],
                                )
                              ),
                              
                              const SizedBox(height: 30),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF48CAE4),
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                  elevation: 0,
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text("Cerrar Expediente", style: GoogleFonts.fredoka(color: const Color(0xFF151522), fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          }
        );
      }
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value, 
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.nunito(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E1E2E);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Panel de Tutor", 
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: textColor)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFFF6B6B)),
            onPressed: _cerrarSesion,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF48CAE4)))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¡Hola, Tutor!",
                      style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Supervisando la cuenta: $_correoTutor",
                      style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF48CAE4), fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Toca a un explorador para ver su progreso estelar 🚀",
                      style: GoogleFonts.nunito(fontSize: 16, color: isDarkMode ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _estudiantes.isEmpty
                  ? Center(
                      child: Text("Aún no tienes exploradores registrados.", style: GoogleFonts.nunito(color: Colors.grey)),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _estudiantes.length,
                      itemBuilder: (context, index) {
                        final nino = _estudiantes[index];
                        return _buildStudentCard(nino, isDarkMode);
                      },
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> nino, bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF222232) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF333344) : Colors.grey.shade300;

    return GestureDetector(
      onTap: () => _mostrarDetallesDelNino(nino['id'], nino['name'], nino['avatar']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isDarkMode ? const Color(0xFF151522) : Colors.grey.shade100,
              backgroundImage: AssetImage(nino['avatar']),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nino['name'],
                    style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  Text(
                    "Grado: ${nino['grade']}º",
                    style: GoogleFonts.nunito(fontSize: 14, color: isDarkMode ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD93D).withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 18),
                  const SizedBox(width: 5),
                  Text(
                    "${nino['estrellas']}",
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFFFFD93D), fontSize: 16),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}