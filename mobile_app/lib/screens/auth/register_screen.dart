import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/neon_db_service.dart';
import '../home/home_screen.dart';

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

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151522), // Fondo oscuro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF222232),
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222232),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF4ECDC4).withOpacity(0.3), blurRadius: 20)],
                    border: Border.all(color: const Color(0xFF4ECDC4), width: 2),
                  ),
                  child: const Icon(Icons.face_retouching_natural_rounded, size: 60, color: Color(0xFF4ECDC4)),
                ),
                const SizedBox(height: 15),
                Text("NUEVO PERFIL", style: GoogleFonts.fredoka(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                Text("¡Únete a la tripulación espacial!", style: GoogleFonts.nunito(color: const Color(0xFF48CAE4), fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222232), 
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: const Color(0xFF333344), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      _buildField(_nombreController, "Tu Nombre", Icons.person_rounded, const Color(0xFFFFD93D), false),
                      const SizedBox(height: 15),
                      _buildField(_emailController, "Correo", Icons.email_rounded, const Color(0xFF48CAE4), false),
                      const SizedBox(height: 15),
                      _buildField(_passController, "PIN de 4 números", Icons.lock_rounded, const Color(0xFFFF6B6B), true),
                      const SizedBox(height: 15),
                      
                      // SELECTOR DE GRADO DARK
                      DropdownButtonFormField<int>(
                        value: _gradoSeleccionado,
                        dropdownColor: const Color(0xFF222232), // Dropdown oscuro
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9D4EDD)),
                        style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.school_rounded, color: Color(0xFF9D4EDD)),
                          filled: true,
                          fillColor: const Color(0xFF151522),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                        items: [1, 2, 3, 4, 5, 6].map((grado) {
                          return DropdownMenuItem(value: grado, child: Text("Grado $gradoº 🎒", style: const TextStyle(color: Colors.white)));
                        }).toList(),
                        onChanged: (val) => setState(() => _gradoSeleccionado = val!),
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4), // Verde agua brillante
                            elevation: 8,
                            shadowColor: const Color(0xFF4ECDC4).withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: _isLoading ? null : _registrar,
                          child: _isLoading 
                            ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: const Color(0xFF151522), strokeWidth: 3))
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

  Widget _buildField(TextEditingController controller, String label, IconData icon, Color neonColor, bool isPass) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      keyboardType: isPass ? TextInputType.number : (label == "Correo" ? TextInputType.emailAddress : TextInputType.name),
      inputFormatters: isPass ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ] : [],
      style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '¡Falta este dato!';
        if (isPass && value.length < 4) return 'El PIN necesita 4 números';
        if (label == "Correo" && !value.contains("@")) return 'Correo no válido';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: neonColor, size: 26),
        hintText: label,
        hintStyle: GoogleFonts.nunito(color: Colors.white38, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: const Color(0xFF151522),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: neonColor, width: 2)),
        errorStyle: GoogleFonts.nunito(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
        counterText: "", 
      ),
    );
  }

  void _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    dynamic resultado = await NeonDbService.registrarUsuario(
      _nombreController.text.trim(), 
      _emailController.text.trim(), 
      _passController.text.trim(), 
      _gradoSeleccionado
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado == true) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
    } else if (resultado is String && resultado == 'duplicate_name') {
      _mostrarAlerta("¡Ese nombre ya existe! 🧐", "Agrega una inicial o número divertido (ej. ${_nombreController.text.trim()}123).", const Color(0xFFFFD93D), Colors.black87);
    } else if (resultado is String && resultado == 'duplicate_email') {
      _mostrarAlerta("¡Ups! Correo en uso 📧", "Ya hay una cuenta con este correo.", const Color(0xFFFF6B6B), Colors.white);
    } else {
      _mostrarAlerta("Error de conexión 🔌", "Revisa tu internet y vuelve a intentar.", const Color(0xFFFF6B6B), Colors.white);
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