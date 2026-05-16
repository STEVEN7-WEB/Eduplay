import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../services/neon_db_service.dart';

class ModeloIAView extends StatefulWidget {
  final bool isDarkMode;
  const ModeloIAView({required this.isDarkMode, super.key});
  @override
  State<ModeloIAView> createState() => _ModeloIAViewState();
}

class _ModeloIAViewState extends State<ModeloIAView> {
  final _idController = TextEditingController();
  
  final _mem = TextEditingController(); final _mat = TextEditingController();
  final _gra = TextEditingController(); final _ing = TextEditingController();
  final _geo = TextEditingController(); final _art = TextEditingController();
  final _cie = TextEditingController(); final _log = TextEditingController();

  String _resultadoIA = "Esperando diagnóstico...";
  String _emoji = "";
  String _recomendacion = "";
  double? _promedioObtenido;
  Map<String, dynamic> _probabilidades = {};
  Color _colorResultado = Colors.grey;
  int? _rangoObtenido;
  bool _isPredicting = false;
  bool _canSave = false;

  final Map<int, Color> _coloresNivel = {
    1: const Color(0xFFFF6B6B), 2: const Color(0xFFFFD93D),
    3: const Color(0xFF48CAE4), 4: const Color(0xFF4ECDC4), 5: const Color(0xFF9D4EDD),
  };

  void _limpiarCampos() {
    setState(() {
      _idController.clear();
      _mem.clear(); _mat.clear(); _gra.clear(); _ing.clear();
      _geo.clear(); _art.clear(); _cie.clear(); _log.clear();
      _resultadoIA = "Esperando diagnóstico..."; _emoji = ""; _recomendacion = "";
      _promedioObtenido = null; _probabilidades = {};
      _canSave = false; _rangoObtenido = null; _colorResultado = Colors.grey;
    });
  }

  Future<void> _analizarRendimiento() async {
    if (_mem.text.isEmpty || _idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Completa el ID y materias")));
      return;
    }

    setState(() { _isPredicting = true; _canSave = false; });
    final url = Uri.parse('http://192.168.0.124:5000/api/predict'); 

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "memoria": int.tryParse(_mem.text) ?? 0, "matematicas": int.tryParse(_mat.text) ?? 0,
          "gramatica": int.tryParse(_gra.text) ?? 0, "ingles": int.tryParse(_ing.text) ?? 0,
          "geografia": int.tryParse(_geo.text) ?? 0, "arte": int.tryParse(_art.text) ?? 0,
          "ciencia": int.tryParse(_cie.text) ?? 0, "logica": int.tryParse(_log.text) ?? 0,
        })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rangoObtenido = data['rango'];
          _resultadoIA = data['etiqueta'];
          _emoji = data['emoji'] ?? '';
          _promedioObtenido = data['promedio'];
          _recomendacion = data['recomendacion'] ?? '';
          _probabilidades = data['probabilidades'] ?? {};
          _colorResultado = _coloresNivel[_rangoObtenido] ?? Colors.grey;
          _canSave = true;
        });
      }
    } catch (e) {
      setState(() => _resultadoIA = "Error de conexión");
    }
    setState(() => _isPredicting = false);
  }

  Future<void> _guardarEnNeon() async {
    final uId = int.tryParse(_idController.text);
    if (uId == null || _rangoObtenido == null) return;

    bool exito = await NeonDbService.guardarResultadoKNN(
      userId: uId, rango: _rangoObtenido!, etiqueta: _resultadoIA,
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito ? "✅ Diagnóstico guardado" : "❌ Error en Neon"),
      backgroundColor: exito ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInput("ID Alumno", _idController, Icons.fingerprint, isId: true)),
              const SizedBox(width: 10),
              IconButton(onPressed: _limpiarCampos, icon: const Icon(Icons.refresh, color: Colors.orange)),
            ],
          ),
          const Divider(height: 30, thickness: 2),
          Text("Ingresar Calificaciones (0-100)", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 2.2, physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildInput("Memoria", _mem, Icons.psychology), _buildInput("Mate", _mat, Icons.calculate),
              _buildInput("Gramática", _gra, Icons.spellcheck), _buildInput("Inglés", _ing, Icons.translate),
              _buildInput("Geo", _geo, Icons.public), _buildInput("Arte", _art, Icons.palette),
              _buildInput("Ciencia", _cie, Icons.science), _buildInput("Lógica", _log, Icons.extension),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48CAE4), minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _isPredicting ? null : _analizarRendimiento,
            icon: _isPredicting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text("CORRER PREDICCIÓN", style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 25),
          
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _canSave ? _colorResultado.withOpacity(0.1) : (widget.isDarkMode ? Colors.white10 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: _canSave ? _colorResultado : Colors.transparent, width: 2)
            ),
            child: Column(
              children: [
                Text("RESULTADO DEL DIAGNÓSTICO", style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                Text("$_emoji $_resultadoIA", textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 28, color: _canSave ? _colorResultado : Colors.grey, fontWeight: FontWeight.w900)),
                
                if (_canSave) ...[
                  const SizedBox(height: 10),
                  Text("Promedio General: $_promedioObtenido", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _colorResultado.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                    child: Text(_recomendacion, textAlign: TextAlign.center, style: GoogleFonts.nunito(fontStyle: FontStyle.italic, color: widget.isDarkMode ? Colors.white : Colors.black87)),
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  Text("Probabilidades por clase:", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  ..._probabilidades.entries.map((e) => _buildBarraProbabilidad(e.key, e.value)),
                ]
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_canSave)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD), minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 5,
              ),
              onPressed: _guardarEnNeon,
              icon: const Icon(Icons.cloud_done_rounded, color: Colors.white),
              label: Text("GUARDAR EN NEON", style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18)),
            ),
        ],
      ),
    );
  }

  Widget _buildBarraProbabilidad(String etiqueta, dynamic porcentaje) {
    double valor = (porcentaje as num).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(etiqueta, style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white70 : Colors.black87))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: valor / 100, minHeight: 10,
                backgroundColor: Colors.grey.withOpacity(0.2), color: _colorResultado,
              ),
            ),
          ),
          SizedBox(width: 50, child: Text(" ${valor.toStringAsFixed(1)}%", textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black))),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {bool isId = false}) {
    return TextField(
      controller: controller, keyboardType: TextInputType.number,
      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: isId ? const Color(0xFF48CAE4) : Colors.grey),
        labelText: label, labelStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.grey),
        filled: true, fillColor: isId ? const Color(0xFF48CAE4).withOpacity(0.05) : (widget.isDarkMode ? Colors.white10 : Colors.grey.shade50),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF48CAE4), width: 1.5)),
      ),
    );
  }
}