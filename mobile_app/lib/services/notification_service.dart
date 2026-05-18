import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

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
    
    await _notificationsPlugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: detalles,
    );
  }

  // --- NUEVO: Método para programar notificaciones repetitivas ---
static Future<void> programarNotificacionPeriodica() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'eduplay_canal_periodico', 
      'Recordatorios de Estudio', 
      channelDescription: 'Recordatorios periódicos para entrar a la app',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: Color(0xFF48CAE4),
    );

    const NotificationDetails detalles = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.periodicallyShow(
      id: 1, 
      title: "¡Hora de aprender! 🚀",
      body: "Entra a EduPlay 2.0 y descubre nuevas misiones divertidas.",
      repeatInterval: RepeatInterval.hourly, 
      notificationDetails: detalles,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // --- NUEVO: Método para cancelar las notificaciones ---
  static Future<void> cancelarTodasLasNotificaciones() async {
    await _notificationsPlugin.cancelAll();
  }
}