import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/neon_db_service.dart';
import '../../main.dart'; // ¡Importante para cambiar el tema global!
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'parent_dashboard_screen.dart'; // Importamos la nueva pantalla de padres

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identificadorController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  bool _isLoading = false;
  bool _isParentMode = false; // Variable mágica para detectar modo padre/alumno

  @override
  void dispose() {
    _identificadorController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final newMode = !isDarkMode; 
    themeNotifier.value = newMode ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('isDarkMode', newMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E1E2E);
    final subtitleColor = isDarkMode ? const Color(0xFF48CAE4) : const Color(0xFF0096C7);
    final cardColor = isDarkMode ? const Color(0xFF222232) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20, top: 10),
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode ? const Color(0xFFFFD93D).withOpacity(0.5) : const Color(0xFF5E60CE).withOpacity(0.5), 
                width: 1.5
              ),
            ),
            child: IconButton(
              onPressed: _toggleTheme, 
              icon: Icon(
                isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                color: isDarkMode ? const Color(0xFFFFD93D) : const Color(0xFF5E60CE), 
                size: 22
              )
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 120, width: 120,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9D4EDD).withOpacity(0.4),
                          blurRadius: 25, spreadRadius: 2,
                        )
                      ],
                      border: Border.all(color: const Color(0xFF9D4EDD), width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.rocket_launch_rounded, size: 60, color: Color(0xFF9D4EDD)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _isParentMode ? "¡HOLA, TUTOR!" : "¡HOLA!",
                    style: GoogleFonts.fredoka(color: textColor, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  Text(
                    _isParentMode ? "Accede al panel de control" : "¡Listo para otra misión!",
                    style: GoogleFonts.nunito(color: subtitleColor, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 30),
                  _buildLoginBox(isDarkMode),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: Text(
                      "¿Eres nuevo? ¡Crea tu perfil aquí! ✨",
                      style: GoogleFonts.nunito(
                        color: isDarkMode ? const Color(0xFFFFD93D) : const Color(0xFFE8B900), 
                        fontWeight: FontWeight.w800, fontSize: 16
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
  }

  Widget _buildLoginBox(bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF222232) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF333344) : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          // Campo 1: Identificador
          _buildIdentificadorField(isDarkMode),
          const SizedBox(height: 15),
          // Campo 2: PIN o Contraseña dependiendo del modo
          _buildPasswordField(isDarkMode),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD),
                elevation: 8,
                shadowColor: const Color(0xFF9D4EDD).withOpacity(0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _isLoading ? null : _login,
              child: _isLoading 
                ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text("ENTRAR 🚀", style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificadorField(bool isDarkMode) {
    final fillColor = isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.white38 : Colors.black38;
    final neonColor = const Color(0xFF4ECDC4);

    return TextFormField(
      controller: _identificadorController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.w700, fontSize: 18),
      onChanged: (value) {
        // Detecta arroba
        setState(() {
          _isParentMode = value.contains('@');
        });
      },
      validator: (value) => (value == null || value.trim().isEmpty) ? '¡Falta este dato!' : null,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.person_outline_rounded, color: neonColor, size: 28),
        hintText: "Usuario o Correo",
        hintStyle: GoogleFonts.nunito(color: hintColor, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: neonColor, width: 2)),
      ),
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    final fillColor = isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.white38 : Colors.black38;
    final neonColor = const Color(0xFFFF6B6B);

    return TextFormField(
      controller: _passController,
      obscureText: true,
      keyboardType: _isParentMode ? TextInputType.text : TextInputType.number,
      inputFormatters: _isParentMode ? [] : [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.w700, fontSize: 18),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '¡Falta este dato!';
        if (!_isParentMode && value.length < 4) return 'El PIN necesita 4 números';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_rounded, color: neonColor, size: 28),
        hintText: _isParentMode ? "Contraseña del Tutor" : "PIN Secreto",
        hintStyle: GoogleFonts.nunito(color: hintColor, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: neonColor, width: 2)),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    bool exito;
    if (_isParentMode) {
      exito = await NeonDbService.loginPorCorreo(_identificadorController.text.trim(), _passController.text.trim());
    } else {
      exito = await NeonDbService.loginPorNombre(_identificadorController.text.trim(), _passController.text.trim());
    }
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (exito) {
      if (_isParentMode) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboardScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Datos incorrectos ❌", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        )
      );
    }
  }
}