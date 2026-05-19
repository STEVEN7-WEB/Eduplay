import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = const Color(0xFF48CAE4);
    final Color bgColor = isDark ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final Color cardColor = isDark ? const Color(0xFF222232) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          "Centro de Ayuda",
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF5E60CE).withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF5E60CE).withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 60, color: Color(0xFF5E60CE)),
                  const SizedBox(height: 15),
                  Text("Soporte D.A.E.A Studio", style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 5),
                  Text(
                    "Si tienes problemas con EduPlay 2.0, ponte en contacto con nosotros en daea.studio@gmail.com",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Preguntas Frecuentes", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
            ),
            const SizedBox(height: 15),
            _buildFaqTile("¿Cómo gano estrellas?", "Las estrellas se ganan al completar misiones correctamente. ¡Entre más respuestas correctas, más estrellas ganas!", cardColor, accentColor, isDark),
            _buildFaqTile("¿Para qué sirven los logros?", "Los logros demuestran tu progreso en la plataforma. Colecciónalos todos para convertirte en el mejor explorador.", cardColor, accentColor, isDark),
            _buildFaqTile("Mi pantalla se quedó cargando", "Verifica tu conexión a internet o intenta reiniciar la aplicación. Si el problema persiste, contacta a soporte.", cardColor, accentColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer, Color cardColor, Color accentColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(isDark ? 0.2 : 0.1)),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent), // Quita la línea de división nativa
        child: ExpansionTile(
          iconColor: accentColor,
          collapsedIconColor: isDark ? Colors.white54 : Colors.grey,
          title: Text(
            question,
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
              child: Text(
                answer,
                style: GoogleFonts.nunito(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}