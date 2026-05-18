import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'db_core.dart';

class AdminDbService {
  static Future<List<Map<String, dynamic>>> obtenerTodosLosUsuarios() async {
    try {
      final connection = await DbCore.conectar();
      final result = await connection.execute(Sql.named("SELECT id, name, email, role, grade FROM users ORDER BY role ASC, id DESC"));
      await connection.close();

      return result.map((row) => {
        'id': row[0] as int,
        'name': row[1].toString(),
        'email': row[2] != null ? row[2].toString() : 'Sin correo',
        'role': row[3].toString(),
        'grade': row[4] != null ? row[4] as int : 0,
      }).toList();
    } catch (e) {
      print('Error admin usuarios: $e');
      return [];
    }
  }

  static Future<bool> eliminarUsuario(int id) async {
    try {
      final connection = await DbCore.conectar();
      await connection.execute(Sql.named('DELETE FROM users WHERE id = @id'), parameters: {'id': id});
      await connection.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> actualizarRolUsuario(int id, String nuevoRol) async {
    try {
      final connection = await DbCore.conectar(); 
      await connection.execute(
        Sql.named("UPDATE users SET role = @rol WHERE id = @id"), 
        parameters: {'rol': nuevoRol, 'id': id}
      );
      await connection.close();
      return true;
    } catch (e) {
      print("Error al cambiar rol: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerTodasLasPreguntas() async {
    try {
      final connection = await DbCore.conectar();
      final results = await connection.execute("SELECT id, materia, grado, pregunta_texto, opciones, respuesta_correcta FROM preguntas ORDER BY id ASC");
      await connection.close();
      
      List<Map<String, dynamic>> preguntas = [];
      for (final row in results) {
        preguntas.add({
          'id': row[0],
          'materia': row[1],
          'grado': row[2],
          'pregunta_texto': row[3],
          'opciones': row[4], 
          'respuesta_correcta': row[5],
        });
      }
      return preguntas;
    } catch (e) {
      print("Error al obtener preguntas: $e");
      return [];
    }
  }

  static Future<bool> crearPregunta(String materia, int grado, String texto, List<String> opciones, int respCorrecta) async {
    try {
      final connection = await DbCore.conectar();
      await connection.execute(
        Sql.named("INSERT INTO preguntas (materia, grado, pregunta_texto, opciones, respuesta_correcta) VALUES (@materia, @grado, @texto, @opciones::jsonb, @resp)"),
        parameters: {
          'materia': materia,
          'grado': grado,
          'texto': texto,
          'opciones': jsonEncode(opciones), 
          'resp': respCorrecta,
        }
      );
      await connection.close();
      return true;
    } catch (e) {
      print("Error al crear pregunta: $e");
      return false;
    }
  }

  static Future<bool> actualizarPregunta(int id, String materia, int grado, String texto, List<String> opciones, int respCorrecta) async {
    try {
      final connection = await DbCore.conectar();
      await connection.execute(
        Sql.named("UPDATE preguntas SET materia = @materia, grado = @grado, pregunta_texto = @texto, opciones = @opciones::jsonb, respuesta_correcta = @resp WHERE id = @id"),
        parameters: {
          'id': id,
          'materia': materia,
          'grado': grado,
          'texto': texto,
          'opciones': jsonEncode(opciones),
          'resp': respCorrecta,
        }
      );
      await connection.close();
      return true;
    } catch (e) {
      print("Error al actualizar pregunta: $e");
      return false;
    }
  }

  static Future<bool> eliminarPregunta(int id) async {
    try {
      final connection = await DbCore.conectar();
      await connection.execute(Sql.named("DELETE FROM preguntas WHERE id = @id"), parameters: {'id': id});
      await connection.close();
      return true;
    } catch (e) {
      print("Error al eliminar pregunta: $e");
      return false;
    }
  }
}