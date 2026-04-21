import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_model.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/network/supabase_service.dart';

class DashboardController extends GetxController {
  final DashboardApi _api = DashboardApi();
  final _db = SupabaseService.client;

  final Rx<DashboardStats> stats = DashboardStats.empty().obs;
  final RxBool isLoading = false.obs;

  RealtimeChannel? _ticketChannel;
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    fetchStats();
    _subscribeTicketChanges();
    _startPolling();
  }

  @override
  void onClose() {
    _stopPolling();
    if (_ticketChannel != null) {
      try {
        _db.removeChannel(_ticketChannel!);
      } catch (_) {}
      _ticketChannel = null;
    }
    super.onClose();
  }

  // ── Polling setiap 30 detik ──────────────────────────────────────────────
  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchStats(),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ── Realtime (bonus jika diaktifkan di Supabase) ─────────────────────────
  void _subscribeTicketChanges() {
    try {
      _ticketChannel = _db
          .channel('dashboard-tickets-changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'tickets',
            callback: (_) => fetchStats(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'tickets',
            callback: (_) => fetchStats(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'tickets',
            callback: (_) => fetchStats(),
          )
          .subscribe();
    } catch (_) {
      // Realtime gagal — polling sudah menangani
    }
  }

  Future<void> fetchStats() async {
    // Jangan tampilkan loading spinner saat polling background
    final showLoading = isLoading.value == false && stats.value.total == 0;
    if (showLoading) isLoading.value = true;

    try {
      final authCtrl = Get.find<AuthController>();
      final user = authCtrl.currentUser.value;
      final isUserRole = user?.isUser ?? true;

      stats.value = await _api.getStats(
        userId:     isUserRole ? user?.id : null,
        helpdeskId: isUserRole ? null : user?.id,
      );
    } catch (_) {}

    if (showLoading) isLoading.value = false;
  }
}
