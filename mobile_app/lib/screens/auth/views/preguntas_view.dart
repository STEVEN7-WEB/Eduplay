import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/neon_db_service.dart';

class PreguntasView extends StatefulWidget {
  final bool isDarkMode;
  const PreguntasView({required this.isDarkMode, super.key});
  @override
  State<PreguntasView> createState() => _PreguntasViewState();
}

class _PreguntasViewState extends State<PreguntasView> {
  List<Map<String, dynamic>> _preguntas = [];
  bool _isLoading = true;
  String _materiaFiltro = 'Todas';
  String _gradoFiltro = 'Todos';

  final List<String> _materias = ['Todas', 'memory', 'math', 'grammar', 'english', 'geography', 'art', 'science', 'logic'];
  final List<String> _grados = ['Todos', '1', '2', '3', '4', '5', '6'];

  @override
  void initState() {
    super.initState();
    _cargarPreguntas();
  }

  Future<void> _cargarPreguntas() async {
    setState(() => _isLoading = true);
    final data = await NeonDbService.obtenerTodasLasPreguntas();
    setState(() {
      _preguntas = data;
      _isLoading = false;
    });
  }

  void _dialogo({Map<String, dynamic>? item}) {
    final bool esEdit = item != null;
    final tText = TextEditingController(text: esEdit ? item['pregunta_texto'] : '');
    
    // Convertimos el grado a una variable de estado local en lugar de un TextEditingController
    int gradoSeleccionado = esEdit ? item['grado'] : 1; 

    List ops = esEdit ? (item['opciones'] is String ? jsonDecode(item['opciones']) : item['opciones']) : ["", "", "", ""];
    final tO1 = TextEditingController(text: ops[0]);
    final tO2 = TextEditingController(text: ops[1]);
    final tO3 = TextEditingController(text: ops[2]);
    final tO4 = TextEditingController(text: ops[3]);
    String mat = esEdit ? item['materia'] : 'memory';
    int resp = esEdit ? item['respuesta_correcta'] : 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF222232) : Colors.white,
        title: Text(esEdit ? "Editar Pregunta" : "Nueva Pregunta", style: GoogleFonts.fredoka(color: const Color(0xFF48CAE4))),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alineamos a la izquierda
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: mat,
                dropdownColor: widget.isDarkMode ? const Color(0xFF222232) : Colors.white,
                items: _materias.where((m)=>m!='Todas').map((m)=>DropdownMenuItem(value:m, child:Text(m.toUpperCase(), style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)))).toList(), 
                onChanged: (v)=>setS(()=>mat=v!), decoration: const InputDecoration(labelText: "Materia")
              ),
              const SizedBox(height: 15),
              
              // --- SECCIÓN DE BOTONES PARA GRADO ---
              Text("Selecciona el Grado:", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [1, 2, 3, 4, 5, 6].map((g) {
                  return ChoiceChip(
                    label: Text("$g", style: TextStyle(color: gradoSeleccionado == g ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                    selected: gradoSeleccionado == g,
                    selectedColor: const Color(0xFF9D4EDD),
                    backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200,
                    onSelected: (s) {
                      if (s) setS(() => gradoSeleccionado = g);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              // -------------------------------------

              TextField(controller: tText, maxLines: 2, decoration: const InputDecoration(labelText: "Pregunta")),
              const SizedBox(height: 15),
              Text("Opciones", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
              TextField(controller: tO1, decoration: const InputDecoration(labelText: "Opción A (0)", prefixIcon: Icon(Icons.looks_one))),
              TextField(controller: tO2, decoration: const InputDecoration(labelText: "Opción B (1)", prefixIcon: Icon(Icons.looks_two))),
              TextField(controller: tO3, decoration: const InputDecoration(labelText: "Opción C (2)", prefixIcon: Icon(Icons.looks_3))),
              TextField(controller: tO4, decoration: const InputDecoration(labelText: "Opción D (3)", prefixIcon: Icon(Icons.looks_4))),
              DropdownButtonFormField<int>(
                value: resp, dropdownColor: widget.isDarkMode ? const Color(0xFF222232) : Colors.white,
                items: [0,1,2,3].map((i)=>DropdownMenuItem(value:i, child:Text("Opción Correcta: $i", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)))).toList(), 
                onChanged: (v)=>setS(()=>resp=v!), decoration: const InputDecoration(labelText: "Respuesta")
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF48CAE4)),
            onPressed: () async {
              // Ahora guardamos usando la variable gradoSeleccionado de los botones
              if (esEdit) {
                await NeonDbService.actualizarPregunta(item['id'], mat, gradoSeleccionado, tText.text, [tO1.text, tO2.text, tO3.text, tO4.text], resp);
              } else {
                await NeonDbService.crearPregunta(mat, gradoSeleccionado, tText.text, [tO1.text, tO2.text, tO3.text, tO4.text], resp);
              }
              Navigator.pop(ctx); 
              _cargarPreguntas();
            }, 
            child: const Text("Guardar", style: TextStyle(color: Colors.white))
          )
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aplicando el doble filtro (Grado y Materia)
    List filtradas = _preguntas.where((p) {
      bool matchMateria = _materiaFiltro == 'Todas' || p['materia'] == _materiaFiltro;
      bool matchGrado = _gradoFiltro == 'Todos' || p['grado'].toString() == _gradoFiltro;
      return matchMateria && matchGrado;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 10),
            child: Text("Filtro por Grado:", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, children: _grados.map((g) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(g == 'Todos' ? g : "Grado $g", style: TextStyle(color: _gradoFiltro == g ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)), 
              selected: _gradoFiltro == g, selectedColor: const Color(0xFF9D4EDD), backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200,
              onSelected: (s) => setState(() => _gradoFiltro = g)
            ),
          )).toList())),

          Padding(
            padding: const EdgeInsets.only(left: 15, top: 5),
            child: Text("Filtro por Materia:", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, children: _materias.map((m) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(m.toUpperCase(), style: TextStyle(color: _materiaFiltro == m ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)), 
              selected: _materiaFiltro == m, selectedColor: const Color(0xFF48CAE4), backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200,
              onSelected: (s) => setState(() => _materiaFiltro = m)
            ),
          )).toList())),

          Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF48CAE4))) : ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: filtradas.length,
            itemBuilder: (context, i) {
              final p = filtradas[i];
              return Card(
                color: widget.isDarkMode ? const Color(0xFF222232) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF9D4EDD), child: Icon(Icons.quiz_rounded, color: Colors.white)),
                  // Agregamos la numeración de la pregunta usando el índice "i + 1"
                  title: Text("${i + 1}. ${p['pregunta_texto']}", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  subtitle: Text("${p['materia'].toUpperCase()} | Grado: ${p['grado']}", style: const TextStyle(color: Colors.grey)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent), onPressed: () => _dialogo(item: p)),
                    IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: () async { await NeonDbService.eliminarPregunta(p['id']); _cargarPreguntas(); }),
                  ]),
                )
              );
            },
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF48CAE4),
        onPressed: () => _dialogo(), 
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: Text("Nueva Pregunta", style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold))
      ),
    );
  }
}