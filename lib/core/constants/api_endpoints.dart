import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String _baseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_baseUrlFromEnv.isNotEmpty) {
      return _normalizeBaseUrl(_baseUrlFromEnv);
    }

    // Default aman untuk pengembangan lokal.
    // Web: browser mengakses server host langsung.
    // Android emulator: localhost host machine via 10.0.2.2.
    return kIsWeb
        ? 'http://127.0.0.1:8000/api/v1'
        : 'http://10.0.2.2:8000/api/v1';
  }

  static String _normalizeBaseUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh-token';
  static const String profile = '/auth/profile';
  static const String updateProfile = '/auth/profile/update';

  // Tickets
  static const String tickets = '/tickets';
  static String ticketDetail(String id) => '/tickets/$id';
  static String ticketStatus(String id) => '/tickets/$id/status';
  static String ticketAssign(String id) => '/tickets/$id/assign';
  static String ticketComments(String id) => '/tickets/$id/comments';
  static String ticketAttachments(String id) => '/tickets/$id/attachments';

  // Dashboard
  static const String dashboardStats = '/dashboard/stats';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String registerFcmToken = '/notifications/register-token';

  // History & Tracking
  static const String ticketHistory = '/tickets/history';
  static String ticketTracking(String id) => '/tickets/$id/tracking';
}
