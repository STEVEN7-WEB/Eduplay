import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    // LA SOLUCIÓN FINAL: El parámetro ahora se llama simplemente 'settings'
    await _notificationsPlugin.initialize(
      settings: initSettings,
    );
  }

  static Future<void> pedirPermisos() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    await androidImplementation?.requestNotificationsPermission();
  }

  static Future<void> mostrarNotificacionInstantanea({
    required int id, 
    required String titulo, 
    required String cuerpo
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'eduplay_canal_1', 
      'Misiones y Logros', 
      channelDescription: 'Notificaciones sobre el progreso del estudiante',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: Color(0xFF48CAE4),
    );

    const NotificationDetails detalles = NotificationDetails(android: androidDetails);
    
    // Parámetros nombrados correctos para la versión 20.0.0+
    await _notificationsPlugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: detalles,
    );
  }
}