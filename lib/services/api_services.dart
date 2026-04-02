import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Cambia esto por la URL de tu API de Laravel cuando la tengas lista
  // Si pruebas en el emulador de Android conectado a tu Laravel local, usa: 10.0.2.2
  static const String baseUrl = 'http://tu-dominio-laravel.com/api';

  // Función para iniciar sesión
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Laravel nos respondió que todo está bien
        final data = jsonDecode(response.body);
        
        // Laravel debería devolverte un token (Sanctum o JWT). Lo guardamos:
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        
        return true; // Login exitoso
      } else {
        // La contraseña o el correo están mal
        return false; 
      }
    } catch (e) {
      print('Error conectando con Laravel: $e');
      return false;
    }
  }
}