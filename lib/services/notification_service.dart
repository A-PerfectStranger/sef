import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicializar servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Manejar tap en notificación
  void _onNotificationTapped(NotificationResponse response) {
    // Aquí puedes manejar la navegación cuando el usuario toca la notificación
    print('Notificación tocada: ${response.payload}');
  }

  /// Solicitar permisos de notificaciones
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return await Permission.notification.isGranted;
  }

  /// Verificar si los permisos están concedidos
  Future<bool> arePermissionsGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Programar notificación de medicamento
  Future<void> scheduleMedicationNotification({
    required int id,
    required String medicationName,
    required String dose,
    required int hour,
    required int minute,
  }) async {
    final hasPermission = await arePermissionsGranted();
    if (!hasPermission) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Recordatorios de Medicamentos',
      channelDescription: 'Notificaciones para recordar tomar medicamentos',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id,
      'Hora de tu medicamento',
      '$medicationName - $dose',
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancelar notificación específica
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Mostrar notificación inmediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final hasPermission = await arePermissionsGranted();
    if (!hasPermission) return;

    const androidDetails = AndroidNotificationDetails(
      'general',
      'Notificaciones Generales',
      channelDescription: 'Notificaciones generales de la aplicación',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Obtener notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Programar notificación de recordatorio de diario
  Future<void> scheduleDiaryReminder() async {
    final hasPermission = await arePermissionsGranted();
    if (!hasPermission) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 9, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'diary_reminders',
      'Recordatorio de Diario',
      channelDescription: 'Notificaciones para recordar completar el diario',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      999, // ID fijo para el recordatorio de diario
      '¿Cómo te sientes hoy?',
      'Tómate un momento para registrar tu estado de ánimo',
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Programar notificación de celebración de racha
  Future<void> showStreakCelebration(int streakDays) async {
    await showNotification(
      id: 998,
      title: '🎉 ¡Racha de $streakDays días!',
      body: '¡Increíble! Continúa así y alcanzarás nuevas cumbres',
    );
  }

  /// Programar notificación motivacional para racha rota
  Future<void> showStreakBrokenMotivation() async {
    await showNotification(
      id: 997,
      title: '💪 No te rindas',
      body: 'Cada día es una nueva oportunidad. ¡Vuelve a empezar!',
    );
  }
}
