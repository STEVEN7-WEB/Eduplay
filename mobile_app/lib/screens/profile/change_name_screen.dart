import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importamos el servicio de base de datos
import '../../services/neon_db_service.dart';

class ChangeNameScreen extends StatefulWidget {
  final String currentName;

  const ChangeNameScreen({super.key, required this.currentName});

  @override
  State<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends State<ChangeNameScreen> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _guardarNombre() async {
    final nuevoNombre = _nameController.text.trim();

    // Si está vacío o es igual al anterior, solo regresamos sin hacer nada
    if (nuevoNombre.isEmpty || nuevoNombre == widget.currentName) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    // Obtenemos el ID del usuario actual
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('id_usuario');

    if (userId != null) {
      // Llamamos a la función de UserDbService para actualizar en la BD
      bool exito = await UserDbService.actualizarNombreUsuario(userId, nuevoNombre);

      setState(() => _isLoading = false);

      if (exito) {
        // Regresamos a la pantalla de perfil enviando el nuevo nombre
        if (mounted) Navigator.pop(context, nuevoNombre);
      } else {
        // Si hubo error, mostramos un mensaje
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error al actualizar. Quizás el nombre ya está en uso."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = const Color(0xFF48CAE4);
    final Color bgColor = isDark ? const Color(0xFF151522) : const Color(0xFFF4F6F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          "Cambiar Nombre", 
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : Colors.black
          )
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¿Cómo quieres que te llamemos?",
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF222232) : Colors.white,
                prefixIcon: Icon(Icons.person, color: accentColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                // Deshabilitamos el botón mientras carga
                onPressed: _isLoading ? null : _guardarNombre,
                child: _isLoading 
                  ? const SizedBox(
                      width: 24, height: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    )
                  : Text(
                      "Guardar Cambios",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
              ),
            )
          ],
        ),
      ),
    );
  }
}