import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/neon_db/auth_db_service.dart';
import '../../main.dart'; 
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'parent_dashboard_screen.dart'; 
import 'admin_dashboard.dart';
import 'recovery_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identificadorController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  bool _isLoading = false;
  bool _isParentOrAdminMode = false;

  // Controlador para las animaciones continuas (el logo flotante y el botón)
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    // Configuramos la animación de "respiración" o flotación
    _pulseController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2)
    )..repeat(reverse: true); // Se repite infinitamente yendo y viniendo

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine)
    );
  }

  @override
  void dispose() {
    _identificadorController.dispose();
    _passController.dispose();
    _pulseController.dispose(); // No olvides matar el controlador de animación
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
    final bgColor = isDarkMode ? const Color(0xFF0D0D1A) : const Color(0xFFF4F6F9);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E1E2E);
    final subtitleColor = isDarkMode ? const Color(0xFF48CAE4) : const Color(0xFF0096C7);
    final cardColor = isDarkMode ? const Color(0xFF222232) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // --- FONDOS CON LUCES DIFUMINADAS (ANIMADOS) ---
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100 + (_floatAnimation.value * 2), // El neón también se mueve un poco
                    left: -100,
                    child: Container(
                      width: 350, height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(isDarkMode ? 0.3 : 0.15), blurRadius: 150)]
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100 - (_floatAnimation.value * 2), 
                    right: -50,
                    child: Container(
                      width: 300, height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF48CAE4).withOpacity(isDarkMode ? 0.25 : 0.15), blurRadius: 150)]
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // --- BOTÓN TEMA ---
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.only(right: 20, top: 10),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDarkMode ? const Color(0xFFFFD93D).withOpacity(0.5) : const Color(0xFF5E60CE).withOpacity(0.5), width: 1.5),
                    ),
                    child: IconButton(
                      onPressed: _toggleTheme, 
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => RotationTransition(turns: anim, child: child),
                        child: Icon(
                          isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                          key: ValueKey(isDarkMode), // Clave para la animación
                          color: isDarkMode ? const Color(0xFFFFD93D) : const Color(0xFF5E60CE), 
                          size: 22
                        ),
                      )
                    ),
                  ),
                ),

                // --- CONTENIDO PRINCIPAL ---
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // --- LOGO ANIMADO (FLOTANDO) ---
                            AnimatedBuilder(
                              animation: _floatAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: Container(
                                    height: 130, width: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.4), blurRadius: 25, spreadRadius: 2)],
                                      border: Border.all(color: const Color(0xFF9D4EDD), width: 3),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/app_icon.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.rocket_launch_rounded, size: 60, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 25),
                            
                            // Textos de bienvenida
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isParentOrAdminMode ? "¡ACCESO ESPECIAL!" : "¡HOLA!",
                                key: ValueKey(_isParentOrAdminMode),
                                style: GoogleFonts.fredoka(color: textColor, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isParentOrAdminMode ? "Ingresa al panel de control" : "¡Listo para otra misión!",
                                key: ValueKey(_isParentOrAdminMode),
                                style: GoogleFonts.nunito(color: subtitleColor, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 35),
                            
                            // Caja de Login
                            _buildGlassLoginBox(isDarkMode, cardColor),
                            const SizedBox(height: 15),
                            
                            // --- BOTONES INFERIORES ---
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const RecoveryScreen()));
                              },
                              child: Text(
                                "¿Olvidaste tu contraseña o PIN? 🤔",
                                style: GoogleFonts.nunito(color: isDarkMode ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                              },
                              child: Text(
                                "¿Eres nuevo? ¡Crea tu perfil aquí! ✨",
                                style: GoogleFonts.nunito(
                                  color: isDarkMode ? const Color(0xFFFFD93D) : const Color(0xFFE8B900), 
                                  fontWeight: FontWeight.w900, fontSize: 17
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassLoginBox(bool isDarkMode, Color baseCardColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: baseCardColor.withOpacity(isDarkMode ? 0.6 : 0.8),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.5), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              _buildIdentificadorField(isDarkMode),
              const SizedBox(height: 15),
              _buildPasswordField(isDarkMode),
              const SizedBox(height: 30),
              
              // --- BOTÓN ENTRAR ANIMADO ---
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9D4EDD).withOpacity(0.4 + (_pulseController.value * 0.4)), // El brillo pulsa
                          blurRadius: 15 + (_pulseController.value * 10),
                          spreadRadius: 1,
                        )
                      ]
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9D4EDD),
                        elevation: 0, // Quitamos la elevación por defecto para usar nuestra sombra
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading 
                        ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : Text("ENTRAR 🚀", style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
                    ),
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentificadorField(bool isDarkMode) {
    final fillColor = isDarkMode ? const Color(0xFF151522).withOpacity(0.8) : const Color(0xFFF4F6F9);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.white54 : Colors.black38;
    const neonColor = Color(0xFF4ECDC4);

    return TextFormField(
      controller: _identificadorController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.w700, fontSize: 18),
      onChanged: (value) {
        setState(() => _isParentOrAdminMode = value.contains('@'));
      },
      validator: (value) => (value == null || value.trim().isEmpty) ? '¡Falta este dato!' : null,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.person_outline_rounded, color: neonColor, size: 28),
        hintText: "Usuario o Correo",
        hintStyle: GoogleFonts.nunito(color: hintColor, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: neonColor, width: 2)),
      ),
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    final fillColor = isDarkMode ? const Color(0xFF151522).withOpacity(0.8) : const Color(0xFFF4F6F9);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.white54 : Colors.black38;
    const neonColor = Color(0xFFFF6B6B);

    return TextFormField(
      controller: _passController,
      obscureText: true,
      keyboardType: _isParentOrAdminMode ? TextInputType.text : TextInputType.number,
      inputFormatters: _isParentOrAdminMode ? [] : [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.w700, fontSize: 18),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '¡Falta este dato!';
        if (!_isParentOrAdminMode && value.length < 4) return 'El PIN necesita 4 números';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_rounded, color: neonColor, size: 28),
        hintText: _isParentOrAdminMode ? "Contraseña" : "PIN Secreto",
        hintStyle: GoogleFonts.nunito(color: hintColor, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: neonColor, width: 2)),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    bool exito;
    if (_isParentOrAdminMode) {
      exito = await AuthDbService.loginPorCorreo(_identificadorController.text.trim(), _passController.text.trim());
    } else {
      exito = await AuthDbService.loginPorNombre(_identificadorController.text.trim(), _passController.text.trim());
    }
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (exito) {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('userRole') ?? 'student';

      if (userRole == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
      } else if (userRole == 'parent') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboardScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Datos incorrectos ❌", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFFF6B6B), behavior: SnackBarBehavior.floating,
      ));
    }
  }
}