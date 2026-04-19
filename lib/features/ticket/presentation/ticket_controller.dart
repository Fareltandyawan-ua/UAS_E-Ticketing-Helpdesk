import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/ticket_api.dart';
import '../data/ticket_model.dart';
import '../../auth/data/auth_model.dart';

class TicketController extends GetxController {
  final TicketApi _api = TicketApi();

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

  // Comment
  final commentController = TextEditingController();
  final RxBool isSubmittingComment = false.obs;
  final RxBool isUpdatingStatus = false.obs;

  // Assign tiket
  final RxList<UserModel> helpdeskUsers = <UserModel>[].obs;
  final RxBool isLoadingHelpdeskUsers = false.obs;
  final RxBool isAssigning = false.obs;

  // History
  final RxList<TicketModel> historyList = <TicketModel>[].obs;
  final RxBool isLoadingHistory = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTickets();
    debounce(
      searchQuery,
      (_) => refreshTickets(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  // ── Fetch tickets ──────────────────────────────────────────────────────────
  Future<void> fetchTickets({
    bool loadMore = false,
    String? filterByUserId, // pass userId jika role user biasa
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
        priority: filterPriority.value.isEmpty ? null : filterPriority.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        page: _page,
        createdBy: filterByUserId,
      );
      loadMore ? tickets.addAll(result) : tickets.assignAll(result);
      if (result.length < 20) _hasMore = false;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
  Future<void> loadTicketDetail(String id) async {
    isLoadingDetail.value = true;
    try {
      selectedTicket.value = await _api.getTicketDetail(id);
      trackingList.assignAll(await _api.getTracking(id));
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
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
    List<dynamic>? attachments, // List<File> dari image_picker
  }) async {
    try {
      await _api.createTicket(
        title: title,
        description: desc,
        priority: priority,
        category: category,
        attachments: attachments?.cast(),
      );
      Get.back();
      await refreshTickets();
      Get.snackbar(
        'Berhasil',
        'Tiket berhasil dibuat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ── Update status ──────────────────────────────────────────────────────────
  Future<void> updateStatus(String ticketId, String newStatus) async {
    isUpdatingStatus.value = true;
    try {
      final updated = await _api.updateTicketStatus(ticketId, newStatus);
      selectedTicket.value = updated;
      final idx = tickets.indexWhere((t) => t.id == ticketId);
      if (idx >= 0) tickets[idx] = updated;
      // Refresh tracking agar timeline terupdate otomatis
      trackingList.assignAll(await _api.getTracking(ticketId));
      Get.snackbar(
        'Berhasil',
        'Status tiket diperbarui',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  // ── Assign tiket ────────────────────────────────────────────────────────────
  Future<void> loadHelpdeskUsers() async {
    if (helpdeskUsers.isNotEmpty) return; // cache sederhana
    isLoadingHelpdeskUsers.value = true;
    try {
      helpdeskUsers.assignAll(await _api.getHelpdeskUsers());
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
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
      Get.snackbar(
        'Berhasil',
        'Tiket berhasil di-assign',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isAssigning.value = false;
    }
  }

  // ── Comment ────────────────────────────────────────────────────────────────
  Future<void> addComment(String ticketId) async {
    if (commentController.text.trim().isEmpty) return;
    isSubmittingComment.value = true;
    try {
      final comment = await _api.addComment(
        ticketId,
        commentController.text.trim(),
      );
      commentController.clear();
      if (selectedTicket.value != null) {
        selectedTicket.value = TicketModel(
          id: selectedTicket.value!.id,
          title: selectedTicket.value!.title,
          description: selectedTicket.value!.description,
          status: selectedTicket.value!.status,
          priority: selectedTicket.value!.priority,
          category: selectedTicket.value!.category,
          createdBy: selectedTicket.value!.createdBy,
          assignedTo: selectedTicket.value!.assignedTo,
          attachments: selectedTicket.value!.attachments,
          comments: [...selectedTicket.value!.comments, comment],
          createdAt: selectedTicket.value!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmittingComment.value = false;
    }
  }

  // ── History ────────────────────────────────────────────────────────────────
  Future<void> fetchHistory({String? userId}) async {
    isLoadingHistory.value = true;
    try {
      historyList.assignAll(await _api.getHistory(userId: userId));
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
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
