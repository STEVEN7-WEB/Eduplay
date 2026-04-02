import 'package:flutter/material.dart';
import 'package:eduplay2_app/services/neon_db_service.dart'; // <-- Aquí está la importación corregida

// Más adelante descomentarás esto para navegar a los consejos
// import '../onboarding/tips_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true; // Controla si mostramos Login o Registro

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE), 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 30),
              
              // Formulario Mágico
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isLogin ? '¡Qué alegría verte!' : '¡Únete a la aventura!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.orange),
                    ),
                    const SizedBox(height: 25),
                    
                    if (!isLogin) ...[
                      _buildTextField(Icons.face, '¿Cómo te llamas? 🧒🏽', Colors.green),
                      const SizedBox(height: 15),
                    ],
                    _buildTextField(Icons.email_rounded, 'Tu correo o el de tus papás 💌', Colors.blue),
                    const SizedBox(height: 15),
                    _buildTextField(Icons.lock_rounded, 'Tu palabra secreta 🤫', Colors.purple, isPassword: true),
                    
                    const SizedBox(height: 35),
                    _buildMainButton(),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? '¿Eres nuevo? ¡Crea tu perfil aquí! ✨' : '¿Ya tienes perfil? ¡Entra aquí! 🎮',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blueAccent, 
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.blue.shade800, offset: const Offset(0, 6))]
          ),
          child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 60),
        ),
        const SizedBox(height: 15),
        Stack(
          children: [
            Text(
              'EDUPLAY 2.0',
              style: TextStyle(
                fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 3,
                foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 6..color = Colors.white,
              ),
            ),
            const Text(
              'EDUPLAY 2.0',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(IconData icon, String hint, Color iconColor, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor, size: 28),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: iconColor, width: 3),
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.green.shade800, offset: const Offset(0, 6))]
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
          elevation: 0,
        ),
        onPressed: () async {
          // Aquí llamas a tu archivo de conexión directo
          // Nota: Deberías sacar el email y password de unos TextControllers
          bool exito = await NeonDbService.loginDirecto("correo@prueba.com", "mipassword");
          
          if (exito) {
            // Ir a la siguiente pantalla
            print("¡Navegando a la pantalla principal!");
          } else {
            // Mostrar error
            print("Intenta de nuevo :(");
          }
        },
        child: Text(
          isLogin ? '¡A JUGAR!' : '¡LISTO, VAMOS!',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
        ),
      ),
    );
  }
}