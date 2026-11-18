import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> yitteBackgroundNotificationHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Firebase native config not yet attached (google-services.json / GoogleService-Info.plist)
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _firebaseReady = false;
  String? _fcmToken;

  bool get isFirebaseReady => _firebaseReady;
  String? get fcmToken => _fcmToken;

  Future<void> initialize({
    void Function(String? deepLink)? onNotificationTap,
  }) async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _localPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          onNotificationTap?.call(details.payload);
        },
      );
    } catch (e) {
      debugPrint('Local notifications init skipped in test/headless mode: $e');
    }

    // Attempt Firebase initialization cleanly; never crash if google-services.json isn't provided yet
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(yitteBackgroundNotificationHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      _fcmToken = await messaging.getToken();
      _firebaseReady = true;

      FirebaseMessaging.onMessage.listen((msg) {
        final notif = msg.notification;
        if (notif != null) {
          showLocalNotification(
            title: notif.title ?? 'Boroom Yitté',
            body: notif.body ?? '',
            deepLink: msg.data['deep_link']?.toString(),
          );
        }
      });
    } catch (e) {
      _firebaseReady = false;
      debugPrint('Firebase Messaging waiting for google-services.json: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? deepLink,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'boroom_yitte_main',
        'Boroom Yitté Notifications',
        channelDescription:
            'Rappels Zikr, invitations de débats, quiz en direct et annonces.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: deepLink,
    );
  }

  /// Schedules the recurring Saturday 20:00 GMT Zikr community reminder.
  Future<void> scheduleSaturdayZikrReminder() async {
    if (kIsWeb || !_initialized) return;
    try {
      final nowUtc = tz.TZDateTime.now(tz.UTC);
      var nextSat = tz.TZDateTime(
        tz.UTC,
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
        20,
        0,
      );
      while (nextSat.weekday != DateTime.saturday || !nextSat.isAfter(nowUtc)) {
        nextSat = nextSat.add(const Duration(days: 1));
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'yitte_zikr_reminders',
          'Rappels Yitté Zikr',
          channelDescription: 'Rappel du rassemblement hebdomadaire Samedi 20h00 GMT',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _localPlugin.zonedSchedule(
        2000,
        'Rassemblement Yitté Zikr — Samedi 20h00 GMT',
        'Le cercle collectif de dhikr va bientôt commencer. Rejoignez le salon dans la sérénité.',
        nextSat,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'boroomyitte://zikr',
      );
    } catch (e) {
      debugPrint('Saturday Zikr schedule skipped in headless/test mode: $e');
    }
  }

  /// Schedules a daily Tasbih reminder for any customizable goal and duration.
  Future<void> scheduleDailyTasbihReminder({
    int hour = 7,
    int minute = 0,
    int targetCount = 10000,
    int durationDays = 30,
    String titleLabel = 'Ṣalātu ʿalā an-Nabī',
  }) async {
    if (kIsWeb || !_initialized) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'yitte_daily_tasbih',
          'Ouverture Tasbīḥ Quotidienne',
          channelDescription:
              'Rappel quotidien pour votre objectif personnel de dhikr et Tasbīḥ',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      final dailyQuota = (targetCount / durationDays.clamp(1, 3650)).ceil();
      await _localPlugin.zonedSchedule(
        2001,
        'Ouverture Tasbīḥ Quotidienne',
        'Votre objectif personnel : $targetCount $titleLabel sur $durationDays jour(s) (~$dailyQuota/j).',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'boroomyitte://zikr',
      );
    } catch (e) {
      debugPrint('Daily Tasbih schedule skipped in headless/test mode: $e');
    }
  }

  Future<void> cancelDailyTasbihReminder() async {
    if (kIsWeb) return;
    try {
      await _localPlugin.cancel(2001);
    } catch (_) {
      // ignore in headless/test mode
    }
  }
}
