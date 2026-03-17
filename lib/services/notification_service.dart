import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    // --- CAMBIO CRÍTICO AQUÍ ---
    // Cambiamos a '@mipmap/launcher_icon'.
    // Si este falla, Android intentará usar el defecto del sistema.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("🔔 Notificación tocada: ${details.payload}");
      },
    );

    // Solicitar permiso (Android 13+)
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // PRUEBA INMEDIATA
  static Future<void> mostrarNotificacionAhora() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'gastos_channel_v3', // <--- CAMBIAMOS A V3 (Canal Nuevo)
            'Mis Gastos (V3)',
            channelDescription: 'Canal de pruebas definitivo',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            // icon: '@mipmap/launcher_icon', // Forzamos el icono aquí también
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        888,
        '¡Funciona! 🚀',
        'Si ves esto, el icono era el problema.',
        details,
      );
      debugPrint("✅ Comando .show() enviado con éxito");
    } catch (e) {
      debugPrint("❌ ERROR FATAL AL MOSTRAR: $e");
    }
  }

  // DIARIAS
  static Future<void> scheduleDailyNotifications() async {
    // (Mantenemos esto vacío por ahora para aislar el problema)
  }

  // 10 SEGUNDOS
  static Future<void> programarParaDentroDe10Segundos() async {
    // (Igual aquí, probemos primero el botón inmediato)
  }
}
