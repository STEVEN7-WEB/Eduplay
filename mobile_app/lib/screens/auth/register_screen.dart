import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Importaciones de tus servicios y pantallas
import '../../services/neon_db/auth_db_service.dart';
import '../../services/email_service.dart'; // Asegúrate de haber creado este archivo
import '../home/home_screen.dart'; // Asegúrate de haber creado este archivo
import 'verification_screen.dart'; // Asegúrate de haber creado este archivo

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  int _gradoSeleccionado = 1; 
  bool _isLoading = false;

  // --- LISTA DE AVATARES DISPONIBLES (Misma que en Perfil) ---
  final List<String> _avatars = [
    'assets/avatars/avatar1.png', 
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png', 
    'assets/avatars/avatar4.png', 
    'assets/avatars/avatar5.png',
    'assets/avatars/avatar6.png',
  ];
  // Valor por defecto inicial
  String _avatarSeleccionado = 'assets/avatars/avatar1.png';

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final cardColor = isDarkMode ? const Color(0xFF222232) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E1E2E);
    final subtitleColor = isDarkMode ? const Color(0xFF48CAE4) : const Color(0xFF0096C7);
    final borderColor = isDarkMode ? const Color(0xFF333344) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4ECDC4), width: 1.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4ECDC4), size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text("NUEVO PERFIL", style: GoogleFonts.fredoka(color: textColor, fontSize: 32, fontWeight: FontWeight.w900)),
                Text("¡Únete a la tripulación espacial!", style: GoogleFonts.nunito(color: subtitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 25),

                // --- SELECTOR DE AVATARES (Horizontal ListView) ---
                Text("Elige tu Avatar", style: GoogleFonts.fredoka(color: isDarkMode ? const Color(0xFFFFD93D) : const Color(0xFFD4A000), fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      final isSelected = _avatarSeleccionado == _avatars[index];
                      return GestureDetector(
                        onTap: () => setState(() => _avatarSeleccionado = _avatars[index]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          padding: EdgeInsets.all(isSelected ? 3 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF4ECDC4) : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(color: const Color(0xFF4ECDC4).withOpacity(0.5), blurRadius: 10)
                            ] : [],
                          ),
                          child: CircleAvatar(
                            radius: isSelected ? 40 : 35,
                            backgroundColor: cardColor,
                            backgroundImage: AssetImage(_avatars[index]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: cardColor, 
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      // Banner de Verificación Informativo
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF48CAE4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF48CAE4).withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read_rounded, color: Color(0xFF48CAE4), size: 30),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                "Enviaremos un correo de verificación y reportes de progreso al tutor.",
                                style: GoogleFonts.nunito(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      _buildField(_nombreController, "Nombre del Explorador", Icons.person_rounded, const Color(0xFFFFD93D), false, isDarkMode),
                      const SizedBox(height: 15),
                      _buildField(_emailController, "Correo del Padre/Tutor", Icons.email_rounded, const Color(0xFF48CAE4), false, isDarkMode),
                      const SizedBox(height: 15),
                      _buildField(_passController, "PIN de 4 números", Icons.lock_rounded, const Color(0xFFFF6B6B), true, isDarkMode),
                      const SizedBox(height: 15),
                      
                      // Dropdown de Grado Escolar
                      DropdownButtonFormField<int>(
                        value: _gradoSeleccionado,
                        dropdownColor: cardColor,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9D4EDD)),
                        style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.w800, fontSize: 16),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.school_rounded, color: Color(0xFF9D4EDD)),
                          filled: true,
                          fillColor: isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                        items: [1, 2, 3, 4, 5, 6].map((grado) {
                          return DropdownMenuItem(value: grado, child: Text("Grado $gradoº 🎒", style: TextStyle(color: textColor)));
                        }).toList(),
                        onChanged: (val) => setState(() => _gradoSeleccionado = val!),
                      ),

                      const SizedBox(height: 30),
                      // Botón de Registrar
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4), // Color Neón Menta
                            elevation: 8,
                            shadowColor: const Color(0xFF4ECDC4).withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: _isLoading ? null : _registrar,
                          child: _isLoading 
                            ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text("¡CREAR MI CUENTA!", style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF151522))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, Color neonColor, bool isPass, bool isDarkMode) {
    final fillColor = isDarkMode ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.white38 : Colors.black38;

    return TextFormField(
      controller: controller,
      obscureText: isPass,
      keyboardType: isPass ? TextInputType.number : (label.contains("Correo") ? TextInputType.emailAddress : TextInputType.name),
      inputFormatters: isPass ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ] : [],
      style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.w700, fontSize: 18),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '¡Falta este dato!';
        if (isPass && value.length < 4) return 'El PIN necesita 4 números';
        if (label.contains("Correo") && !value.contains("@")) return 'Correo no válido';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: neonColor, size: 26),
        hintText: label,
        hintStyle: GoogleFonts.nunito(color: hintColor, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: neonColor, width: 2)),
        errorStyle: GoogleFonts.nunito(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
        counterText: "", 
      ),
    );
  }

  /// LÓGICA DE REGISTRO
  void _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 1. Mostrar estado de carga local y generar código de verificación
    setState(() => _isLoading = true);
    String codigoGenerado = EmailService.generarCodigo();
    
    // 2. Enviar el correo al tutor
    bool correoEnviado = await EmailService.enviarCodigo(_emailController.text.trim(), codigoGenerado);
    
    if (!mounted) return;

    if (!correoEnviado) {
      setState(() => _isLoading = false);
      _mostrarAlerta("Error de conexión 🔌", "No pudimos enviar el correo de verificación. Revisa tus credenciales o intenta más tarde.", const Color(0xFFFF6B6B), Colors.white);
      return;
    }

    // Ocultamos la carga temporalmente mientras abrimos la otra pantalla
    setState(() => _isLoading = false);

    // 3. Abrir la pantalla de verificación y esperar resultado
    final verificado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationScreen(
          correoPadre: _emailController.text.trim(),
          codigoReal: codigoGenerado,
        ),
      ),
    );

    // 4. Si el usuario ingresó el código correcto y regresó "true" desde VerificationScreen
    if (verificado == true) {
      if (!mounted) return;
      setState(() => _isLoading = true); // Volvemos a mostrar que está cargando para guardar en BD
      
      // Llamamos al servicio de Neon pasándole el avatar seleccionado
      dynamic resultado = await AuthDbService.registrarUsuario(
        _nombreController.text.trim(), 
        _emailController.text.trim(), 
        _passController.text.trim(), 
        _gradoSeleccionado,
        _avatarSeleccionado // Pasamos la ruta elegida (ej. 'assets/avatars/avatar3.png')
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (resultado == true) {
        // Registro y Login exitosos, vamos al Home
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
      } else if (resultado is String && resultado == 'duplicate_name') {
        _mostrarAlerta("¡Ese nombre ya existe! 🧐", "Agrega una inicial o número divertido (ej. ${_nombreController.text.trim()}123).", const Color(0xFFFFD93D), Colors.black87);
      } else if (resultado is String && resultado == 'duplicate_email') {
        _mostrarAlerta("¡Ups! Correo en uso 📧", "Ya hay una cuenta verificada con este correo.", const Color(0xFFFF6B6B), Colors.white);
      } else {
        _mostrarAlerta("Error de conexión 🔌", "Revisa tu internet y vuelve a intentar.", const Color(0xFFFF6B6B), Colors.white);
      }
    } else {
      // El usuario canceló la verificación o el código fue incorrecto
      // No hacemos nada, la carga ya se quitó.
    }
  }

  void _mostrarAlerta(String titulo, String mensaje, Color bgColor, Color txtColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titulo, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18, color: txtColor)),
            Text(mensaje, style: GoogleFonts.nunito(fontSize: 15, color: txtColor)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 5),
        padding: const EdgeInsets.all(16),
      )
    );
  }
}