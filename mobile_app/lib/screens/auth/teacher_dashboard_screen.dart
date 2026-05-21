import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; 
import '../../services/neon_db/user_db_service.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  List<Map<String, dynamic>> _alumnos = [];
  bool _isLoading = true;
  String _nombreMaestro = "Profesor(a)";

  @override
  void initState() {
    super.initState();
    _cargarDatosClase();
  }

  Future<void> _cargarDatosClase() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('userName') ?? 'Profesor(a)';

    setState(() {
      _nombreMaestro = nombre;
    });

    final estudiantesDb = await UserDbService.obtenerTodosLosEstudiantesParaMaestro();
    
    if (mounted) {
      setState(() {
        _alumnos = estudiantesDb;
        _isLoading = false;
      });
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
          "Centro de Control Escolar", 
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
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¡Hola, $_nombreMaestro!",
                      style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Resumen general de tu grupo de exploradores 🛸",
                      style: GoogleFonts.nunito(fontSize: 15, color: isDarkMode ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _alumnos.isEmpty
                  ? Center(
                      child: Text("No hay alumnos registrados en la base de datos.", style: GoogleFonts.nunito(color: Colors.grey)),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _alumnos.length,
                      itemBuilder: (context, index) {
                        final alumno = _alumnos[index];
                        return _buildTeacherStudentCard(alumno, isDarkMode);
                      },
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildTeacherStudentCard(Map<String, dynamic> alumno, bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF222232) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF333344) : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        children: [
          // Encabezado: Avatar, Nombre y Grado
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isDarkMode ? const Color(0xFF151522) : Colors.grey.shade100,
                backgroundImage: AssetImage(alumno['avatar']),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumno['name'],
                      style: GoogleFonts.fredoka(fontSize: 19, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                    Text(
                      "Grado: ${alumno['grade']}º",
                      style: GoogleFonts.nunito(fontSize: 14, color: isDarkMode ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.grey, height: 1, thickness: 0.2),
          ),

          // Fila del Medio: Materia Top y Estrellas
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch_rounded, color: Color(0xFF9D4EDD), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Fuerte en: ${alumno['materia_top']}",
                        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "${alumno['estrellas']}",
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFFFFD93D), fontSize: 14),
                    )
                  ],
                ),
              )
            ],
          ),
          
          const SizedBox(height: 15),

          // Sección Inferior: Resultado KNN (Inteligencia Artificial)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Color(0xFF00F0FF), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Diagnóstico IA (KNN)",
                        style: GoogleFonts.nunito(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black54),
                      ),
                      Text(
                        alumno['knn_etiqueta'],
                        style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Promedio",
                      style: GoogleFonts.nunito(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black54),
                    ),
                    Text(
                      alumno['knn_promedio'],
                      style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}