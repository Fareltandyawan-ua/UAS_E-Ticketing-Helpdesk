import 'package:get/get.dart';
import 'package:realtime_client/realtime_client.dart'
    show PostgresChangeEvent;
import '../../core/network/supabase_service.dart';
import 'notification_model.dart';

class NotificationController extends GetxController {
  final _db = SupabaseService.client;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;

  // Stream subscription untuk Supabase Realtime
  dynamic _realtimeChannel;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    _subscribeRealtime();
  }

  @override
  void onClose() {
    // Unsubscribe realtime channel saat controller di-dispose
    if (_realtimeChannel != null) {
      try {
        _db.removeChannel(_realtimeChannel);
      } catch (_) {}
    }
    super.onClose();
  }

  /// Subscribe ke Supabase Realtime agar notifikasi update otomatis
  void _subscribeRealtime() {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      _realtimeChannel = _db
          .channel('public:notifications:user_id=eq.$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              // Tambahkan notifikasi baru ke list tanpa re-fetch semua
              try {
                final newNotif =
                    NotificationModel.fromJson(payload.newRecord);
                // Hanya tambahkan jika milik user ini
                if (payload.newRecord['user_id'] == userId) {
                  notifications.insert(0, newNotif);
                  unreadCount.value =
                      notifications.where((n) => !n.isRead).length;
                }
              } catch (_) {
                fetchNotifications(); // fallback jika parsing gagal
              }
            },
          )
          .subscribe();
    } catch (_) {
      // Realtime tidak tersedia — fallback ke manual fetch
    }
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _db
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      notifications.assignAll(
        (data as List).map((e) => NotificationModel.fromJson(e)).toList(),
      );
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    } catch (_) {
      // Gagal fetch notifikasi tidak perlu crash app
    }
    isLoading.value = false;
  }

  Future<void> markRead(String id) async {
    try {
      await _db.from('notifications').update({'is_read': true}).eq('id', id);
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        final old = notifications[idx];
        notifications[idx] = NotificationModel(
          id: old.id,
          title: old.title,
          body: old.body,
          ticketId: old.ticketId,
          isRead: true,
          createdAt: old.createdAt,
        );
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      await fetchNotifications();
    } catch (_) {}
  }
}
