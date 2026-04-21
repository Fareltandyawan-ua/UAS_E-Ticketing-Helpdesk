import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_service.dart';
import 'notification_model.dart';

class NotificationController extends GetxController {
  final _db = SupabaseService.client;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;

  // Realtime
  RealtimeChannel? _channel;
  // Polling timer — backup jika Realtime tidak terpasang
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    _subscribeRealtime();
    _startPolling();
  }

  @override
  void onClose() {
    _stopPolling();
    _unsubscribeRealtime();
    super.onClose();
  }

  // ── Polling setiap 20 detik ──────────────────────────────────────────────
  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => fetchNotifications(),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ── Realtime (bonus jika diaktifkan di Supabase) ─────────────────────────
  void _unsubscribeRealtime() {
    if (_channel != null) {
      try {
        _db.removeChannel(_channel!);
      } catch (_) {}
      _channel = null;
    }
  }

  void _subscribeRealtime() {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _channel = _db
          .channel('notifications-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              try {
                final newNotif =
                    NotificationModel.fromJson(payload.newRecord);
                notifications.insert(0, newNotif);
                unreadCount.value =
                    notifications.where((n) => !n.isRead).length;
              } catch (_) {
                fetchNotifications();
              }
            },
          )
          .subscribe();
    } catch (_) {
      // Realtime gagal connect — polling sudah menangani
    }
  }

  // ── Fetch ────────────────────────────────────────────────────────────────
  Future<void> fetchNotifications() async {
    // Jangan tampilkan loading spinner saat background polling
    final showLoading = notifications.isEmpty;
    if (showLoading) isLoading.value = true;

    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _db
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      notifications.assignAll(
        (data as List).map((e) => NotificationModel.fromJson(e)).toList(),
      );
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    } catch (_) {}

    if (showLoading) isLoading.value = false;
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
