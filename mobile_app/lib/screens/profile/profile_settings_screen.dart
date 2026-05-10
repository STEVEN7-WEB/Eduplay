import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Descomenta si vas a usar SharedPreferences aquí

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  // Variables de ejemplo para el perfil
  final String _name = "Steven";
  final int _age = 10;
  final String _featuredSubject = "Matemáticas";
  final int _missionsDone = 42;
  final String _level = "Explorador Galáctico";

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = const Color(0xFF48CAE4); // Cian Neón
    final Color bgColor = isDark ? const Color(0xFF151522) : const Color(0xFFF4F6F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          "Mi Perfil", 
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : Colors.black
          )
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // --- HEADER DE PERFIL ---
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 4),
                      boxShadow: [
                        BoxShadow(color: accentColor.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 20)
                      ]
                    ),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage('assets/avatars/avatar1.png'), // Asegúrate de que la ruta exista
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  // Botón para cambiar avatar
                  CircleAvatar(
                    backgroundColor: accentColor,
                    radius: 18,
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _name, 
              style: GoogleFonts.fredoka(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black
              )
            ),
            Text(_level, style: GoogleFonts.nunito(color: accentColor, fontWeight: FontWeight.w700, fontSize: 16)),
            
            const SizedBox(height: 30),

            // --- SECCIÓN DE ESTADÍSTICAS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Edad", "$_age años", Icons.cake_rounded, Colors.orange, isDark),
                _buildStatCard("Misiones", "$_missionsDone", Icons.auto_awesome_rounded, Colors.purpleAccent, isDark),
              ],
            ),

            const SizedBox(height: 25),

            // --- APARTADO DE MATERIA DESTACADA ---
            _buildFeaturedSubjectCard(_featuredSubject, isDark),

            const SizedBox(height: 25),

            // --- LISTA DE OPCIONES / CONFIGURACIÓN ---
            _buildSettingItem(Icons.person_outline_rounded, "Cambiar nombre", "Edita cómo te llamamos", isDark),
            _buildSettingItem(Icons.notifications_none_rounded, "Notificaciones", "Alertas de nuevas misiones", isDark),
            _buildSettingItem(Icons.security_rounded, "Privacidad", "Configuración de cuenta", isDark),
            _buildSettingItem(Icons.help_outline_rounded, "Ayuda", "Soporte técnico de App Tec", isDark),
            
            const SizedBox(height: 40),
            
            // Versión de la app
            Text("D.A.E.A Studio - v1.0.2", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222232) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value, 
            style: GoogleFonts.fredoka(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black
            )
          ),
          Text(label, style: GoogleFonts.nunito(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFeaturedSubjectCard(String subject, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF48CAE4).withOpacity(0.2), const Color(0xFF5E60CE).withOpacity(0.2)]
                         : [Colors.cyan.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF48CAE4).withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFF48CAE4), size: 40),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Materia Destacada", 
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54
                )
              ),
              Text(subject, style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF48CAE4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222232) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : Colors.grey.shade700),
      ),
      title: Text(
        title, 
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87
        )
      ),
      subtitle: Text(
        subtitle, 
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54
        )
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white54 : Colors.grey),
      onTap: () {
        // Lógica para abrir cada configuración en el futuro
      },
    );
  }
}