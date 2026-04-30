import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          child: Form(
            key: _formKey,
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
                      _buildField(_nombreController, "Tu Nombre", Icons.face, Colors.greenAccent, false),
                      const SizedBox(height: 15),
                      _buildField(_emailController, "Correo", Icons.email, Colors.cyanAccent, false),
                      const SizedBox(height: 15),
                      _buildField(_passController, "PIN de 4 números", Icons.lock, Colors.pinkAccent, true),
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
                            ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Color(0xFF0D1B2A), strokeWidth: 3))
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
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, Color color, bool isPass) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      keyboardType: isPass ? TextInputType.number : 
                    (label == "Correo" ? TextInputType.emailAddress : TextInputType.name),
      inputFormatters: isPass ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ] : [],
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Falta llenar este campo';
        }
        if (isPass && value.length < 4) {
          return 'El PIN debe tener 4 números';
        }
        if (label == "Correo" && !value.contains("@")) {
          return 'Ingresa un correo válido';
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
        errorStyle: const TextStyle(color: Colors.pinkAccent),
        counterText: "", 
      ),
    );
  }

  void _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Aquí implementamos la lógica para recibir el string de respuesta
    dynamic resultado = await NeonDbService.registrarUsuario(
      _nombreController.text.trim(), 
      _emailController.text.trim(), 
      _passController.text.trim(), 
      _gradoSeleccionado
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Verificamos el tipo de resultado que devuelve NeonDbService
    if (resultado == true) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
    } else if (resultado is String && resultado == 'duplicate_email') {
      // Manejamos el error específico del correo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Ups! Este correo ya está registrado 📧"),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 4),
        )
      );
    } else {
      // Error general
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al registrar ❌. Revisa tu conexión."),
          backgroundColor: Colors.pinkAccent,
        )
      );
    }
  }
}