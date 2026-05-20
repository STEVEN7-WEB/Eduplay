import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/neon_db/game_db_service.dart';

class ResultadosIAView extends StatefulWidget {
  final bool isDarkMode;
  const ResultadosIAView({required this.isDarkMode, super.key});

  @override
  State<ResultadosIAView> createState() => _ResultadosIAViewState();
}

class _ResultadosIAViewState extends State<ResultadosIAView> {
  late Future<List<Map<String, dynamic>>> _resultadosFuture;

  @override
  void initState() {
    super.initState();
    _cargarResultados();
  }

  void _cargarResultados() {
    setState(() {
      _resultadosFuture = GameDbService.obtenerTodosResultadosKNN();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _resultadosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF48CAE4)));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error al cargar los diagnósticos", style: GoogleFonts.nunito(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No hay diagnósticos guardados aún.", style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey)));
          }

          final resultados = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _cargarResultados(),
            color: const Color(0xFF48CAE4),
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: resultados.length,
              itemBuilder: (context, index) {
                final res = resultados[index];
                
                return Card(
                  color: widget.isDarkMode ? const Color(0xFF222232) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("ID Alumno: ${res['user_id']}", style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF48CAE4))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: const Color(0xFF9D4EDD).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text("Rango: ${res['rango']}", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: const Color(0xFF9D4EDD))),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text("Diagnóstico: ${res['etiqueta']}", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
                        const SizedBox(height: 5),
                        Text("Promedio General: ${res['promedio_general']}", style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Recomendación de la IA:", style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 5),
                              Text("${res['recomendacion']}", style: GoogleFonts.nunito(fontStyle: FontStyle.italic, color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}