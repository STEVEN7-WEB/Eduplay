import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/neon_db_service.dart';

class UsuariosView extends StatefulWidget {
  final bool isDarkMode;
  const UsuariosView({required this.isDarkMode, super.key});
  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  List<Map<String, dynamic>> _usuarios = [];
  String _filtroActual = 'Todos';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    final data = await NeonDbService.obtenerTodosLosUsuarios();
    setState(() {
      _usuarios = data;
      _isLoading = false;
    });
  }

  Future<void> _cambiarRol(int id, String rolActual) async {
    String nuevoRol = rolActual == 'admin' ? 'student' : 'admin';
    bool? confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF222232) : Colors.white,
        title: Text("Cambiar Rol", style: GoogleFonts.fredoka(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: Text("¿Seguro que quieres hacer a este usuario $nuevoRol?", style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF48CAE4)),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Confirmar", style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );

    if (confirmar == true) {
      bool exito = await NeonDbService.actualizarRolUsuario(id, nuevoRol);
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Rol actualizado a $nuevoRol"), backgroundColor: Colors.green));
        _cargarUsuarios();
      }
    }
  }

  Widget _buildFiltroBtn(String rol, IconData icon) {
    bool seleccionado = _filtroActual == rol;
    return ChoiceChip(
      label: Text(rol.toUpperCase(), style: TextStyle(color: seleccionado ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
      selected: seleccionado,
      selectedColor: const Color(0xFF48CAE4),
      backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200,
      avatar: Icon(icon, color: seleccionado ? Colors.white : Colors.grey, size: 18),
      onSelected: (bool selected) => setState(() => _filtroActual = rol),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF48CAE4)));

    List<Map<String, dynamic>> filtrados = _usuarios.where((u) => _filtroActual == 'Todos' ? true : u['role'] == _filtroActual).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFiltroBtn('Todos', Icons.people_alt_rounded),
              _buildFiltroBtn('student', Icons.school_rounded),
              _buildFiltroBtn('admin', Icons.admin_panel_settings_rounded),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: filtrados.length,
            itemBuilder: (context, i) {
              final u = filtrados[i];
              bool isAdmin = u['role'] == 'admin';
              return Card(
                color: widget.isDarkMode ? const Color(0xFF222232) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? const Color(0xFF9D4EDD) : const Color(0xFF48CAE4), 
                    child: Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded, color: Colors.white)
                  ),
                  title: Text(u['name'], style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  subtitle: Text("ID: ${u['id']} | Rol: ${u['role']}", style: const TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.manage_accounts_rounded, color: Colors.orangeAccent), onPressed: () => _cambiarRol(u['id'], u['role'])),
                      IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: () async {
                        await NeonDbService.eliminarUsuario(u['id']);
                        _cargarUsuarios();
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}