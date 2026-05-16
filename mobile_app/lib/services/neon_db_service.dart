import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NeonDbService {
  static Future<Connection> _conectar() async {
    final endpoint = Endpoint(
      host: 'ep-bold-sea-ammozaye-pooler.c-5.us-east-1.aws.neon.tech',
      database: 'neondb',
      username: 'neondb_owner',
      password: 'npg_XkHAZ3tCTf8U', 
      port: 5432,
    );
    return await Connection.open(endpoint, settings: ConnectionSettings(sslMode: SslMode.require));
  }

  static String hp(String texto) {
    var bytes = utf8.encode(texto); 
    var digest = sha256.convert(bytes); 
    return digest.toString(); 
  }

  static Future<dynamic> registrarUsuario(String nombre, String email, String password, int grado, String avatar) async {
    try {
      final connection = await _conectar();
      
      final nameCheck = await connection.execute(
        Sql.named('SELECT id FROM users WHERE LOWER(name) = LOWER(@nombre)'),
        parameters: {'nombre': nombre},
      );

      if (nameCheck.isNotEmpty) {
        await connection.close();
        return 'duplicate_name'; 
      }

      final String passwordHasheado = hp(password);

      await connection.execute(
        Sql.named('INSERT INTO users (name, email, password, grade, role, avatar) VALUES (@nombre, @email, @password, @grado, @rol, @avatar)'),
        parameters: {
          'nombre': nombre, 
          'email': email, 
          'password': passwordHasheado, 
          'grado': grado,
          'rol': 'student',
          'avatar': avatar 
        },
      );
      await connection.close();
      
      return await loginPorNombre(nombre, password);
      
    } catch (e) {
      if (e.toString().contains('users_email_key') || e.toString().contains('23505')) {
        return 'duplicate_email'; 
      }
      return false;
    }
  }

  static Future<bool> loginPorNombre(String nombre, String pin) async {
    try {
      final connection = await _conectar();
      
      final result = await connection.execute(
        Sql.named('SELECT id, grade, name, password, avatar FROM users WHERE LOWER(name) = LOWER(@nombre)'),
        parameters: {'nombre': nombre},
      );
      await connection.close();

      if (result.isNotEmpty) {
        final String pinHasheadoIntento = hp(pin);

        for (final row in result) {
          final dbPassword = row[3].toString();

          if (dbPassword == pinHasheadoIntento) {
            final int userId = row[0] as int;
            final int grado = row[1] != null ? row[1] as int : 1; 
            final String userName = row[2].toString();
            final String userAvatar = row[4] != null ? row[4].toString() : 'assets/avatars/avatar1.png';

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('sesion_iniciada', true);
            await prefs.setInt('id_usuario', userId);
            await prefs.setInt('grado_usuario', grado);
            await prefs.setString('userName', userName);
            await prefs.setString('userAvatar', userAvatar); 
            await prefs.setString('userRole', 'student');
            
            return true; 
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> loginPorCorreo(String email, String password) async {
    try {
      final connection = await _conectar();
      
      final result = await connection.execute(
        Sql.named('SELECT id, grade, name, password, avatar, role FROM users WHERE LOWER(email) = LOWER(@email)'),
        parameters: {'email': email},
      );
      await connection.close();

      if (result.isNotEmpty) {
        final String passHasheadoIntento = hp(password);

        for (final row in result) {
          final dbPassword = row[3].toString();

          if (dbPassword == passHasheadoIntento) {
            final String dbRole = row[5].toString(); 
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('sesion_iniciada', true);
            await prefs.setString('parentEmail', email.toLowerCase()); 
            await prefs.setString('userRole', dbRole); 
            
            return true; 
          }
        }
      }
      return false;
    } catch (e) {
      print('Error en loginPorCorreo: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> obtenerPerfilUsuario(int userId) async {
    try {
      final connection = await _conectar();
      
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
      final connection = await _conectar();

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
      final connection = await _conectar();
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

  static Future<List<Map<String, dynamic>>> obtenerPreguntasPorMateria(String materia, int grado) async {
    try {
      final connection = await _conectar();
      final result = await connection.execute(
        Sql.named('SELECT id, pregunta_texto, opciones, respuesta_correcta, materia, grado FROM preguntas WHERE materia = @materia AND grado = @grado'),
        parameters: {'materia': materia, 'grado': grado},
      );
      await connection.close();

      return result.map((row) => {
        'id': row[0],
        'text': row[1].toString(),          
        'options': row[2],                  
        'correct_option': row[3],           
        'subject': row[4].toString(),       
        'grade': row[5],                    
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> obtenerResumenActividad(int userId) async {
    try {
      final connection = await _conectar();
      
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

      await connection.close();

      return {
        'total_misiones': totalMisiones,
        'materia_top': materiaTop, 
      };
    } catch (e) {
      print('Error al obtener resumen de actividad: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerEstudiantesDelPadre(String emailPadre) async {
    try {
      final connection = await _conectar();
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

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> guardarResultadoKNN({
    required int userId,
    required int rango,
    required String etiqueta,
  }) async {
    try {
      final connection = await _conectar();
      
      await connection.execute(
        Sql.named('INSERT INTO knn_results (user_id, rango, etiqueta, fecha) VALUES (@user_id, @rango, @etiqueta, CURRENT_TIMESTAMP)'),
        parameters: {
          'user_id': userId,
          'rango': rango,
          'etiqueta': etiqueta,
        },
      );
      
      await connection.close();
      return true;
    } catch (e) {
      print('Error al guardar resultado KNN: $e');
      return false;
    }
  }

  // ==========================================================
  // FUNCIONES DE ADMIN
  // ==========================================================

  static Future<List<Map<String, dynamic>>> obtenerTodosLosUsuarios() async {
    try {
      final connection = await _conectar();
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
      final connection = await _conectar();
      await connection.execute(Sql.named('DELETE FROM users WHERE id = @id'), parameters: {'id': id});
      await connection.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> actualizarRolUsuario(int id, String nuevoRol) async {
    try {
      final connection = await _conectar(); 
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
      final connection = await _conectar();
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
      final connection = await _conectar();
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
      final connection = await _conectar();
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
      final connection = await _conectar();
      await connection.execute(Sql.named("DELETE FROM preguntas WHERE id = @id"), parameters: {'id': id});
      await connection.close();
      return true;
    } catch (e) {
      print("Error al eliminar pregunta: $e");
      return false;
    }
  }

  // ==========================================================
  // LOGROS Y RÉCORDS
  // ==========================================================

  static Future<List<Map<String, dynamic>>> obtenerLogrosUsuario(int userId) async {
    try {
      final connection = await _conectar();
      final result = await connection.execute(
        Sql.named('''
          SELECT l.id, l.titulo, l.descripcion, l.icono, l.requisito_estrellas,
          (CASE WHEN ul.logro_id IS NULL THEN false ELSE true END) as desbloqueado
          FROM logros l
          LEFT JOIN user_logros ul ON l.id = ul.logro_id AND ul.user_id = @userId
          ORDER BY l.requisito_estrellas ASC
        '''),
        parameters: {'userId': userId},
      );
      await connection.close();

      return result.map((row) => {
        'id': row[0],
        'titulo': row[1].toString(),
        'descripcion': row[2].toString(),
        'icono': row[3].toString(),
        'requisito': row[4] as int,
        'desbloqueado': row[5] as bool,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> verificarYDesbloquearLogros(int userId) async {
    try {
      final connection = await _conectar();
      await connection.execute(
        Sql.named('''
          INSERT INTO user_logros (user_id, logro_id)
          SELECT @userId, id FROM logros 
          WHERE requisito_estrellas <= (SELECT estrellas FROM users WHERE id = @userId)
          AND id NOT IN (SELECT logro_id FROM user_logros WHERE user_id = @userId)
          ON CONFLICT DO NOTHING
        '''),
        parameters: {'userId': userId},
      );
      await connection.close();
    } catch (e) {
      print('Error al actualizar logros: $e');
    }
  }

  static Future<int> obtenerMejorPuntajeMateria(int userId, String materia) async {
    try {
      final connection = await _conectar();
      final result = await connection.execute(
        Sql.named('SELECT MAX(points) FROM scores WHERE user_id = @id AND subject = @materia'),
        parameters: {'id': userId, 'materia': materia},
      );
      await connection.close();

      if (result.isNotEmpty && result.first[0] != null) {
        return result.first[0] as int;
      }
      return 0; 
    } catch (e) {
      print('Error al obtener mejor puntaje: $e');
      return 0;
    }
  }

  static Future<bool> guardarProgresoExamen({
    required int userId,
    required String materia,
    required int estrellasGanadas,
  }) async {
    try {
      final connection = await _conectar();
      
      await connection.execute(
        Sql.named('UPDATE users SET estrellas = estrellas + @estrellas WHERE id = @id'),
        parameters: {'estrellas': estrellasGanadas, 'id': userId},
      );

      final existingScore = await connection.execute(
        Sql.named('SELECT id FROM scores WHERE user_id = @user_id AND subject = @subject'),
        parameters: {'user_id': userId, 'subject': materia},
      );

      if (existingScore.isNotEmpty) {
        await connection.execute(
          Sql.named('UPDATE scores SET points = @points WHERE user_id = @user_id AND subject = @subject'),
          parameters: {'points': estrellasGanadas, 'user_id': userId, 'subject': materia},
        );
      } else {
        await connection.execute(
          Sql.named('INSERT INTO scores (user_id, subject, points) VALUES (@user_id, @subject, @points)'),
          parameters: {'user_id': userId, 'subject': materia, 'points': estrellasGanadas},
        );
      }
      
      await connection.close();
      await verificarYDesbloquearLogros(userId);
      
      return true;
    } catch (e) {
      print("Error guardando récord: $e");
      return false;
    }
  }

  // ==========================================================
  // RECUPERACIÓN DE CONTRASEÑA
  // ==========================================================
  
  static Future<String?> obtenerCorreoDeUsuario(String identificador) async {
    try {
      final connection = await _conectar();
      bool esCorreo = identificador.contains('@');
      
      String query = esCorreo 
          ? "SELECT email FROM users WHERE LOWER(email) = LOWER(@id) AND role != 'student' LIMIT 1"
          : "SELECT email FROM users WHERE LOWER(name) = LOWER(@id) LIMIT 1";

      final result = await connection.execute(
        Sql.named(query),
        parameters: {'id': identificador},
      );
      
      await connection.close();
      if (result.isNotEmpty) return result.first[0].toString();
      return null;
    } catch (e) {
      print("Error obteniendo correo: $e");
      return null;
    }
  }

  static Future<bool> actualizarPassword(String identificador, String nuevaPassword) async {
    try {
      final connection = await _conectar();
      final passHasheado = hp(nuevaPassword);
      bool esCorreo = identificador.contains('@');

      String query = esCorreo 
          ? "UPDATE users SET password = @pass WHERE LOWER(email) = LOWER(@id) AND role != 'student'"
          : "UPDATE users SET password = @pass WHERE LOWER(name) = LOWER(@id)";

      await connection.execute(
        Sql.named(query),
        parameters: {'pass': passHasheado, 'id': identificador},
      );
      
      await connection.close();
      return true;
    } catch (e) {
      print("Error actualizando password: $e");
      return false;
    }
  }
}