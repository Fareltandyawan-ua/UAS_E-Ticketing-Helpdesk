import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_service.dart';
import '../data/ticket_api.dart';
import '../data/ticket_model.dart';
import '../../auth/data/auth_model.dart';

class TicketController extends GetxController {
  final TicketApi _api = TicketApi();
  final _db = SupabaseService.client;

  // List state
  final RxList<TicketModel> tickets = <TicketModel>[].obs;
  final RxBool isLoadingList = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString filterStatus = ''.obs;
  final RxString filterPriority = ''.obs;
  final RxString searchQuery = ''.obs;
  int _page = 1;
  bool _hasMore = true;

  // Detail state
  final Rx<TicketModel?> selectedTicket = Rx<TicketModel?>(null);
  final RxBool isLoadingDetail = false.obs;
  final RxList<TicketTrackingModel> trackingList = <TicketTrackingModel>[].obs;

  // Assign tiket
  final RxList<UserModel> helpdeskUsers = <UserModel>[].obs;
  final RxBool isLoadingHelpdeskUsers = false.obs;
  final RxBool isAssigning = false.obs;
  final RxBool isUpdatingStatus = false.obs;
  final RxBool isDeleting = false.obs;

  // History
  final RxList<TicketModel> historyList = <TicketModel>[].obs;
  final RxBool isLoadingHistory = false.obs;

  // Realtime channel
  RealtimeChannel? _ticketChannel;

