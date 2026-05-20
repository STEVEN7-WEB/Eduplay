import 'package:postgres/postgres.dart';
import 'db_core.dart';

class GameDbService {

  // =========================
  // OBTENER PREGUNTAS
  // =========================
  static Future<List<Map<String, dynamic>>> obtenerPreguntasPorMateria(
      String materia,
      int grado,
      ) async {

    try {

      final connection = await DbCore.conectar();

      final result = await connection.execute(
        Sql.named('''
          SELECT 
            id,
            pregunta_texto,
            opciones,
            respuesta_correcta,
            materia,
            grado
          FROM preguntas
          WHERE materia = @materia
          AND grado = @grado
        '''),
        parameters: {
          'materia': materia,
          'grado': grado,
        },
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

      print("Error obteniendo preguntas: $e");

      return [];
    }
  }

  // =========================
  // OBTENER LOGROS
  // =========================
  static Future<List<Map<String, dynamic>>> obtenerLogrosUsuario(
      int userId,
      ) async {

    try {

      final connection = await DbCore.conectar();

      final result = await connection.execute(
        Sql.named('''
          SELECT 
            l.id,
            l.titulo,
            l.descripcion,
            l.icono,
            l.requisito_estrellas,
            (
              CASE 
                WHEN ul.logro_id IS NULL 
                THEN false 
                ELSE true 
              END
            ) as desbloqueado

          FROM logros l

          LEFT JOIN user_logros ul
          ON l.id = ul.logro_id
          AND ul.user_id = @userId

          ORDER BY l.requisito_estrellas ASC
        '''),
        parameters: {
          'userId': userId,
        },
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

      print("Error obteniendo logros: $e");

      return [];
    }
  }

  // =========================
  // DESBLOQUEAR LOGROS
  // =========================
  static Future<void> verificarYDesbloquearLogros(
      int userId,
      ) async {

    try {

      final connection = await DbCore.conectar();

      await connection.execute(
        Sql.named('''
          INSERT INTO user_logros (
            user_id,
            logro_id
          )

          SELECT 
            @userId,
            id

          FROM logros

          WHERE requisito_estrellas <= (
            SELECT estrellas
            FROM users
            WHERE id = @userId
          )

          AND id NOT IN (
            SELECT logro_id
            FROM user_logros
            WHERE user_id = @userId
          )

          ON CONFLICT DO NOTHING
        '''),
        parameters: {
          'userId': userId,
        },
      );

      await connection.close();

    } catch (e) {

      print('Error al actualizar logros: $e');
    }
  }

  // =========================
  // MEJOR PUNTAJE
  // =========================
  static Future<int> obtenerMejorPuntajeMateria(
      int userId,
      String materia,
      ) async {

    try {

      final connection = await DbCore.conectar();

      final result = await connection.execute(
        Sql.named('''
          SELECT MAX(points)
          FROM scores
          WHERE user_id = @id
          AND subject = @materia
        '''),
        parameters: {
          'id': userId,
          'materia': materia,
        },
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

  // =========================
  // GUARDAR PROGRESO
  // =========================
  static Future<bool> guardarProgresoExamen({
    required int userId,
    required String materia,
    required int estrellasGanadas,
  }) async {

    try {

      final connection = await DbCore.conectar();

      // Sumar estrellas
      await connection.execute(
        Sql.named('''
          UPDATE users
          SET estrellas = estrellas + @estrellas
          WHERE id = @id
        '''),
        parameters: {
          'estrellas': estrellasGanadas,
          'id': userId,
        },
      );

      // Verificar si ya existe
      final existingScore = await connection.execute(
        Sql.named('''
          SELECT id
          FROM scores
          WHERE user_id = @user_id
          AND subject = @subject
        '''),
        parameters: {
          'user_id': userId,
          'subject': materia,
        },
      );

      // SI EXISTE -> guardar el mayor
      if (existingScore.isNotEmpty) {

        await connection.execute(
          Sql.named('''
            UPDATE scores

            SET points = GREATEST(points, @points),
                last_played = CURRENT_TIMESTAMP

            WHERE user_id = @user_id
            AND subject = @subject
          '''),
          parameters: {
            'points': estrellasGanadas,
            'user_id': userId,
            'subject': materia,
          },
        );

      } else {

        // SI NO EXISTE -> insertar
        await connection.execute(
          Sql.named('''
            INSERT INTO scores (
              user_id,
              subject,
              points,
              last_played
            )

            VALUES (
              @user_id,
              @subject,
              @points,
              CURRENT_TIMESTAMP
            )
          '''),
          parameters: {
            'user_id': userId,
            'subject': materia,
            'points': estrellasGanadas,
          },
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

  // =========================
  // OBTENER CALIFICACIONES
  // =========================
  static Future<Map<String, dynamic>?> obtenerCalificacionesUsuario(
      int userId,
      ) async {

    try {

      final connection = await DbCore.conectar();

      final result = await connection.execute(
        Sql.named('''
          SELECT subject, points
          FROM scores
          WHERE user_id = @id
        '''),
        parameters: {
          'id': userId,
        },
      );

      await connection.close();

      if (result.isEmpty) {
        return null;
      }

      Map<String, dynamic> calificaciones = {

        'memoria': 0,
        'matematicas': 0,
        'gramatica': 0,
        'ingles': 0,
        'geografia': 0,
        'arte': 0,
        'ciencia': 0,
        'logica': 0,
      };

      for (final row in result) {

        String subject =
        row[0].toString().toLowerCase().trim();

        int points = row[1] as int;

        print("Materia encontrada: $subject -> $points");

        switch (subject) {

          case 'memory':
            calificaciones['memoria'] = points;
            break;

          case 'math':
            calificaciones['matematicas'] = points;
            break;

          case 'grammar':
            calificaciones['gramatica'] = points;
            break;

          case 'english':
            calificaciones['ingles'] = points;
            break;

          case 'geography':
            calificaciones['geografia'] = points;
            break;

          case 'art':
            calificaciones['arte'] = points;
            break;

          case 'science':
            calificaciones['ciencia'] = points;
            break;

          case 'logic':
            calificaciones['logica'] = points;
            break;
        }
      }

      print("Calificaciones finales:");
      print(calificaciones);

      return calificaciones;

    } catch (e) {

      print('Error obteniendo calificaciones: $e');

      return null;
    }
  }

  // =========================
  // GUARDAR RESULTADO KNN
  // =========================
  static Future<bool> guardarResultadoKNN({
    required int userId,
    required int rango,
    required String etiqueta,
    required double promedioGeneral,
    required String recomendacion,
  }) async {

    try {

      final connection = await DbCore.conectar();

      await connection.execute(
        Sql.named('''
          INSERT INTO knn_results (
            user_id,
            rango,
            etiqueta,
            promedio_general,
            recomendacion,
            generado_en
          )

          VALUES (
            @user_id,
            @rango,
            @etiqueta,
            @promedio_general,
            @recomendacion,
            CURRENT_TIMESTAMP
          )
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

  // =========================
  // HISTORIAL KNN
  // =========================
  static Future<List<Map<String, dynamic>>>
  obtenerTodosResultadosKNN() async {

    try {

      final connection = await DbCore.conectar();

      final result = await connection.execute(
        Sql.named('''
          SELECT
            k.user_id,
            u.name,
            u.grade,
            k.rango,
            k.etiqueta,
            k.promedio_general,
            k.recomendacion,
            k.generado_en

          FROM knn_results k

          JOIN users u
          ON k.user_id = u.id

          ORDER BY k.generado_en DESC
        '''),
      );

      await connection.close();

      return result.map((row) => {

        'user_id': row[0] as int,
        'nombre': row[1].toString(),
        'grado': row[2],
        'rango': row[3] as int,
        'etiqueta': row[4].toString(),
        'promedio_general': row[5],
        'recomendacion': row[6].toString(),
        'fecha': row[7],

      }).toList();

    } catch (e) {

      print('Error al obtener historial KNN: $e');

      return [];
    }
  }
}