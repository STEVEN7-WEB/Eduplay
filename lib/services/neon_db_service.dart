import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NeonDbService {
  
  // --- ATAJO DE CONEXIÓN ---
  // Hacemos esto para no tener que pegar tu contraseña en cada función
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

  // 1. FUNCIÓN DE LOGIN (Ya la teníamos, pero ahora guarda el ID del usuario)
  static Future<bool> loginDirecto(String email, String password) async {
    try {
      final connection = await _conectar();
      final result = await connection.execute(
        Sql.named('SELECT id FROM users WHERE email = @email AND password = @password'),
        parameters: {'email': email, 'password': password},
      );
      await connection.close();

      if (result.isNotEmpty) {
        // Obtenemos el ID del niño (es la primera columna de la primera fila)
        final int childId = result[0][0] as int; 

        // Guardamos que ya inició sesión y también su ID para saber de quién son los puntos
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('sesion_iniciada', true);
        await prefs.setInt('id_usuario', childId); 
        
        return true; 
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  // 2. FUNCIÓN PARA SUBIR COSAS (Guardar progreso)
  static Future<bool> guardarPuntaje(String materia, int puntosObtenidos) async {
    try {
      // Sacamos el ID del niño de la memoria del celular
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('id_usuario');

      if (userId == null) return false; // Si no hay usuario, no guardamos nada

      final connection = await _conectar();
      
      // INSERTAMOS los datos en la base de datos
      await connection.execute(
        Sql.named('INSERT INTO scores (user_id, subject, points) VALUES (@userId, @materia, @puntos)'),
        parameters: {
          'userId': userId,
          'materia': materia,
          'puntos': puntosObtenidos,
        },
      );
      
      await connection.close();
      print("¡Puntaje guardado en la nube!");
      return true;
    } catch (e) {
      print('Error al guardar puntaje: $e');
      return false;
    }
  }

  // 3. FUNCIÓN PARA EXTRAER COSAS (Obtener el historial de juegos)
  static Future<List<Map<String, dynamic>>> obtenerPuntajes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('id_usuario');

      if (userId == null) return [];

      final connection = await _conectar();
      
      // EXTRAEMOS los últimos 10 juegos de este niño
      final result = await connection.execute(
        Sql.named('SELECT subject, points FROM scores WHERE user_id = @userId ORDER BY last_played DESC LIMIT 10'),
        parameters: {'userId': userId},
      );
      
      await connection.close();

      // Convertimos el resultado a una lista que Flutter pueda mostrar fácil en pantalla
      List<Map<String, dynamic>> historial = [];
      for (final fila in result) {
        final mapa = fila.toColumnMap();
        historial.add({
          'materia': mapa['subject'],
          'puntos': mapa['points'],
        });
      }
      
      return historial; // Devolvemos la lista de juegos
    } catch (e) {
      print('Error al obtener puntajes: $e');
      return [];
    }
  }
}