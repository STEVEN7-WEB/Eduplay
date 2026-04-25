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

  // AHORA PIDE EL GRADO PARA REGISTRAR
  static Future<bool> registrarUsuario(String nombre, String email, String password, int grado) async {
    try {
      final connection = await _conectar();
      await connection.execute(
        Sql.named('INSERT INTO users (name, email, password, grade) VALUES (@nombre, @email, @password, @grado)'),
        parameters: {'nombre': nombre, 'email': email, 'password': password, 'grado': grado},
      );
      await connection.close();
      return await loginDirecto(email, password);
    } catch (e) {
      print('Error al registrar: $e');
      return false;
    }
  }

  // AHORA LEE EL GRADO AL INICIAR SESIÓN
  static Future<bool> loginDirecto(String email, String password) async {
    try {
      final connection = await _conectar();
      final result = await connection.execute(
        // Extraemos ID y Grade
        Sql.named('SELECT id, grade FROM users WHERE email = @email AND password = @password'),
        parameters: {'email': email, 'password': password},
      );
      await connection.close();

      if (result.isNotEmpty) {
        final int userId = result[0][0] as int;
        // Si la columna grade es nula por alguna razón, ponemos grado 1 por defecto
        final int grado = result[0][1] != null ? result[0][1] as int : 1; 

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('sesion_iniciada', true);
        await prefs.setInt('id_usuario', userId);
        await prefs.setInt('grado_usuario', grado); // Guardamos el grado en el celular
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  static Future<bool> guardarPuntaje(String materia, int puntosObtenidos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('id_usuario');
      if (userId == null) return false;

      final connection = await _conectar();
      await connection.execute(
        Sql.named('INSERT INTO scores (user_id, subject, points) VALUES (@userId, @materia, @puntos)'),
        parameters: {'userId': userId, 'materia': materia, 'puntos': puntosObtenidos},
      );
      await connection.close();
      return true;
    } catch (e) {
      print('Error al guardar: $e');
      return false;
    }
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}