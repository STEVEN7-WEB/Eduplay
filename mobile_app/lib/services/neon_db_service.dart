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

  /// REGISTRO DIRECTO A NEON
  static Future<bool> registrarUsuario(String nombre, String email, String password, int grado) async {
    try {
      final connection = await _conectar();
      await connection.execute(
        Sql.named('INSERT INTO users (name, email, password, grade, role) VALUES (@nombre, @email, @password, @grado, @rol)'),
        parameters: {
          'nombre': nombre, 
          'email': email, 
          'password': password, // ⚠️ Se guarda en texto plano
          'grado': grado,
          'rol': 'student'
        },
      );
      await connection.close();
      return await loginPorNombre(nombre, password);
    } catch (e) {
      print('Error al registrar: $e');
      return false;
    }
  }

  /// LOGIN POR NOMBRE Y PIN (Adaptado a tu nueva pantalla)
  static Future<bool> loginPorNombre(String nombre, String pin) async {
    try {
      final connection = await _conectar();
      
      // Buscamos al usuario por nombre ignorando mayúsculas/minúsculas usando LOWER()
      final result = await connection.execute(
        Sql.named('SELECT id, grade, name, password FROM users WHERE LOWER(name) = LOWER(@nombre)'),
        parameters: {'nombre': nombre},
      );
      await connection.close();

      if (result.isNotEmpty) {
        final dbPassword = result[0][3].toString();

        // ⚠️ Comparamos el PIN exacto. (Fallará con usuarios creados en la Web que tengan Hash)
        if (dbPassword == pin) {
          final int userId = result[0][0] as int;
          final int grado = result[0][1] != null ? result[0][1] as int : 1; 
          final String userName = result[0][2].toString();

          // Guardamos sesión en memoria
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('sesion_iniciada', true);
          await prefs.setInt('id_usuario', userId);
          await prefs.setInt('grado_usuario', grado);
          await prefs.setString('userName', userName);
          return true;
        } else {
          print("El PIN no coincide");
        }
      }
      return false;
    } catch (e) {
      print('Error en loginPorNombre directo: $e');
      return false;
    }
  }

  /// OBTENER PREGUNTAS DIRECTAMENTE DE NEON
  static Future<List<Map<String, dynamic>>> obtenerPreguntasPorMateria(String materia, int grado) async {
    try {
      final connection = await _conectar();
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
        'text': row[1].toString(),           
        'options': row[2],                  
        'correct_option': row[3],           
        'subject': row[4].toString(),       
        'grade': row[5],                    
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