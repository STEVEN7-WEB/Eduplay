import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey, // Usamos Form para validaciones
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO CIRCULAR
                  Container(
                    height: 120, width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B263B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent, width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.rocket_launch, size: 60, color: Colors.cyanAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "BIENVENIDO",
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3),
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
                    child: const Text(
                      "¿Eres nuevo? ¡Crea tu perfil aquí! ✨",
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
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
        color: const Color(0xFF1B263B),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          _buildField(_emailController, "Correo", Icons.email, Colors.cyanAccent, false),
          const SizedBox(height: 15),
          _buildField(_passController, "PIN Secreto", Icons.lock, Colors.pinkAccent, true),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: const Color(0xFF0D1B2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _isLoading ? null : _login,
              child: _isLoading 
                ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Color(0xFF0D1B2A), strokeWidth: 3))
                : const Text("ENTRAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, Color color, bool isPass) {
    return TextFormField( // Cambiado a TextFormField
      controller: controller,
      obscureText: isPass,
      keyboardType: isPass ? TextInputType.number : TextInputType.emailAddress,
      inputFormatters: isPass ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ] : [],
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es requerido';
        }
        if (isPass && value.length < 4) {
          return 'El PIN debe tener 4 números';
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color),
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF0D1B2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), 
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.pinkAccent), // Estilo para los errores
        counterText: "", 
      ),
    );
  }

  void _login() async {
    // 1. Validamos que el formulario esté correcto antes de enviar nada
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Aquí es donde llamas a tu API de Flask
    bool exito = await NeonDbService.loginDirecto(_emailController.text.trim(), _passController.text.trim());
    
    if (!mounted) return; // Buena práctica en Flutter
    setState(() => _isLoading = false);

    if (exito) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Correo o PIN incorrectos ❌"),
          backgroundColor: Colors.pinkAccent,
        )
      );
    }
  }
}