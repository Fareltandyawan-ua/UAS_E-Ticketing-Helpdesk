import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

/// Service untuk menampilkan local notification di system tray.
///
/// Dipakai oleh:
/// - NotificationController: saat menerima notifikasi baru via Supabase Realtime
/// - FCMService (fase berikutnya): saat menerima FCM message di foreground
class LocalNotificationService {
  LocalNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'helpdesk_notifications';
  static const _channelName = 'Notifikasi Tiket';
  static const _channelDesc =
      'Notifikasi terkait aktivitas tiket helpdesk Anda';

  /// Init plugin + buat Android channel. Idempoten.
  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleTap,
    );

    // Buat channel khusus Android 8+
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    // Minta izin notifikasi (Android 13+ & iOS)
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Tampilkan notifikasi. [payload] biasanya ticketId untuk navigasi.
  static Future<void> show({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    await _plugin.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handler tap notifikasi — navigasi ke detail tiket kalau payload berisi
  /// ticketId, atau ke halaman notifikasi sebagai fallback.
  static void _handleTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _safeNavigate(AppRoutes.notifications);
      return;
    }
    _safeNavigate(AppRoutes.ticketDetail, arguments: payload);
  }

  static void _safeNavigate(String route, {dynamic arguments}) {
    try {
      Get.toNamed(route, arguments: arguments);
    } catch (e) {
      if (kDebugMode) debugPrint('Gagal navigate dari notif: $e');
    }
  }
}
