import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_core.dart';

class UserDbService {
  static Future<Map<String, dynamic>?> obtenerPerfilUsuario(int userId) async {
    try {
      final connection = await DbCore.conectar();
      
      final result = await connection.execute(
        Sql.named('SELECT name, grade, avatar, estrellas, role FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );

      String materiaFuerte = "";
      final topSubjectQuery = await connection.execute(
        Sql.named('SELECT subject FROM scores WHERE user_id = @id GROUP BY subject ORDER BY SUM(points) DESC LIMIT 1'),
        parameters: {'id': userId},
      );
      
      if (topSubjectQuery.isNotEmpty) {
        materiaFuerte = topSubjectQuery.first[0].toString();
      }

      await connection.close();

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'name': row[0].toString(),
          'grade': row[1] as int,
          'avatar': row[2] != null ? row[2].toString() : 'assets/avatars/avatar1.png',
          'estrellas': row[3] as int,
          'role': row[4].toString(),
          'materia_fuerte': materiaFuerte,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> actualizarNombreUsuario(int userId, String nuevoNombre) async {
    try {
      final connection = await DbCore.conectar();

      final nameCheck = await connection.execute(
        Sql.named('SELECT id FROM users WHERE LOWER(name) = LOWER(@nombre) AND id != @id'),
        parameters: {'nombre': nuevoNombre, 'id': userId},
      );

      if (nameCheck.isNotEmpty) {
        await connection.close();
        return false; 
      }

      await connection.execute(
        Sql.named('UPDATE users SET name = @nuevoNombre WHERE id = @id'),
        parameters: {'nuevoNombre': nuevoNombre, 'id': userId},
      );
      await connection.close();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', nuevoNombre);

      return true; 
    } catch (e) {
      return false;
    }
  }

  static Future<bool> actualizarAvatarUsuario(int userId, String nuevoAvatarPath) async {
    try {
      final connection = await DbCore.conectar();
      await connection.execute(
        Sql.named('UPDATE users SET avatar = @avatar WHERE id = @id'),
        parameters: {'avatar': nuevoAvatarPath, 'id': userId},
      );
      await connection.close();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userAvatar', nuevoAvatarPath);

      return true;
    } catch (e) {
      print('Error al actualizar avatar: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> obtenerResumenActividad(int userId) async {
    try {
      final connection = await DbCore.conectar();
      
      // ======================================================================
      // 🚀 LIMPIEZA DE MATERIAS DUPLICADAS: Deja solo la de mayor calificación
      // ======================================================================
      await connection.execute(
        Sql.named('''
          DELETE FROM scores 
          WHERE user_id = @id AND id NOT IN (
            SELECT s.id FROM (
              SELECT id, ROW_NUMBER() OVER (
                PARTITION BY LOWER(subject) 
                ORDER BY points DESC, id DESC
              ) as rn
              FROM scores
              WHERE user_id = @id
            ) s
            WHERE s.rn = 1
          )
        '''),
        parameters: {'id': userId},
      );
      // ======================================================================

      final misionesResult = await connection.execute(
        Sql.named('SELECT COUNT(*) FROM scores WHERE user_id = @id'),
        parameters: {'id': userId},
      );
      
      int totalMisiones = 0;
      if (misionesResult.isNotEmpty) {
        totalMisiones = misionesResult.first[0] as int;
      }

      final materiaResult = await connection.execute(
        Sql.named('SELECT subject FROM scores WHERE user_id = @id GROUP BY subject ORDER BY SUM(points) DESC LIMIT 1'),
        parameters: {'id': userId},
      );
      
      String materiaTop = "";
      if (materiaResult.isNotEmpty) {
        materiaTop = materiaResult.first[0].toString();
        if(materiaTop.isNotEmpty){
          materiaTop = materiaTop[0].toUpperCase() + materiaTop.substring(1).toLowerCase();
        }
      }

      // Mapeamos los puntajes individuales ya limpios para el HomeScreen
      final puntajesMateriasResult = await connection.execute(
        Sql.named('SELECT subject, points FROM scores WHERE user_id = @id'),
        parameters: {'id': userId},
      );

      Map<String, int> mapaPuntajes = {};
      for (final row in puntajesMateriasResult) {
        final String materiaKey = row[0].toString().toLowerCase().trim();
        final int puntos = row[1] as int;
        mapaPuntajes[materiaKey] = puntos;
      }

      await connection.close();

      return {
        'total_misiones': totalMisiones,
        'materia_top': materiaTop, 
        'tabla_puntajes': mapaPuntajes, 
      };
    } catch (e) {
      print('Error al obtener resumen de actividad: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerEstudiantesDelPadre(String emailPadre) async {
    try {
      final connection = await DbCore.conectar();
      final result = await connection.execute(
        Sql.named("SELECT id, name, grade, avatar, estrellas FROM users WHERE LOWER(email) = LOWER(@email) ORDER BY estrellas DESC"),
        parameters: {'email': emailPadre}
      );
      await connection.close();

      return result.map((row) => {
        'id': row[0] as int,
        'name': row[1].toString(),
        'grade': row[2] as int,
        'avatar': row[3] != null ? row[3].toString() : 'assets/avatars/avatar1.png',
        'estrellas': row[4] as int,
      }).toList();
    } catch (e) {
      print('Error al obtener hijos del padre: $e');
      return [];
    }
  }

  static Future<bool> reiniciarViaje(int userId) async {
    try {
      final connection = await DbCore.conectar();
      
      await connection.execute(
        Sql.named('UPDATE users SET estrellas = 0 WHERE id = @id'),
        parameters: {'id': userId},
      );

      await connection.execute(
        Sql.named('UPDATE scores SET points = 0 WHERE user_id = @id'),
        parameters: {'id': userId},
      );

      // Inyecta el Logro ID 99 (Insignia de Prestigio)
      await connection.execute(
        Sql.named('INSERT INTO user_logros (user_id, logro_id) VALUES (@userId, 99) ON CONFLICT DO NOTHING'),
        parameters: {'userId': userId},
      );
      
      await connection.close();
      return true;
    } catch (e) {
      print('Error al reiniciar viaje: $e');
      return false;
    }
  }

  static Future<bool> eliminarCuenta(int userId) async {
    try {
      final connection = await DbCore.conectar();
      await connection.execute(
        Sql.named('DELETE FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      await connection.close();
      return true;
    } catch (e) {
      print('Error al eliminar cuenta desde perfil: $e');
      return false;
    }
  }
}