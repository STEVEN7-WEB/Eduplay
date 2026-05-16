import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/neon_db_service.dart';
import '../../services/email_service.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  int _pasoActual = 1; 
  String _correoDestino = "";
  String _codigoGenerado = "";
  bool _isProcessing = false;

  final TextEditingController _usuarioCtrl = TextEditingController();
  final TextEditingController _codigoCtrl = TextEditingController();
  final TextEditingController _nuevaPassCtrl = TextEditingController();

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _codigoCtrl.dispose();
    _nuevaPassCtrl.dispose();
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: const Color(0xFFFF6B6B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  void _procesarPaso() async {
    if (_pasoActual == 1) {
      if (_usuarioCtrl.text.isEmpty) {
        _mostrarError("Ingresa un usuario o correo");
        return;
      }
      setState(() => _isProcessing = true);
      String? correoHallado = await NeonDbService.obtenerCorreoDeUsuario(_usuarioCtrl.text.trim());
      
      if (correoHallado != null) {
        _codigoGenerado = EmailService.generarCodigo();
        bool enviado = await EmailService.enviarCodigo(correoHallado, _codigoGenerado);
        if (enviado) {
          setState(() {
            _correoDestino = correoHallado;
            _pasoActual = 2;
          });
        } else {
          _mostrarError("Fallo al enviar correo");
        }
      } else {
        _mostrarError("Usuario/Correo no encontrado");
      }
      setState(() => _isProcessing = false);
    } 
    else if (_pasoActual == 2) {
      if (_codigoCtrl.text.trim() == _codigoGenerado) {
        setState(() => _pasoActual = 3);
      } else {
        _mostrarError("El código no coincide");
      }
    } 
    else if (_pasoActual == 3) {
      if (_nuevaPassCtrl.text.isEmpty) {
        _mostrarError("Ingresa tu nueva contraseña");
        return;
      }
      setState(() => _isProcessing = true);
      bool guardado = await NeonDbService.actualizarPassword(_usuarioCtrl.text.trim(), _nuevaPassCtrl.text.trim());
      setState(() => _isProcessing = false);
      
      if (guardado) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("¡Contraseña actualizada con éxito! 🎉", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF4ECDC4), behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context); // Regresa al Login
      } else {
        _mostrarError("Hubo un error al guardar");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0D0D1A) : const Color(0xFFF4F6F9);
    final cardColor = isDarkMode ? const Color(0xFF222232) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E1E2E);
    final neonColor = const Color(0xFF48CAE4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // --- FONDOS DE NEÓN DIFUMINADOS ---
          Positioned(
            top: 50, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF48CAE4).withOpacity(isDarkMode ? 0.3 : 0.15), blurRadius: 150)]
              ),
            ),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(isDarkMode ? 0.25 : 0.15), blurRadius: 150)]
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(35),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(isDarkMode ? 0.6 : 0.8),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.5), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _construirContenidoPaso(isDarkMode, textColor, neonColor),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirContenidoPaso(bool isDarkMode, Color textColor, Color neonColor) {
    String titulo = ""; String subtitulo = ""; IconData icono = Icons.help;
    TextEditingController activoCtrl = _usuarioCtrl;
    TextInputType tipoTeclado = TextInputType.text;
    String hint = "";
    
    if (_pasoActual == 1) {
      titulo = "Recuperar Acceso"; subtitulo = "Ingresa tu usuario (alumno) o correo (tutor) para enviarte un código de rescate.";
      icono = Icons.lock_reset_rounded; hint = "Tu usuario o correo"; 
    } else if (_pasoActual == 2) {
      titulo = "¡Código Enviado!"; 
      subtitulo = "Revisa el correo oculto (***${_correoDestino.substring(_correoDestino.indexOf('@'))}) y escribe los 6 números.";
      icono = Icons.mark_email_read_rounded; hint = "Código de 6 dígitos"; 
      activoCtrl = _codigoCtrl; tipoTeclado = TextInputType.number;
    } else if (_pasoActual == 3) {
      titulo = "Nueva Contraseña"; subtitulo = "Ingresa tu nuevo PIN secreto o contraseña.";
      icono = Icons.vpn_key_rounded; hint = "Nueva contraseña / PIN"; 
      activoCtrl = _nuevaPassCtrl; 
    }

    return Column(
      key: ValueKey<int>(_pasoActual),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: neonColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icono, size: 60, color: neonColor),
        ),
        const SizedBox(height: 20),
        Text(titulo, style: GoogleFonts.fredoka(color: neonColor, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(subtitulo, textAlign: TextAlign.center, style: GoogleFonts.nunito(color: textColor, fontSize: 16)),
        const SizedBox(height: 30),
        TextField(
          controller: activoCtrl,
          keyboardType: tipoTeclado,
          style: GoogleFonts.nunito(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38),
            filled: true, fillColor: isDarkMode ? const Color(0xFF151522).withOpacity(0.8) : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: neonColor, width: 2)),
          ),
        ),
        const SizedBox(height: 35),
        SizedBox(
          width: double.infinity, height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: neonColor,
              foregroundColor: const Color(0xFF0D0D1A),
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
            onPressed: _isProcessing ? null : _procesarPaso,
            child: _isProcessing 
              ? const CircularProgressIndicator(color: Color(0xFF0D0D1A))
              : Text(_pasoActual == 3 ? "Guardar y Entrar" : "Siguiente", style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
}