import 'package:flutter/foundation.dart';
import '../network/supabase_service.dart';

/// Jenis aktivitas user yang dilacak (BR-005).
///
/// Disimpan sebagai string biasa di kolom `activity_type` agar mudah
/// diperluas tanpa migrasi enum di database.
class ActivityType {
  ActivityType._();

  // Auth
  static const String login = 'login';
  static const String logout = 'logout';
  static const String register = 'register';
  static const String passwordChanged = 'password_changed';
  static const String profileUpdated = 'profile_updated';

  // Ticket
  static const String ticketCreated = 'ticket_created';
  static const String ticketStatusChanged = 'ticket_status_changed';
  static const String ticketAssigned = 'ticket_assigned';
  static const String ticketDeleted = 'ticket_deleted';
  static const String commentAdded = 'comment_added';

  // Admin
  static const String userRoleChanged = 'user_role_changed';
  static const String userActivated = 'user_activated';
  static const String userDeactivated = 'user_deactivated';
}

/// Service untuk mencatat aktivitas pengguna ke tabel `user_activities`.
///
/// Semua method **fire-and-forget**: tidak boleh memblokir flow utama
/// walau pencatatan gagal. Error di-swallow + log ke console (debug mode).
class ActivityLogger {
  ActivityLogger._();

  static final _db = SupabaseService.client;

  /// Catat aktivitas user.
  ///
  /// - [type] gunakan konstanta dari [ActivityType].
  /// - [description] kalimat human-readable yang akan muncul di log/UI.
  /// - [ticketId] opsional, untuk event yang related ke tiket.
  /// - [metadata] opsional, JSON tambahan (mis. {"old": "open", "new": "closed"}).
  /// - [userId] default ke user yang sedang login. Eksplisit set kalau
  ///   logging action yang dilakukan TERHADAP user lain (mis. admin
  ///   menonaktifkan user).
  static Future<void> log({
    required String type,
    required String description,
    String? ticketId,
    Map<String, dynamic>? metadata,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _db.auth.currentUser?.id;
      if (uid == null) return;

      await _db.from('user_activities').insert({
        'user_id': uid,
        'activity_type': type,
        'description': description,
        if (ticketId != null) 'ticket_id': ticketId,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      // Jangan throw — logging tidak boleh memblokir flow utama.
      if (kDebugMode) {
        debugPrint('ActivityLogger.log failed: $e');
      }
    }
  }
}
