import 'dart:math' as math;
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

  // --- ACTUALIZADO: Programación diaria con mensajes espaciales aleatorios ---
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

    // Banco de frases interactivas y llamativas para motivar al estudiante
    final List<Map<String, String>> frasesMotivacionales = [
      {
        'titulo': "¡Alerta en la cabina! 🛸",
        'cuerpo': "Tus estrellas te extrañan en el espacio. ¡Entra a ganar más XP!"
      },
      {
        'titulo': "¡Misión diaria disponible! 🚀",
        'cuerpo': "El planeta de las Matemáticas necesita tu ayuda. ¡Vamos a jugar!"
      },
      {
        'titulo': "¡Llamado al Comandante! 👨‍🚀",
        'cuerpo': "Hay trofeos nuevos esperando en la Sala de Trofeos. ¿Podrás desbloquearlos hoy?"
      },
      {
        'titulo': "¡Radar cósmico activo! 🛰️",
        'cuerpo': "Se detectaron nuevos desafíos de Lógica esperando tu estrategia estelar."
      }
    ];

    // Selección aleatoria del mensaje para evitar la monotonía diaria
    final random = math.Random();
    final fraseElegida = frasesMotivacionales[random.nextInt(frasesMotivacionales.length)];

    await _notificationsPlugin.periodicallyShow(
      id: 1, 
      title: fraseElegida['titulo'],
      body: fraseElegida['cuerpo'],
      repeatInterval: RepeatInterval.daily, // Cambiado de hourly a daily para una retención sana
      notificationDetails: detalles,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // --- Método para cancelar las notificaciones ---
  static Future<void> cancelarTodasLasNotificaciones() async {
    await _notificationsPlugin.cancelAll();
  }
}