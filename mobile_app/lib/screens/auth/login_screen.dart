import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/neon_db_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151522), // Fondo oscuro espacial
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO CIRCULAR NEÓN
                  Container(
                    height: 120, width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222232),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9D4EDD).withOpacity(0.4), // Brillo morado
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
                    "¡HOLA!",
                    style: GoogleFonts.fredoka(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  Text(
                    "¡Listo para otra misión!",
                    style: GoogleFonts.nunito(color: const Color(0xFF48CAE4), fontSize: 16, fontWeight: FontWeight.w700), // Texto cian
                  ),
                  const SizedBox(height: 30),
                  _buildLoginBox(),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      "¿Eres nuevo? ¡Crea tu perfil aquí! ✨",
                      style: GoogleFonts.nunito(color: const Color(0xFFFFD93D), fontWeight: FontWeight.w800, fontSize: 16), // Amarillo neón
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

  Widget _buildLoginBox() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF222232), // Gris azulado oscuro
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFF333344), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          _buildField(_nombreController, "Tu Nombre", Icons.face_retouching_natural_rounded, const Color(0xFF4ECDC4), false),
          const SizedBox(height: 15),
          _buildField(_passController, "PIN Secreto", Icons.lock_rounded, const Color(0xFFFF6B6B), true),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD), // Botón Morado Neón
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

  Widget _buildField(TextEditingController controller, String label, IconData icon, Color neonColor, bool isPass) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      keyboardType: isPass ? TextInputType.number : TextInputType.name,
      inputFormatters: isPass ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ] : [],
      style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '¡Falta este dato!';
        if (isPass && value.length < 4) return 'El PIN necesita 4 números';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: neonColor, size: 28),
        hintText: label,
        hintStyle: GoogleFonts.nunito(color: Colors.white38, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: const Color(0xFF151522), // Fondo del input más oscuro que la tarjeta
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), 
          borderSide: BorderSide(color: neonColor.withOpacity(0.3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), 
          borderSide: BorderSide(color: Colors.transparent, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), 
          borderSide: BorderSide(color: neonColor, width: 2), // Brilla al tocarlo
        ),
        errorStyle: GoogleFonts.nunito(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
        counterText: "", 
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    bool exito = await NeonDbService.loginPorNombre(_nombreController.text.trim(), _passController.text.trim());
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (exito) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nombre o PIN incorrectos ❌", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          backgroundColor: const Color(0xFFFF6B6B), // Rojo pastel
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        )
      );
    }
  }
}