import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationScreen extends StatefulWidget {
  final String correoPadre;
  final String codigoReal;

  const VerificationScreen({
    super.key, 
    required this.correoPadre, 
    required this.codigoReal
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _codigoController = TextEditingController();
  bool _tieneError = false;

  void _verificar() {
    if (_codigoController.text.trim() == widget.codigoReal) {
      // Si el código es correcto, regresamos un "true" a la pantalla de registro
      Navigator.pop(context, true);
    } else {
      setState(() => _tieneError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Código incorrecto. Intenta de nuevo ❌", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF151522) : const Color(0xFFF4F6F9);
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E2E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_rounded, size: 80, color: Color(0xFF9D4EDD)),
            const SizedBox(height: 20),
            Text(
              "¡Revisa tu correo!",
              style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            Text(
              "Enviamos un código de 6 dígitos al correo de tu tutor:\n${widget.correoPadre}",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codigoController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 30, letterSpacing: 10, fontWeight: FontWeight.bold, color: textColor),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                hintText: "000000",
                filled: true,
                fillColor: isDark ? const Color(0xFF222232) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), 
                  borderSide: BorderSide(color: _tieneError ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4), width: 2)
                ),
              ),
              onChanged: (val) {
                if (_tieneError) setState(() => _tieneError = false);
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _verificar,
                child: Text("VERIFICAR CÓDIGO", style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF151522))),
              ),
            ),
            const SizedBox(height: 100), // Espacio para el teclado
          ],
        ),
      ),
    );
  }
}