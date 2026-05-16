import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications_screen.dart';
import 'help_screen.dart';

import '../../services/neon_db_service.dart'; 
import 'change_name_screen.dart'; 

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  // Sin valores quemados
  String _name = "";
  int _age = 0;
  int _estrellas = 0;
  String _level = "";
  String _avatarPath = ''; 
  String _featuredSubject = "";
  
  bool _isLoading = true; 
  bool _isUpdatingAvatar = false; 

  final List<String> _misAvataresDisponibles = [
    'assets/avatars/avatar1.png', 
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png', 
    'assets/avatars/avatar4.png', 
    'assets/avatars/avatar5.png',
    'assets/avatars/avatar6.png',
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
      final perfilData = await NeonDbService.obtenerPerfilUsuario(userId);

      if (mounted && perfilData != null) {
        setState(() {
          _name = perfilData['name'] ?? 'Usuario';
          _estrellas = perfilData['estrellas'] ?? 0;
          _avatarPath = perfilData['avatar'] ?? 'assets/avatars/avatar1.png';
          
          String? materiaDb = perfilData['materia_fuerte'];
          if (materiaDb != null && materiaDb.isNotEmpty) {
            _featuredSubject = materiaDb;
          } else {
            _featuredSubject = "Aún no has empezado";
          }
          
          int grado = perfilData['grade'] ?? 1;
          _age = grado + 5; 

          String role = perfilData['role'] ?? 'student';
          if (role == 'admin') {
            _level = "Administrador del Sistema";
          } else {
            _level = "Explorador (Grado $gradoº)";
          }

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
      bool exito = await NeonDbService.actualizarAvatarUsuario(userId, nuevoPathElegido);

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
              Container(
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              Text(
                "Elige tu nuevo aspecto", 
                style: GoogleFonts.fredoka(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black
                )
              ),
              const SizedBox(height: 5),
              Text(
                "Toca un avatar para seleccionarlo", 
                style: GoogleFonts.nunito(color: Colors.grey, fontSize: 16)
              ),
              const SizedBox(height: 25),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _misAvataresDisponibles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    mainAxisSpacing: 15, 
                    crossAxisSpacing: 15, 
                    childAspectRatio: 1, 
                  ),
                  itemBuilder: (context, index) {
                    final String pathOpcion = _misAvataresDisponibles[index];
                    final bool esElActual = (_avatarPath == pathOpcion);

                    return GestureDetector(
                      onTap: () => _confirmarYGuardarAvatar(pathOpcion),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: esElActual ? accentColor : Colors.transparent,
                            width: esElActual ? 4 : 0,
                          ),
                          boxShadow: esElActual ? [
                            BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))
                          ] : [],
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(pathOpcion),
                          backgroundColor: isDark ? const Color(0xFF151522) : Colors.grey.shade100,
                        ),
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
        backgroundColor: colorBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = const Color(0xFF48CAE4);
    final Color bgColor = isDark ? const Color(0xFF151522) : const Color(0xFFF4F6F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          "Mi Perfil Espacial", 
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : Colors.black
          )
        ),
        centerTitle: true,
      ),
      body: (_isLoading || _isUpdatingAvatar)
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 135, height: 135, 
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor, width: 4),
                            boxShadow: [
                              BoxShadow(color: accentColor.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 25)
                            ]
                          ),
                          child: CircleAvatar(
                            // _avatarPath ya está cargado 100% de la BD
                            backgroundImage: AssetImage(_avatarPath), 
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        GestureDetector(
                          onTap: _mostrarSelectorDeAvatarModal, 
                          child: CircleAvatar(
                            backgroundColor: accentColor,
                            radius: 22, 
                            child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 22),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _name, 
                    style: GoogleFonts.fredoka(
                      fontSize: 30, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black
                    )
                  ),
                  Text(_level, style: GoogleFonts.nunito(color: accentColor, fontWeight: FontWeight.w800, fontSize: 17)),
                  
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("Edad est.", "$_age años", Icons.cake_rounded, Colors.orange, isDark),
                      _buildStatCard("Estrellas", "$_estrellas", Icons.star_rounded, Colors.amber, isDark),
                    ],
                  ),

                  const SizedBox(height: 25),

                  _buildFeaturedSubjectCard(_featuredSubject, isDark),

                  const SizedBox(height: 25),

                  _buildSettingItem(Icons.person_outline_rounded, "Cambiar nombre", "Edita tu nombre de explorador", isDark, () async {
                    final nuevoNombre = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNameScreen(currentName: _name),
                      ),
                    );

                    if (nuevoNombre != null && nuevoNombre.toString().isNotEmpty) {
                      setState(() {
                        _name = nuevoNombre;
                      });
                    }
                  }),
_buildSettingItem(Icons.notifications_none_rounded, "Notificaciones", "Alertas de nuevas misiones", isDark, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>  NotificationsScreen()),
                    );
                  }),
                  
                  // Se eliminó el botón de Privacidad
                  
                  _buildSettingItem(Icons.help_outline_rounded, "Ayuda", "Soporte técnico de App Tec", isDark, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpScreen()),
                    );
                  }),
                  const SizedBox(height: 40),
                  
                  Text("D.A.E.A Studio - v1.0.2", style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222232) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value, 
            style: GoogleFonts.fredoka(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black
            )
          ),
          Text(label, style: GoogleFonts.nunito(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFeaturedSubjectCard(String subject, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF48CAE4).withOpacity(0.2), const Color(0xFF5E60CE).withOpacity(0.15)]
                         : [Colors.cyan.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF48CAE4).withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: Color(0xFF48CAE4), size: 45),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Materia Destacada", 
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black54
                  )
                ),
                Text(subject, style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF48CAE4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, bool isDark, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222232) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : Colors.grey.shade700, size: 22),
      ),
      title: Text(
        title, 
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: isDark ? Colors.white : Colors.black87
        )
      ),
      subtitle: Text(
        subtitle, 
        style: GoogleFonts.nunito(
          fontSize: 13,
          color: isDark ? Colors.white54 : Colors.black54
        )
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white54 : Colors.grey),
      onTap: onTap, 
    );
  }
}