import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/license_model.dart';

/// Service untuk menangani notifikasi (FCM + Local Notifications)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      // Request permission untuk iOS
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel untuk Android
      const androidChannel = AndroidNotificationChannel(
        'sim_reminder_channel',
        'Pengingat SIM',
        description: 'Notifikasi pengingat kadaluarsa SIM',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Setup FCM handlers
      _setupFCMHandlers();

      _initialized = true;
    } catch (e) {
      print('Error saat initialize notifications: $e');
    }
  }

  /// Setup FCM message handlers
  void _setupFCMHandlers() {
    // Handler untuk foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Menerima message di foreground: ${message.notification?.title}');

      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? 'Pengingat SIM',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Handler untuk background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notifikasi diklik: ${message.notification?.title}');
      // Navigate ke screen yang sesuai
    });
  }

  /// Handler ketika notifikasi diklik
  void _onNotificationTapped(NotificationResponse response) {
    print('Notifikasi diklik: ${response.payload}');
    // Navigate ke screen yang sesuai
  }

  /// Tampilkan local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sim_reminder_channel',
      'Pengingat SIM',
      channelDescription: 'Notifikasi pengingat kadaluarsa SIM',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule notifikasi untuk license yang akan kadaluarsa
  Future<void> scheduleLicenseReminder(LicenseModel license) async {
    try {
      final expirationDate = license.expirationDate;
      final now = DateTime.now();

      // Cancel notifikasi existing untuk license ini
      await cancelLicenseReminder(license.id);

      // Jika sudah kadaluarsa, tidak perlu schedule
      if (expirationDate.isBefore(now)) {
        return;
      }

      // Schedule notifikasi 7 hari sebelum kadaluarsa
      final sevenDaysBefore = expirationDate.subtract(const Duration(days: 7));

      if (sevenDaysBefore.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(license.id, 7),
          title: 'Pengingat SIM',
          body: 'SIM ${license.licenseType} atas nama ${license.ownerName} akan kadaluarsa dalam 7 hari',
          scheduledDate: sevenDaysBefore,
          payload: license.id,
        );
      }

      // Schedule notifikasi harian untuk 7 hari terakhir
      for (int i = 6; i >= 1; i--) {
        final reminderDate = expirationDate.subtract(Duration(days: i));

        if (reminderDate.isAfter(now)) {
          await _scheduleNotification(
            id: _getNotificationId(license.id, i),
            title: 'Pengingat SIM',
            body: 'SIM ${license.licenseType} atas nama ${license.ownerName} akan kadaluarsa dalam $i hari',
            scheduledDate: reminderDate,
            payload: license.id,
          );
        }
      }

      // Schedule notifikasi di hari kadaluarsa
      if (expirationDate.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(license.id, 0),
          title: 'SIM Kadaluarsa Hari Ini!',
          body: 'SIM ${license.licenseType} atas nama ${license.ownerName} kadaluarsa hari ini',
          scheduledDate: expirationDate,
          payload: license.id,
        );
      }
    } catch (e) {
      print('Error saat schedule license reminder: $e');
    }
  }

  /// Schedule single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      // Set waktu ke jam 9 pagi
      final scheduleTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        9, // Jam 9 pagi
        0,
      );

      final tzScheduleTime = tz.TZDateTime.from(scheduleTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'sim_reminder_channel',
        'Pengingat SIM',
        channelDescription: 'Notifikasi pengingat kadaluarsa SIM',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduleTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('Notifikasi dijadwalkan untuk $tzScheduleTime dengan ID $id');
    } catch (e) {
      print('Error saat schedule notification: $e');
    }
  }

  /// Cancel notifikasi untuk license tertentu
  Future<void> cancelLicenseReminder(String licenseId) async {
    try {
      // Cancel semua notifikasi (7 hari + hari H)
      for (int i = 0; i <= 7; i++) {
        await _localNotifications.cancel(_getNotificationId(licenseId, i));
      }
    } catch (e) {
      print('Error saat cancel license reminder: $e');
    }
  }

  /// Cancel semua notifikasi
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      print('Error saat cancel all notifications: $e');
    }
  }

  /// Generate notification ID unik dari license ID dan days before
  int _getNotificationId(String licenseId, int daysBefore) {
    // Combine license ID hash dengan days before untuk ID unik
    final hash = licenseId.hashCode.abs();
    return (hash % 100000) * 10 + daysBefore;
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      print('Error saat get FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
    } catch (e) {
      print('Error saat subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error saat unsubscribe from topic: $e');
    }
  }

  /// Check apakah notifikasi enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final result = await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
        return result ?? false;
      }
      return true; // iOS akan request permission saat initialize
    } catch (e) {
      print('Error saat check notification permission: $e');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error saat request notification permission: $e');
      return false;
    }
  }
}

/// Background message handler (harus top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}
