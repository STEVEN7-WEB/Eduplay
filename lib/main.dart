import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'services/neon_db_service.dart'; // Importante para usar las funciones de Neon

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  final prefs = await SharedPreferences.getInstance();
  final bool yaInicioSesion = prefs.getBool('sesion_iniciada') ?? false;

  runApp(EduplayApp(iniciarDirecto: yaInicioSesion));
}

class EduplayApp extends StatelessWidget {
  final bool iniciarDirecto;

  const EduplayApp({super.key, required this.iniciarDirecto}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eduplay 2.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'ComicSans', // O la fuente que estés usando
      ),
      home: iniciarDirecto ? const PantallaTemporalHome() : const LoginScreen(), 
    );
  }
}

// Cambiamos a StatefulWidget para poder actualizar el texto en pantalla al bajar datos
class PantallaTemporalHome extends StatefulWidget {
  const PantallaTemporalHome({super.key});

  @override
  State<PantallaTemporalHome> createState() => _PantallaTemporalHomeState();
}

class _PantallaTemporalHomeState extends State<PantallaTemporalHome> {
  String estadoDeDatos = "¡Listo para la aventura!";
  String listaDePuntos = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, color: Colors.orange, size: 80),
                const Text(
                  '¡BIENVENIDO AL JUEGO!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.blue),
                ),
                const SizedBox(height: 30),

                // --- BOTÓN PARA SUBIR ---
                _buildTestButton(
                  text: 'Subir: Gane 50 pts en Mates 🚀',
                  color: Colors.green,
                  icon: Icons.cloud_upload,
                  onPressed: () async {
                    setState(() => estadoDeDatos = "Subiendo...");
                    bool exito = await NeonDbService.guardarPuntaje('Matemáticas', 50);
                    setState(() {
                      estadoDeDatos = exito ? "¡Puntos guardados en Neon! ✅" : "Error al subir ❌";
                    });
                  },
                ),

                const SizedBox(height: 15),

                // --- BOTÓN PARA BAJAR ---
                _buildTestButton(
                  text: 'Bajar mis trofeos 🏆',
                  color: Colors.orange,
                  icon: Icons.cloud_download,
                  onPressed: () async {
                    setState(() => estadoDeDatos = "Bajando datos...");
                    List<Map<String, dynamic>> datos = await NeonDbService.obtenerPuntajes();
                    
                    setState(() {
                      estadoDeDatos = "Datos extraídos de la nube";
                      listaDePuntos = datos.map((e) => "🎮 ${e['materia']}: ${e['puntos']} pts").join("\n");
                      if (listaDePuntos.isEmpty) listaDePuntos = "Aún no tienes trofeos guardados.";
                    });
                  },
                ),

                const SizedBox(height: 30),

                // Panel para ver los resultados
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(estadoDeDatos, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const Divider(),
                      Text(listaDePuntos, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                TextButton.icon(
                  onPressed: () async {
                    await NeonDbService.cerrarSesion();
                    if (mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    }
                  },
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton({required String text, required Color color, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}