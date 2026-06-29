import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/pedido.dart';
import '../models/recordatorio.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

if (defaultTargetPlatform == TargetPlatform.android) {
  final androidPlugin = _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  final tienePermiso = await androidPlugin?.areNotificationsEnabled();
  print('🔔 ¿Tiene permiso de notificaciones? $tienePermiso');

  if (tienePermiso == false) {
    final resultado = await androidPlugin?.requestNotificationsPermission();
    print('🔔 Resultado solicitud permiso: $resultado');
  }
}
  }

  // ─── Detalles reutilizables ───────────────────────────────────────────────
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'entregas_channel',
        'Recordatorios de Entrega',
        channelDescription: 'Notificaciones de pedidos próximos a entregar',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        ticker: 'Entrega pendiente',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ─── Programa notificaciones automáticas desde un Pedido ─────────────────
  Future<void> scheduleNotificacionPedido({
    required String pedidoId,
    required String titulo,
    required DateTime fechaEntrega,
  }) async {
    final now = DateTime.now();

    // 🔔 1 día antes a las 9:00 AM
    final unDiaAntes = DateTime(
      fechaEntrega.year,
      fechaEntrega.month,
      fechaEntrega.day,
      9, 0,
    ).subtract(const Duration(days: 1));

    if (unDiaAntes.isAfter(now)) {
      await _plugin.zonedSchedule(
        '${pedidoId}_1d'.hashCode,
        '⏰ Entrega mañana',
        titulo,
        tz.TZDateTime.from(unDiaAntes, tz.local),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 🔔 3 horas antes de la hora de entrega
    final tresHorasAntes = fechaEntrega.subtract(const Duration(hours: 3));

    if (tresHorasAntes.isAfter(now)) {
      await _plugin.zonedSchedule(
        '${pedidoId}_3h'.hashCode,
        '🚨 Entrega en 3 horas',
        titulo,
        tz.TZDateTime.from(tresHorasAntes, tz.local),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // ─── Reprograma todos los pedidos activos al iniciar la app ──────────────
  Future<void> reprogramarDesdePedidos(List<Pedido> pedidos) async {
    await cancelAll();
    for (final pedido in pedidos) {
      if (pedido.estado != 'Entregado' && pedido.fechaEntrega != null) {
        await scheduleNotificacionPedido(
          pedidoId: pedido.id,
          titulo: pedido.titulo ?? 'Pedido sin título',
          fechaEntrega: pedido.fechaEntrega!,
        );
      }
    }
  }

  // ─── Para recordatorios manuales ─────────────────────────────────────────
  Future<void> scheduleReminderNotification(Recordatorio recordatorio) async {
    await scheduleNotificacionPedido(
      pedidoId: recordatorio.id,
      titulo: recordatorio.titulo,
      fechaEntrega: recordatorio.fechaRecordatorio,
    );
  }

  // ─── Cancela las notificaciones de un pedido ─────────────────────────────
  Future<void> cancelNotification(String id) async {
    await _plugin.cancel('${id}_1d'.hashCode);
    await _plugin.cancel('${id}_3h'.hashCode);
  }

  // ─── Cancela todo ─────────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Prueba: notificación en 10 segundos ─────────────────────────────────
Future<void> mostrarNotificacionEn10Segundos() async {
  final scheduledDate =
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

  await _plugin.zonedSchedule(
    999,
    'Prueba programada',
    'Esta notificación se programó para 10 segundos después',
    scheduledDate,
    _notificationDetails(),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
}