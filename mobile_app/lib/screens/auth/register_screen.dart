import 'package:flutter/material.dart';
import '../../services/neon_db_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  int _gradoSeleccionado = 1; // Grado por defecto
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 20),
              const Text("NUEVO PERFIL", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: const Color(0xFF1B263B), borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    _buildField(_nombreController, "Tu Nombre", Icons.face, Colors.greenAccent),
                    const SizedBox(height: 15),
                    _buildField(_emailController, "Correo", Icons.email, Colors.cyanAccent),
                    const SizedBox(height: 15),
                    _buildField(_passController, "Contraseña", Icons.lock, Colors.pinkAccent, isPass: true),
                    const SizedBox(height: 15),
                    
                    // SELECTOR DE GRADO
                    DropdownButtonFormField<int>(
                      value: _gradoSeleccionado,
                      dropdownColor: const Color(0xFF1B263B),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.school, color: Colors.orangeAccent),
                        filled: true,
                        fillColor: const Color(0xFF0D1B2A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                      items: [1, 2, 3, 4, 5, 6].map((grado) {
                        return DropdownMenuItem(value: grado, child: Text("Grado $gradoº"));
                      }).toList(),
                      onChanged: (val) => setState(() => _gradoSeleccionado = val!),
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: const Color(0xFF0D1B2A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _isLoading ? null : _registrar,
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Color(0xFF0D1B2A))
                          : const Text("CREAR MI CUENTA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, Color color, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color),
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF0D1B2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  void _registrar() async {
    if (_nombreController.text.isEmpty || _emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡No dejes campos vacíos! ✍️")));
      return;
    }
    setState(() => _isLoading = true);
    // Mandamos el grado seleccionado
    bool exito = await NeonDbService.registrarUsuario(_nombreController.text, _emailController.text, _passController.text, _gradoSeleccionado);
    setState(() => _isLoading = false);

    if (exito && mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al registrar ❌")));
    }
  }
}