import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_service.dart';
import '../../core/services/local_notification_service.dart';
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
            callback: (payload) async {
              try {
                final newNotif =
                    NotificationModel.fromJson(payload.newRecord);

                // Jangan tampilkan notifikasi untuk tiket yang sudah terhapus.
                if (newNotif.ticketId != null &&
                    !await _ticketExists(newNotif.ticketId!)) {
                  return;
                }

                notifications.insert(0, newNotif);
                unreadCount.value =
                    notifications.where((n) => !n.isRead).length;

                // Tampilkan local notification di system tray
                LocalNotificationService.show(
                  title: newNotif.title,
                  body: newNotif.body,
                  payload: newNotif.ticketId,
                );
              } catch (_) {
                fetchNotifications();
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'tickets',
            callback: (payload) {
              final deletedTicketId = payload.oldRecord['id']?.toString();
              if (deletedTicketId == null) return;
              _removeNotificationsForTicket(deletedTicketId);
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

      final fetched =
          (data as List).map((e) => NotificationModel.fromJson(e)).toList();
      notifications.assignAll(await _filterExistingTicketNotifications(fetched));
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

  void _removeNotificationsForTicket(String ticketId) {
    notifications.removeWhere((n) => n.ticketId == ticketId);
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  Future<bool> ticketExists(String ticketId) => _ticketExists(ticketId);

  Future<bool> _ticketExists(String ticketId) async {
    try {
      final rows = await _db
          .from('tickets')
          .select('id')
          .eq('id', ticketId)
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (_) {
      // Jika gagal validasi, jangan blok notifikasi agar tidak kehilangan info penting.
      return true;
    }
  }

  Future<List<NotificationModel>> _filterExistingTicketNotifications(
    List<NotificationModel> items,
  ) async {
    final ticketIds = items
        .map((n) => n.ticketId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (ticketIds.isEmpty) return items;

    try {
      final rows = await _db
          .from('tickets')
          .select('id')
          .inFilter('id', ticketIds.toList());
      final existingIds = (rows as List)
          .map((row) => row['id']?.toString())
          .whereType<String>()
          .toSet();

      return items
          .where((n) => n.ticketId == null || existingIds.contains(n.ticketId))
          .toList();
    } catch (_) {
      return items;
    }
  }
}
