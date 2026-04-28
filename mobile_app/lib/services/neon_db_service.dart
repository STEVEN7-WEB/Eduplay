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

  static Future<bool> registrarUsuario(String nombre, String email, String password, int grado) async {
    try {
      final connection = await _conectar();
      await connection.execute(
        // Agregamos 'student' como rol por defecto
        Sql.named('INSERT INTO users (name, email, password, grade, role) VALUES (@nombre, @email, @password, @grado, @rol)'),
        parameters: {
          'nombre': nombre, 
          'email': email, 
          'password': password, 
          'grado': grado,
          'rol': 'student'
        },
      );
      await connection.close();
      return await loginDirecto(email, password);
    } catch (e) {
      print('Error al registrar: $e');
      return false;
    }
  }

  static Future<bool> loginDirecto(String email, String password) async {
    try {
      final connection = await _conectar();
      final result = await connection.execute(
        Sql.named('SELECT id, grade, name FROM users WHERE email = @email AND password = @password'),
        parameters: {'email': email, 'password': password},
      );
      await connection.close();

      if (result.isNotEmpty) {
        final int userId = result[0][0] as int;
        final int grado = result[0][1] != null ? result[0][1] as int : 1; 
        final String nombre = result[0][2].toString();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('sesion_iniciada', true);
        await prefs.setInt('id_usuario', userId);
        await prefs.setInt('grado_usuario', grado);
        await prefs.setString('userName', nombre);
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerPreguntasPorMateria(String materia, int grado) async {
    try {
      final connection = await _conectar();
      
      // La tabla se llama 'preguntas' y usamos los nombres de columna exactos
      final result = await connection.execute(
        Sql.named('SELECT id, pregunta_texto, opciones, respuesta_correcta, materia, grado '
                  'FROM preguntas '
                  'WHERE materia = @materia AND grado = @grado'),
        parameters: {
          'materia': materia, 
          'grado': grado
        },
      );
      await connection.close();

      return result.map((row) => {
        'id': row[0],
        'text': row[1].toString(),           // pregunta_texto
        'options': row[2],                  // opciones (jsonb)
        'correct_option': row[3],           // respuesta_correcta
        'subject': row[4].toString(),       // materia
        'grade': row[5],                    // grado
      }).toList();

    } catch (e) {
      print('❌ Error al jalar preguntas de Neon: $e');
      return [];
    }
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}