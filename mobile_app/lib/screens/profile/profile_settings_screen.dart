import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import 'notifications_screen.dart';
import 'help_screen.dart';
import '../../services/neon_db/user_db_service.dart'; 
import '../../services/neon_db/auth_db_service.dart'; 
import 'change_name_screen.dart'; 

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _name = "";
  int _estrellas = 0;
  String _avatarPath = ''; 
  String _role = "";
  int _grade = 1; // Guardamos el grado del usuario
  
  bool _isLoading = true; 
  bool _isUpdatingAvatar = false; 

  final List<String> _misAvataresDisponibles = [
    'assets/avatars/avatar1.png', 'assets/avatars/avatar2.png', 'assets/avatars/avatar3.png', 
    'assets/avatars/avatar4.png', 'assets/avatars/avatar5.png', 'assets/avatars/avatar6.png',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeBD();
  }

  Future<void> _cargarDatosDesdeBD() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('id_usuario');

    if (userId != null) {
      final perfilData = await UserDbService.obtenerPerfilUsuario(userId);

      if (mounted && perfilData != null) {
        setState(() {
          _name = perfilData['name'] ?? 'Usuario';
          _estrellas = perfilData['estrellas'] ?? 0;
          _avatarPath = perfilData['avatar'] ?? 'assets/avatars/avatar1.png';
          _role = perfilData['role'] ?? 'student';
          _grade = perfilData['grade'] ?? 1; // Obtenemos el grado para usarlo como Nivel
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false); 
      }
    } else {
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  Future<void> _confirmarYGuardarAvatar(String nuevoPathElegido) async {
    Navigator.pop(context);
    setState(() => _isUpdatingAvatar = true);

    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('id_usuario');

    if (userId != null) {
      bool exito = await UserDbService.actualizarAvatarUsuario(userId, nuevoPathElegido);

      if (!mounted) return;

      if (exito) {
        setState(() {
          _avatarPath = nuevoPathElegido;
          _isUpdatingAvatar = false;
        });
        _mostrarFeedbackVisual("¡Avatar actualizado espacialmente!", const Color(0xFF4ECDC4));
      } else {
        setState(() => _isUpdatingAvatar = false);
        _mostrarFeedbackVisual("Error de conexión 🔌 No se guardó.", const Color(0xFFFF6B6B));
      }
    } else {
       setState(() => _isUpdatingAvatar = false);
    }
  }

  void _mostrarSelectorDeAvatarModal() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = const Color(0xFF48CAE4);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: isDark ? const Color(0xFF222232) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text("Elige tu nuevo aspecto", style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 5),
              Text("Toca un avatar para seleccionarlo", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 25),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(), itemCount: _misAvataresDisponibles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 1),
                  itemBuilder: (context, index) {
                    final String pathOpcion = _misAvataresDisponibles[index];
                    final bool esElActual = (_avatarPath == pathOpcion);

                    return GestureDetector(
                      onTap: () => _confirmarYGuardarAvatar(pathOpcion),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: esElActual ? accentColor : Colors.transparent, width: esElActual ? 4 : 0),
                          boxShadow: esElActual ? [BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))] : [],
                        ),
                        child: CircleAvatar(backgroundImage: AssetImage(pathOpcion), backgroundColor: isDark ? const Color(0xFF151522) : Colors.grey.shade100),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  void _mostrarFeedbackVisual(String mensaje, Color colorBg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, textAlign: TextAlign.center, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: colorBg, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
      )
    );
  }

  // Cuadro de diálogo de seguridad antes de eliminar
  void _mostrarDialogoEliminarCuenta() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222232) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("¿Eliminar cuenta?", style: GoogleFonts.fredoka(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
          content: Text("Esta acción borrará todo tu progreso de forma permanente y no se puede deshacer. ¿Estás completamente seguro?", style: GoogleFonts.nunito()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar", style: GoogleFonts.nunito(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () async {
                Navigator.pop(context); // Cierra el diálogo
                setState(() => _isLoading = true);

                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getInt('id_usuario');

                if (userId != null) {
                  // Conectado al nuevo servicio
                  await UserDbService.eliminarCuenta(userId);
                }
                
                await AuthDbService.cerrarSesion();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                }
              },
              child: Text("Sí, Eliminar", style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      }
    );
  }
  
  String _obtenerRango(int nivel) {
    if (_role == 'admin') return "Administrador Galáctico";
    if (nivel < 3) return "Recluta Espacial";
    if (nivel < 5) return "Explorador Estelar";
    if (nivel < 6) return "Comandante Galáctico";
    return "Maestro del Universo";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF4F6F9);
    final Color cardColor = isDark ? const Color(0xFF222232) : Colors.white;

    if (_isLoading || _isUpdatingAvatar) {
      return Scaffold(backgroundColor: bgColor, body: const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD))));
    }

    // --- LÓGICA DE NIVEL Y XP AJUSTADA A TUS PETICIONES ---
    int nivel = _grade; // El nivel mostrado ahora es exactamente el Grado
    int metaXP = 80;    // Máximo de XP configurado a 80
    // Evitamos que la barra visual sobrepase el 100% si el usuario junta más de 80 estrellas
    double progresoXP = (_estrellas / metaXP).clamp(0.0, 1.0);
    String rango = _obtenerRango(nivel);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        // Se quitó el actions: [] con el botón de ajustes
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.military_tech_rounded, size: 180, color: const Color(0xFFFFD93D).withOpacity(isDark ? 0.2 : 0.4)),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 140, height: 140, 
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, border: Border.all(color: const Color(0xFF9D4EDD), width: 4),
                          boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(isDark ? 0.4 : 0.2), blurRadius: 30)]
                        ),
                        child: CircleAvatar(backgroundImage: AssetImage(_avatarPath), backgroundColor: cardColor),
                      ),
                      GestureDetector(
                        onTap: _mostrarSelectorDeAvatarModal, 
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF48CAE4), shape: BoxShape.circle, border: Border.all(color: bgColor, width: 3)),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Muestra el nombre en grande
            Text(_name, style: GoogleFonts.fredoka(fontSize: 34, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 5),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 28),
                const SizedBox(width: 8),
                Text(rango, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF48CAE4))),
              ],
            ),
            const SizedBox(height: 35),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Nivel $nivel", style: GoogleFonts.fredoka(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("${_estrellas.toString()} / ${metaXP.toString()} XP", style: GoogleFonts.nunito(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 12, width: double.infinity,
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF151522) : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic,
                  height: 12, width: MediaQuery.of(context).size.width * 0.85 * progresoXP,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD93D), borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.5), blurRadius: 10)]
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            _buildSettingItem(Icons.person_outline_rounded, "Cambiar nombre", "Edita tu nombre de explorador", isDark, () async {
              final nuevoNombre = await Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeNameScreen(currentName: _name)));
              if (nuevoNombre != null && nuevoNombre.toString().isNotEmpty) {
                setState(() => _name = nuevoNombre);
              }
            }),
            _buildSettingItem(Icons.notifications_none_rounded, "Notificaciones", "Alertas de nuevas misiones", isDark, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            }),
            _buildSettingItem(Icons.help_outline_rounded, "Ayuda", "Soporte técnico de App Tec", isDark, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
            }),

            const SizedBox(height: 15),

            // --- BOTÓN ROJO DE ELIMINAR CUENTA ---
            GestureDetector(
              onTap: _mostrarDialogoEliminarCuenta,
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.5))
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF6B6B), size: 24),
                  ),
                  title: Text("Eliminar cuenta", style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 18, color: const Color(0xFFFF6B6B))),
                  subtitle: Text("Borrar todos los datos", style: GoogleFonts.nunito(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text("D.A.E.A Studio - v1.0.2", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222232) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(isDark ? 0.2 : 0.1))
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF9D4EDD).withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF9D4EDD), size: 24),
        ),
        title: Text(title, style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: isDark ? Colors.white54 : Colors.grey),
        onTap: onTap, 
      ),
    );
  }
}