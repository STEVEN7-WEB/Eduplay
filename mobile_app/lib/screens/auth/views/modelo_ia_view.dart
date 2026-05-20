import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../services/neon_db/game_db_service.dart';

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
  bool _isSearching = false; 
  bool _canSave = false;
  bool _isSaving = false; 

  final Map<int, Color> _coloresNivel = {
    1: const Color(0xFFFF6B6B), 2: const Color(0xFFFFD93D),
    3: const Color(0xFF48CAE4), 4: const Color(0xFF4ECDC4), 5: const Color(0xFF9D4EDD),
  };

  void _limpiarCampos() {
    if (_isPredicting || _isSearching || _isSaving) return; 
    setState(() {
      _idController.clear();
      _mem.clear(); _mat.clear(); _gra.clear(); _ing.clear();
      _geo.clear(); _art.clear(); _cie.clear(); _log.clear();
      _resultadoIA = "Esperando diagnóstico..."; _emoji = ""; _recomendacion = "";
      _promedioObtenido = null; _probabilidades = {};
      _canSave = false; _rangoObtenido = null; _colorResultado = Colors.grey;
    });
  }

  Future<void> _buscarCalificaciones() async {
    final uId = int.tryParse(_idController.text);
    if (uId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Ingresa un ID válido")));
      return;
    }

    setState(() => _isSearching = true);

    try {
      final notas = await GameDbService.obtenerCalificacionesUsuario(uId);

      if (notas != null && notas.isNotEmpty) {
        setState(() {
          _mem.text = (notas['memoria'] ?? 0).toString();
          _mat.text = (notas['matematicas'] ?? 0).toString();
          _gra.text = (notas['gramatica'] ?? 0).toString();
          _ing.text = (notas['ingles'] ?? 0).toString();
          _geo.text = (notas['geografia'] ?? 0).toString();
          _art.text = (notas['arte'] ?? 0).toString();
          _cie.text = (notas['ciencia'] ?? 0).toString();
          _log.text = (notas['logica'] ?? 0).toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Calificaciones cargadas"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Alumno sin calificaciones registradas"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Error de conexión con Neon")));
    }

    setState(() => _isSearching = false);
  }

  int _adaptarEscala(String texto) {
    int valor = int.tryParse(texto) ?? 0;
    return valor <= 10 ? valor * 10 : valor;
  }

  Future<void> _analizarRendimiento() async {
    if (_mem.text.isEmpty || _idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Completa el ID y realiza la búsqueda primero")));
      return;
    }

    setState(() { _isPredicting = true; _canSave = false; });
    
    final url = Uri.parse('https://eduplay-r5bc.onrender.com/api/predict'); 

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "memoria": _adaptarEscala(_mem.text), "matematicas": _adaptarEscala(_mat.text),
          "gramatica": _adaptarEscala(_gra.text), "ingles": _adaptarEscala(_ing.text),
          "geografia": _adaptarEscala(_geo.text), "arte": _adaptarEscala(_art.text),
          "ciencia": _adaptarEscala(_cie.text), "logica": _adaptarEscala(_log.text),
        })
      ).timeout(const Duration(seconds: 15)); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rangoObtenido = data['rango'];
          _resultadoIA = data['etiqueta'];
          _emoji = data['emoji'] ?? '';
          
          double promServidor = (data['promedio'] ?? 0).toDouble();
          _promedioObtenido = promServidor > 10 ? promServidor / 10 : promServidor;
          
          _recomendacion = data['recomendacion'] ?? '';
          _probabilidades = data['probabilidades'] ?? {};
          _colorResultado = _coloresNivel[_rangoObtenido] ?? Colors.grey;
          _canSave = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Error en el servidor de IA"), backgroundColor: Colors.red));
        setState(() => _resultadoIA = "Error del servidor");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ No se pudo conectar con el servidor"), backgroundColor: Colors.red));
      setState(() => _resultadoIA = "Sin conexión");
    }
    setState(() => _isPredicting = false);
  }

  Future<void> _guardarEnNeon() async {
    final uId = int.tryParse(_idController.text);
    if (uId == null || _rangoObtenido == null) return;

    setState(() => _isSaving = true); 

    bool exito = await GameDbService.guardarResultadoKNN(
      userId: uId, 
      rango: _rangoObtenido!, 
      etiqueta: _resultadoIA,
      promedioGeneral: _promedioObtenido ?? 0.0,
      recomendacion: _recomendacion
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(exito ? "✅ Diagnóstico guardado en la BD" : "❌ Error en Neon"),
      backgroundColor: exito ? Colors.green : Colors.red,
    ));

    setState(() => _isSaving = false); 
  }

  @override
  Widget build(BuildContext context) {
    bool isUIBlocked = _isPredicting || _isSearching || _isSaving;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInput("ID Alumno", _idController, Icons.fingerprint, isId: true, isReadOnly: false)),
              const SizedBox(width: 10),
              _isSearching
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(onPressed: isUIBlocked ? null : _buscarCalificaciones, icon: Icon(Icons.search, color: isUIBlocked ? Colors.grey : Colors.blue, size: 28)),
              IconButton(onPressed: isUIBlocked ? null : _limpiarCampos, icon: Icon(Icons.refresh, color: isUIBlocked ? Colors.grey : Colors.orange, size: 28)),
            ],
          ),
          const Divider(height: 30, thickness: 2),
          Text("Historial de Calificaciones", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.grey)),
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
            onPressed: isUIBlocked ? null : _analizarRendimiento,
            icon: _isPredicting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text("DIAGNOSTICAR CON IA", style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 25),
          
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: _canSave ? _colorResultado.withOpacity(0.3) : Colors.black12, blurRadius: 15, offset: const Offset(0, 5))
              ],
              border: Border.all(color: _canSave ? _colorResultado.withOpacity(0.5) : Colors.transparent, width: 2)
            ),
            child: Column(
              children: [
                Text("RESULTADO DEL DIAGNÓSTICO", style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                Text("$_emoji $_resultadoIA", textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 28, color: _canSave ? _colorResultado : Colors.grey, fontWeight: FontWeight.w900)),
                
                if (_canSave) ...[
                  const SizedBox(height: 10),
                  Text("Promedio General: ${_promedioObtenido?.toStringAsFixed(1) ?? '0.0'}", style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: _colorResultado.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
                    child: Text(_recomendacion, textAlign: TextAlign.center, style: GoogleFonts.nunito(fontStyle: FontStyle.italic, color: widget.isDarkMode ? Colors.white : Colors.black87)),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text("Desglose de Probabilidades:", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),
                  // Aquí iteramos sobre el diccionario, lo ordenamos de mayor a menor probabilidad y lo mapeamos a las barras
                  ...(_probabilidades.entries.toList()..sort((a, b) => (b.value as num).compareTo(a.value as num)))
                      .map((e) => _buildBarraProbabilidad(e.key, (e.value as num).toDouble())),
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
              onPressed: _isSaving ? null : _guardarEnNeon,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_done_rounded, color: Colors.white),
              label: Text("GUARDAR EN NEON", style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18)),
            ),
        ],
      ),
    );
  }

  // Diseño pulido y moderno de las barras de progreso
  Widget _buildBarraProbabilidad(String etiqueta, double valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 95, 
            child: Text(etiqueta, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: widget.isDarkMode ? Colors.white70 : Colors.black87))
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: valor / 100, 
                minHeight: 12,
                backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200, 
                valueColor: AlwaysStoppedAnimation<Color>(_colorResultado),
              ),
            ),
          ),
          SizedBox(
            width: 60, 
            child: Text("${valor.toStringAsFixed(1)}%", textAlign: TextAlign.right, style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.w600, color: widget.isDarkMode ? Colors.white : Colors.black54))
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {bool isId = false, bool isReadOnly = true}) {
    return TextField(
      controller: controller, 
      keyboardType: TextInputType.number,
      readOnly: isReadOnly, 
      inputFormatters: [LengthLimitingTextInputFormatter(isId ? 4 : 2)], 
      style: TextStyle(
        color: isReadOnly ? Colors.grey : (widget.isDarkMode ? Colors.white : Colors.black), 
        fontWeight: FontWeight.bold
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: isId ? const Color(0xFF48CAE4) : Colors.grey),
        labelText: label, labelStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.grey),
        filled: true, 
        fillColor: isId ? const Color(0xFF48CAE4).withOpacity(0.05) : (widget.isDarkMode ? Colors.white10 : Colors.grey.shade200),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isReadOnly ? Colors.transparent : const Color(0xFF48CAE4), width: 1.5)),
      ),
    );
  }
}