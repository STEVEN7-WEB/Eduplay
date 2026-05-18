import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- IMPORTANTE AGREGAR ESTO
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushEnabled = false;
  bool _emailEnabled = false;

  // --- NUEVO: Cargar configuración al iniciar la pantalla ---
  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('push_enabled') ?? false;
      _emailEnabled = prefs.getBool('email_enabled') ?? false;
    });
  }

  Future<void> _guardarPreferencia(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
  // -----------------------------------------------------------

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
          "Notificaciones",
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ajustes de Alertas", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
            const SizedBox(height: 15),
            
            // --- ACTUALIZADO: Switch de Notificaciones Push ---
            _buildSwitchTile("Notificaciones Push", "Recibe alertas de nuevas misiones en tu dispositivo", _pushEnabled, (val) async {
              setState(() => _pushEnabled = val);
              await _guardarPreferencia('push_enabled', val); // Se guarda en memoria

              if (val) {
                await NotificationService.pedirPermisos();
                await NotificationService.mostrarNotificacionInstantanea(
                  id: 0,
                  titulo: "¡Notificaciones Activadas! 🚀",
                  cuerpo: "EduPlay 2.0 te avisará de nuevas misiones.",
                );
                // Activar notificaciones periódicas
                await NotificationService.programarNotificacionPeriodica();
              } else {
                // Cancelar notificaciones si apaga el switch
                await NotificationService.cancelarTodasLasNotificaciones();
              }
            }, cardColor, accentColor, isDark),
            
            const SizedBox(height: 10),
            
            // --- ACTUALIZADO: Switch de Correos ---
            _buildSwitchTile("Correos Electrónicos", "Resumen semanal de tu progreso", _emailEnabled, (val) async {
              setState(() => _emailEnabled = val);
              await _guardarPreferencia('email_enabled', val); // Se guarda en memoria
            }, cardColor, accentColor, isDark),
            
            const SizedBox(height: 35),
            Text("Historial Reciente", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
            const SizedBox(height: 15),
            _buildNotificationItem("¡Misión Completada!", "Ganaste 10 estrellas en Matemáticas.", Icons.star_rounded, Colors.amber, cardColor, isDark),
            _buildNotificationItem("Nuevo Logro", "Desbloqueaste el título 'Explorador Espacial'.", Icons.emoji_events_rounded, const Color(0xFF9D4EDD), cardColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, Color cardColor, Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(isDark ? 0.2 : 0.1))),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: accentColor,
        title: Text(title, style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNotificationItem(String title, String desc, IconData icon, Color iconColor, Color cardColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : Colors.black87)),
                Text(desc, style: GoogleFonts.nunito(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}