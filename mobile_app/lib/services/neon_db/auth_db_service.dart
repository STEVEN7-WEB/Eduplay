import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_core.dart';

class AuthDbService {

  // =========================================================
  // 🚀 REGISTRAR USUARIO
  // =========================================================
  static Future<dynamic> registrarUsuario(
    String nombre,
    String email,
    String password,
    int grado,
    String avatar,
  ) async {
    try {
      final connection = await DbCore.conectar();

      // Verificar nombre duplicado
      final nameCheck = await connection.execute(
        Sql.named(
          'SELECT id FROM users WHERE LOWER(name) = LOWER(@nombre)',
        ),
        parameters: {'nombre': nombre},
      );

      if (nameCheck.isNotEmpty) {
        await connection.close();
        return 'duplicate_name';
      }

      final String passwordHasheado = DbCore.hp(password);

      // Crear usuario
      await connection.execute(
        Sql.named('''
          INSERT INTO users
          (
            name,
            email,
            password,
            grade,
            role,
            avatar
          )
          VALUES
          (
            @nombre,
            @email,
            @password,
            @grado,
            @rol,
            @avatar
          )
        '''),
        parameters: {
          'nombre': nombre,
          'email': email,
          'password': passwordHasheado,
          'grado': grado,
          'rol': 'student',
          'avatar': avatar,
        },
      );

      await connection.close();

      // Login automático
      return await loginPorNombre(nombre, password);
    } catch (e) {
      // Se eliminó la validación que atrapaba el error de correo duplicado
      print("Error registrando usuario: $e");
      return false;
    }
  }

  // =========================================================
  // 👦 LOGIN POR NOMBRE (ALUMNOS)
  // =========================================================
  static Future<bool> loginPorNombre(String nombre, String pin) async {
    try {
      final connection = await DbCore.conectar();
      final result = await connection.execute(
        Sql.named('''
          SELECT
            id,
            grade,
            name,
            password,
            avatar,
            role
          FROM users
          WHERE LOWER(name) = LOWER(@nombre)
        '''),
        parameters: {
          'nombre': nombre,
        },
      );

      await connection.close();

      if (result.isNotEmpty) {
        final String pinHasheadoIntento = DbCore.hp(pin);

        for (final row in result) {
          final dbPassword = row[3].toString();

          if (dbPassword == pinHasheadoIntento) {
            final int userId = row[0] as int;
            final int grado = row[1] != null ? row[1] as int : 1;
            final String userName = row[2].toString();
            final String userAvatar = row[4] != null ? row[4].toString() : 'assets/avatars/avatar1.png';
            
            // Aquí respetamos el rol que traiga (normalmente 'student')
            final String userRole = row[5] != null ? row[5].toString() : 'student';

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('sesion_iniciada', true);
            await prefs.setInt('id_usuario', userId);
            await prefs.setInt('grado_usuario', grado);
            await prefs.setString('userName', userName);
            await prefs.setString('userAvatar', userAvatar);
            await prefs.setString('userRole', userRole);

            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error en loginPorNombre: $e');
      return false;
    }
  }

  // =========================================================
  // 👨‍🏫 LOGIN POR CORREO
  // =========================================================
  static Future<bool> loginPorCorreo(String email, String password) async {
    try {
      final connection = await DbCore.conectar();
      final result = await connection.execute(
        Sql.named('''
          SELECT
            id,
            grade,
            name,
            password,
            avatar,
            role
          FROM users
          WHERE LOWER(email) = LOWER(@email)
        '''),
        parameters: {
          'email': email,
        },
      );

      await connection.close();

      if (result.isNotEmpty) {
        final String passHasheadoIntento = DbCore.hp(password);

        for (final row in result) {
          final dbPassword = row[3].toString();

          if (dbPassword == passHasheadoIntento) {
            final int userId = row[0] as int;
            final int grado = row[1] != null ? row[1] as int : 1;
            final String userName = row[2].toString();
            final String userAvatar = row[4] != null ? row[4].toString() : 'assets/avatars/avatar1.png';
            
            // 🚀 MODIFICACIÓN CLAVE:
            String dbRole = row[5] != null ? row[5].toString() : 'student';
            if (dbRole == 'student') {
              dbRole = 'parent';
            }

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('sesion_iniciada', true);
            await prefs.setInt('id_usuario', userId);
            await prefs.setInt('grado_usuario', grado);
            await prefs.setString('userName', userName);
            await prefs.setString('userAvatar', userAvatar);
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

  // =========================================================
  // 🚪 CERRAR SESIÓN
  // =========================================================
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // =========================================================
  // 📧 OBTENER CORREO
  // =========================================================
  static Future<String?> obtenerCorreoDeUsuario(String identificador) async {
    try {
      final connection = await DbCore.conectar();
      bool esCorreo = identificador.contains('@');

      String query = esCorreo
          ? """
            SELECT email
            FROM users
            WHERE LOWER(email) = LOWER(@id)
            AND role != 'student'
            LIMIT 1
          """
          : """
            SELECT email
            FROM users
            WHERE LOWER(name) = LOWER(@id)
            LIMIT 1
          """;

      final result = await connection.execute(
        Sql.named(query),
        parameters: {
          'id': identificador,
        },
      );

      await connection.close();

      if (result.isNotEmpty) {
        return result.first[0].toString();
      }
      return null;
    } catch (e) {
      print("Error obteniendo correo: $e");
      return null;
    }
  }

  // =========================================================
  // 🔐 ACTUALIZAR PASSWORD
  // =========================================================
  static Future<bool> actualizarPassword(String identificador, String nuevaPassword) async {
    try {
      final connection = await DbCore.conectar();
      final passHasheado = DbCore.hp(nuevaPassword);
      bool esCorreo = identificador.contains('@');

      String query = esCorreo
          ? """
            UPDATE users
            SET password = @pass
            WHERE LOWER(email) = LOWER(@id)
            AND role != 'student'
          """
          : """
            UPDATE users
            SET password = @pass
            WHERE LOWER(name) = LOWER(@id)
          """;

      await connection.execute(
        Sql.named(query),
        parameters: {
          'pass': passHasheado,
          'id': identificador,
        },
      );

      await connection.close();
      return true;
    } catch (e) {
      print("Error actualizando password: $e");
      return false;
    }
  }
}