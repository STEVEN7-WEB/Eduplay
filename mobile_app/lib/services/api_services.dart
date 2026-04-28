import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚠️ Esta es tu IP real para probar en el celular físico
  static const String baseUrl = 'http://192.168.1.6:5000/api';

  // --- 1. OBTENER LISTA DE ALUMNOS ---
  static Future<List<dynamic>> obtenerAlumnos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/lista'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      }
      return [];
    } catch (e) {
      print('❌ Error conectando con Flask: $e');
      return [];
    }
  }

  // --- 2. INICIAR SESIÓN CON PIN ---
  static Future<Map<String, dynamic>> loginConPin(int userId, String pin, String userName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/$userId/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_token', data['session_token']);
        await prefs.setString('userId', userId.toString());
        await prefs.setString('userName', userName);
        
        print('✅ Sesión iniciada para: $userName');
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'PIN incorrecto'};
      }
    } catch (e) {
      print('❌ Error en el Login: $e');
      return {'success': false, 'error': 'Error de conexión con el servidor'};
    }
  }

  // --- 3. LOGIN POR EMAIL ---
  static Future<bool> loginPorEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_token', data['session_token']);
        await prefs.setString('userId', data['usuario']['id'].toString());
        await prefs.setString('userName', data['usuario']['nombre']);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error en login por email: $e');
      return false;
    }
  }

  // --- 4. REGISTRAR NUEVO USUARIO ---
  static Future<bool> registrarUsuario(String nombre, String email, String password, int grado) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
          'grado_escolar': grado
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_token', data['session_token']);
        await prefs.setString('userId', data['id'].toString());
        await prefs.setString('userName', data['nombre']);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error en registro: $e');
      return false;
    }
  }

  // --- 5. CERRAR SESIÓN ---
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('userId');
    await prefs.remove('userName');
  }
}