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
      password: 'npg_XkHAZ3tCTf8U', // Nota de seguridad: Cuidado con compartir esta contraseña en entornos públicos
      port: 5432,
    );
    return await Connection.open(endpoint, settings: ConnectionSettings(sslMode: SslMode.require));
  }

  // === FUNCIÓN PARA ENCRIPTAR EL PIN ===
  static String hp(String texto) {
    var bytes = utf8.encode(texto); 
    var digest = sha256.convert(bytes); 
    return digest.toString(); 
  }

  /// REGISTRO DIRECTO A NEON
  // Añadimos "String avatar" como parámetro
  static Future<dynamic> registrarUsuario(String nombre, String email, String password, int grado, String avatar) async {
    try {
      final connection = await _conectar();
      
      // --- 1. Validar si el nombre ya existe ---
      final nameCheck = await connection.execute(
        Sql.named('SELECT id FROM users WHERE LOWER(name) = LOWER(@nombre)'),
        parameters: {'nombre': nombre},
      );

      if (nameCheck.isNotEmpty) {
        await connection.close();
        return 'duplicate_name'; 
      }
      // ------------------------------------------------

      // 2. Encriptamos el PIN antes de guardarlo
      final String passwordHasheado = hp(password);

      // 3. Insertamos el nuevo usuario con su avatar
      await connection.execute(
        Sql.named('INSERT INTO users (name, email, password, grade, role, avatar) VALUES (@nombre, @email, @password, @grado, @rol, @avatar)'),
        parameters: {
          'nombre': nombre, 
          'email': email, 
          'password': passwordHasheado, 
          'grado': grado,
          'rol': 'student',
          'avatar': avatar // Guardamos la ruta de la imagen
        },
      );
      await connection.close();
      
      // Si el registro es exitoso, iniciamos sesión automáticamente
      return await loginPorNombre(nombre, password);
      
    } catch (e) {
      if (e.toString().contains('users_email_key') || e.toString().contains('23505')) {
        print('Aviso: El correo ya existe en la base de datos.');
        return 'duplicate_email'; 
      }
      
      print('Error al registrar: $e');
      return false;
    }
  }

  /// LOGIN POR NOMBRE Y PIN
  static Future<bool> loginPorNombre(String nombre, String pin) async {
    try {
      final connection = await _conectar();
      
      // Agregamos "avatar" a la consulta SELECT (posición 4)
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
            // Obtenemos el avatar de la base de datos. Si es nulo, ponemos el de por defecto.
            final String userAvatar = row[4] != null ? row[4].toString() : 'assets/avatars/avatar1.png';

            // Guardamos todo en memoria
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('sesion_iniciada', true);
            await prefs.setInt('id_usuario', userId);
            await prefs.setInt('grado_usuario', grado);
            await prefs.setString('userName', userName);
            await prefs.setString('userAvatar', userAvatar); // Guardamos la ruta del avatar para usarlo en HomeScreen
            
            return true; // Login exitoso
          }
        }
        print("Se encontró el nombre, pero el PIN no coincide con ninguno.");
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

  /// CERRAR SESIÓN
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}