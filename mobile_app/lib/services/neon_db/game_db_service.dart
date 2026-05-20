import 'package:postgres/postgres.dart';
import 'db_core.dart';

class GameDbService {
  static Future<List<Map<String, dynamic>>> obtenerPreguntasPorMateria(String materia, int grado) async {
    try {
      final connection = await DbCore.conectar();
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

  static Future<List<Map<String, dynamic>>> obtenerLogrosUsuario(int userId) async {
    try {
      final connection = await DbCore.conectar();
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
      final connection = await DbCore.conectar();
      // Inserta logros basados en las estrellas actuales de forma permanente
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
      final connection = await DbCore.conectar();
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
      final connection = await DbCore.conectar();
      
      // Sumamos las estrellas al usuario
      await connection.execute(
        Sql.named('UPDATE users SET estrellas = estrellas + @estrellas WHERE id = @id'),
        parameters: {'estrellas': estrellasGanadas, 'id': userId},
      );

      // Verificamos si ya existe la materia para evitar crear filas duplicadas desde el inicio
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
      
      // Escanea si el nuevo puntaje desbloquea alguna medalla
      await verificarYDesbloquearLogros(userId);
      
      return true;
    } catch (e) {
      print("Error guardando récord: $e");
      return false;
    }
  }

  // --- NUEVA FUNCIÓN: Obtiene y agrupa las calificaciones de la tabla 'scores' ---
  static Future<Map<String, dynamic>?> obtenerCalificacionesUsuario(int userId) async {
    try {
      final connection = await DbCore.conectar();
      
      final result = await connection.execute(
        Sql.named('SELECT subject, points FROM scores WHERE user_id = @id'),
        parameters: {'id': userId},
      );
      await connection.close();

      if (result.isNotEmpty) {
        Map<String, dynamic> calificaciones = {};
        
        // Convertimos las filas separadas en un solo mapa adaptado a la vista
        for (final row in result) {
          String subjectStr = row[0].toString().toLowerCase();
          int points = row[1] as int;
          
          if (subjectStr.contains('memoria')) calificaciones['memoria'] = points;
          else if (subjectStr.contains('mate')) calificaciones['matematicas'] = points;
          else if (subjectStr.contains('gram')) calificaciones['gramatica'] = points;
          else if (subjectStr.contains('ing')) calificaciones['ingles'] = points;
          else if (subjectStr.contains('geo')) calificaciones['geografia'] = points;
          else if (subjectStr.contains('arte')) calificaciones['arte'] = points;
          else if (subjectStr.contains('cie')) calificaciones['ciencia'] = points;
          else if (subjectStr.contains('log') || subjectStr.contains('lóg')) calificaciones['logica'] = points;
          else calificaciones[subjectStr] = points;
        }
        return calificaciones;
      }
      return null;
    } catch (e) {
      print('Error obteniendo calificaciones: $e');
      return null;
    }
  }

  // --- FUNCIÓN ACTUALIZADA: Ahora guarda el promedio y la recomendación ---
  static Future<bool> guardarResultadoKNN({
    required int userId,
    required int rango,
    required String etiqueta,
    required double promedioGeneral, 
    required String recomendacion,   
  }) async {
    try {
      final connection = await DbCore.conectar();
      
      // Se agregaron los nuevos campos al INSERT INTO basándose en la estructura de tu BD
      await connection.execute(
        Sql.named('''
          INSERT INTO knn_results 
          (user_id, rango, etiqueta, promedio_general, recomendacion, generado_en) 
          VALUES 
          (@user_id, @rango, @etiqueta, @promedio_general, @recomendacion, CURRENT_TIMESTAMP)
        '''),
        parameters: {
          'user_id': userId,
          'rango': rango,
          'etiqueta': etiqueta,
          'promedio_general': promedioGeneral,
          'recomendacion': recomendacion,
        },
      );
      
      await connection.close();
      return true;
    } catch (e) {
      print('Error al guardar resultado KNN: $e');
      return false;
    }
  }

  // --- NUEVA FUNCIÓN: Extrae todos los resultados KNN para el panel de admin ---
  static Future<List<Map<String, dynamic>>> obtenerTodosResultadosKNN() async {
    try {
      final connection = await DbCore.conectar();
      
      // Extraemos la información ordenando desde el diagnóstico más reciente al más viejo
      final result = await connection.execute(
        Sql.named('''
          SELECT user_id, rango, etiqueta, promedio_general, recomendacion, generado_en 
          FROM knn_results 
          ORDER BY generado_en DESC
        ''')
      );
      
      await connection.close();

      return result.map((row) => {
        'user_id': row[0] as int,
        'rango': row[1] as int,
        'etiqueta': row[2].toString(),
        'promedio_general': row[3],
        'recomendacion': row[4].toString(),
        'fecha': row[5],
      }).toList();
      
    } catch (e) {
      print('Error al obtener el historial KNN: $e');
      return [];
    }
  }
}