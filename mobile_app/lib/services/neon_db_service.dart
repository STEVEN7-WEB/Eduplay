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

  /// LOGIN POR NOMBRE Y PIN (PARA ALUMNOS)
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
            // Obtenemos el avatar de la base de datos. Si es nulo, ponemos el de por defecto.
            final String userAvatar = row[4] != null ? row[4].toString() : 'assets/avatars/avatar1.png';

            // Guardamos todo en memoria
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('sesion_iniciada', true);
            await prefs.setInt('id_usuario', userId);
            await prefs.setInt('grado_usuario', grado);
            await prefs.setString('userName', userName);
            await prefs.setString('userAvatar', userAvatar); 
            await prefs.setString('userRole', 'student');
            
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

  /// LOGIN POR CORREO (PARA PADRES)
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
            final int userId = row[0] as int;
            final int grado = row[1] != null ? row[1] as int : 1; 
            final String userName = row[2].toString();
            final String userAvatar = row[4] != null ? row[4].toString() : 'assets/avatars/avatar1.png';

            // Guardamos todo en memoria
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('sesion_iniciada', true);
            await prefs.setInt('id_usuario', userId);
            await prefs.setInt('grado_usuario', grado);
            await prefs.setString('userName', userName);
            await prefs.setString('userAvatar', userAvatar); 
            await prefs.setString('userRole', 'parent'); // Marcamos que es un padre
            
            return true; // Login exitoso
          }
        }
        print("Se encontró el correo, pero la contraseña no coincide.");
      }
      return false;
    } catch (e) {
      print('Error en loginPorCorreo directo: $e');
      return false;
    }
  }

  /// OBTENER PERFIL DE USUARIO 
  static Future<Map<String, dynamic>?> obtenerPerfilUsuario(int userId) async {
    try {
      final connection = await _conectar();
      
      // Consultamos estrictamente los datos que existen en tu BD
      final result = await connection.execute(
        Sql.named('''
          SELECT name, grade, avatar, estrellas, role
          FROM users 
          WHERE id = @id
        '''),
        parameters: {'id': userId},
      );
      
      await connection.close();

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'name': row[0].toString(),
          'grade': row[1] as int,
          'avatar': row[2] != null ? row[2].toString() : 'assets/avatars/avatar1.png',
          'estrellas': row[3] as int,
          'role': row[4].toString(),
        };
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener el perfil de Neon: $e');
      return null;
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

  /// ACTUALIZAR NOMBRE DE USUARIO
  static Future<bool> actualizarNombreUsuario(int userId, String nuevoNombre) async {
    try {
      final connection = await _conectar();

      // 1. Verificar que el nuevo nombre no esté ocupado por otro usuario
      final nameCheck = await connection.execute(
        Sql.named('SELECT id FROM users WHERE LOWER(name) = LOWER(@nombre) AND id != @id'),
        parameters: {'nombre': nuevoNombre, 'id': userId},
      );

      if (nameCheck.isNotEmpty) {
        await connection.close();
        print('El nombre ya está en uso por otra persona.');
        return false; 
      }

      // 2. Actualizar el nombre en la base de datos
      await connection.execute(
        Sql.named('UPDATE users SET name = @nuevoNombre WHERE id = @id'),
        parameters: {
          'nuevoNombre': nuevoNombre, 
          'id': userId
        },
      );
      await connection.close();

      // 3. Actualizar el nombre en SharedPreferences para que la app lo sepa
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', nuevoNombre);

      return true; // Se actualizó con éxito
    } catch (e) {
      print('❌ Error al actualizar el nombre en Neon: $e');
      return false;
    }
  }

  /// CERRAR SESIÓN
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}