  @override
  void onInit() {
    super.onInit();
    fetchTickets();
    _subscribeRealtime();
    debounce(
      searchQuery,
      (_) => refreshTickets(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    if (_ticketChannel != null) {
      _db.removeChannel(_ticketChannel!);
      _ticketChannel = null;
    }
    super.onClose();
  }

  /// Subscribe Realtime pada tabel tickets
  /// INSERT → tambahkan ke list, UPDATE → update item di list, DELETE → hapus dari list
  void _subscribeRealtime() {
    _ticketChannel = _db
        .channel('ticket-list-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tickets',
          callback: (payload) {
            // Saat ada tiket baru, refresh seluruh list agar relasi terbawa
            refreshTickets();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tickets',
          callback: (payload) {
            final updatedId = payload.newRecord['id']?.toString();
            if (updatedId == null) return;

            // Update selectedTicket jika sedang dibuka.
            // Preserve komentar yang sudah tampil agar tidak flicker/hilang sesaat.
            if (selectedTicket.value?.id == updatedId) {
              loadTicketDetail(updatedId, preserveComments: true);
            }

            // Update item di ticket list secara lokal (status, assigned_to)
            final idx = tickets.indexWhere((t) => t.id == updatedId);
            if (idx >= 0) {
              // Refresh untuk mendapatkan data terbaru dengan relasi
              refreshTickets();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'tickets',
          callback: (payload) {
            final deletedId = payload.oldRecord['id']?.toString();
            if (deletedId == null) return;

            // Pastikan tiket yang dihapus ikut hilang dari semua list aktif.
            tickets.removeWhere((t) => t.id == deletedId);
            historyList.removeWhere((t) => t.id == deletedId);

            if (selectedTicket.value?.id == deletedId) {
              selectedTicket.value = null;
              trackingList.clear();
            }
          },
        )
        .subscribe();
  }

  // ── Fetch tickets ──────────────────────────────────────────────────────────
  Future<void> fetchTickets({
    bool loadMore = false,
    String? filterByUserId,
  }) async {
    if (loadMore) {
      if (!_hasMore || isLoadingMore.value) return;
      isLoadingMore.value = true;
      _page++;
    } else {
      isLoadingList.value = true;
      _page = 1;
      _hasMore = true;
    }

    try {
      final result = await _api.getTickets(
        status: filterStatus.value.isEmpty ? null : filterStatus.value,
        priority:
            filterPriority.value.isEmpty ? null : filterPriority.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        page: _page,
        createdBy: filterByUserId,
      );
      loadMore ? tickets.addAll(result) : tickets.assignAll(result);
      if (result.length < 20) _hasMore = false;
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoadingList.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshTickets({String? filterByUserId}) async {
    _page = 1;
    _hasMore = true;
    await fetchTickets(filterByUserId: filterByUserId);
  }

  // ── Detail ─────────────────────────────────────────────────────────────────
  Future<void> loadTicketDetail(String id, {bool preserveComments = false}) async {
    isLoadingDetail.value = true;
    try {
      final previousComments = preserveComments && selectedTicket.value?.id == id
          ? selectedTicket.value!.comments
          : const <CommentModel>[];
      final detail = await _api.getTicketDetail(id);

      if (previousComments.isNotEmpty && detail.comments.length < previousComments.length) {
        selectedTicket.value = TicketModel(
          id: detail.id,
          title: detail.title,
          description: detail.description,
          status: detail.status,
          priority: detail.priority,
          category: detail.category,
          createdBy: detail.createdBy,
          assignedTo: detail.assignedTo,
          attachments: detail.attachments,
          comments: previousComments,
          createdAt: detail.createdAt,
          updatedAt: detail.updatedAt,
        );
      } else {
        selectedTicket.value = detail;
      }

      trackingList.assignAll(await _api.getTracking(id));
    } catch (e) {
      // Jika tiket sudah dihapus di perangkat/user lain, bersihkan state lokal.
      tickets.removeWhere((t) => t.id == id);
      if (selectedTicket.value?.id == id) {
        selectedTicket.value = null;
        trackingList.clear();
      }
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ── Create ticket ──────────────────────────────────────────────────────────
  Future<void> createTicketDirect({
    required String title,
    required String desc,
    required String priority,
    required String category,
    List<XFile>? attachments,
  }) async {
    try {
      await _api.createTicket(
        title: title,
        description: desc,
        priority: priority,
        category: category,
        attachments: attachments,
      );
      Get.back();
      await refreshTickets();
      Get.snackbar('Berhasil', 'Tiket berhasil dibuat',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // ── Update status ──────────────────────────────────────────────────────────
  Future<void> updateStatus(String ticketId, String newStatus) async {
    isUpdatingStatus.value = true;
    try {
      final updated = await _api.updateTicketStatus(ticketId, newStatus);

      // Response update status biasanya tidak membawa komentar lengkap.
      // Jadi komentar yang sedang tampil harus dipertahankan agar tidak hilang sesaat.
      if (selectedTicket.value?.id == ticketId) {
        final current = selectedTicket.value!;
        selectedTicket.value = TicketModel(
          id: updated.id,
          title: updated.title,
          description: updated.description,
          status: updated.status,
          priority: updated.priority,
          category: updated.category,
          createdBy: updated.createdBy,
          assignedTo: updated.assignedTo,
          attachments: updated.attachments,
          comments: current.comments,
          createdAt: updated.createdAt,
          updatedAt: updated.updatedAt,
        );
      } else {
        selectedTicket.value = updated;
      }

      final idx = tickets.indexWhere((t) => t.id == ticketId);
      if (idx >= 0) tickets[idx] = updated;
      trackingList.assignAll(await _api.getTracking(ticketId));
      Get.snackbar('Berhasil', 'Status tiket diperbarui',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  // ── Assign tiket ────────────────────────────────────────────────────────────
  Future<void> loadHelpdeskUsers() async {
    if (helpdeskUsers.isNotEmpty) return;
    isLoadingHelpdeskUsers.value = true;
    try {
      helpdeskUsers.assignAll(await _api.getHelpdeskUsers());
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingHelpdeskUsers.value = false;
    }
  }

  Future<void> assignTicket(String ticketId, String assigneeId) async {
    isAssigning.value = true;
    try {
      final updated = await _api.assignTicket(ticketId, assigneeId);
      selectedTicket.value = updated;
      final idx = tickets.indexWhere((t) => t.id == ticketId);
      if (idx >= 0) tickets[idx] = updated;
      Get.snackbar('Berhasil', 'Tiket berhasil di-assign',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isAssigning.value = false;
    }
  }

  // ── Delete ticket ──────────────────────────────────────────────────────────
  /// Hapus tiket dan refresh list. Tutup detail screen jika sedang dibuka.
  Future<bool> deleteTicket(String ticketId) async {
    isDeleting.value = true;
    try {
      await _api.deleteTicket(ticketId);
      tickets.removeWhere((t) => t.id == ticketId);
      if (selectedTicket.value?.id == ticketId) {
        selectedTicket.value = null;
      }
      Get.snackbar('Berhasil', 'Tiket berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  // ── History ────────────────────────────────────────────────────────────────
  Future<void> fetchHistory({String? userId}) async {
    isLoadingHistory.value = true;
    try {
      historyList.assignAll(await _api.getHistory(userId: userId));
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingHistory.value = false;
    }
  }

  // ── Filter ─────────────────────────────────────────────────────────────────
  void setFilter({String? status, String? priority}) {
    if (status != null) filterStatus.value = status;
    if (priority != null) filterPriority.value = priority;
    refreshTickets();
  }

  void clearFilters() {
    filterStatus.value = '';
    filterPriority.value = '';
    searchQuery.value = '';
    refreshTickets();
  }
}
