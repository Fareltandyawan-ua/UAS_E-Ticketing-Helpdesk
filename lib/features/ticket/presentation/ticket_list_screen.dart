import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../routes/app_routes.dart';
import '../../auth/presentation/auth_controller.dart';
import 'ticket_controller.dart';
import '../data/ticket_model.dart';

class TicketListScreen extends StatelessWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    return Obx(() {
      final isHelpdesk = authCtrl.isHelpdesk;
      return isHelpdesk ? const _HelpdeskTicketView() : const _UserTicketView();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW USER BIASA
// ─────────────────────────────────────────────────────────────────────────────
class _UserTicketView extends StatelessWidget {
  const _UserTicketView();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TicketController>();
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiket Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, ctrl),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(ctrl: ctrl),
          _FilterChips(ctrl: ctrl),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoadingList.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final userId = authCtrl.currentUser.value?.id;
              final myTickets = ctrl.tickets
                  .where((t) => t.createdBy?.id == userId)
                  .toList();
              if (myTickets.isEmpty) {
                return EmptyState(
                  title: 'Belum Ada Tiket',
                  subtitle: 'Buat tiket baru untuk melaporkan masalah',
                  icon: Icons.confirmation_number_outlined,
                  actionLabel: 'Buat Tiket',
                  onAction: () => Get.toNamed(AppRoutes.createTicket),
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.refreshTickets,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      myTickets.length + (ctrl.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == myTickets.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return TicketCard(ticket: myTickets[i]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.createTicket),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Tiket'),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, TicketController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(ctrl: ctrl),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW HELPDESK / ADMIN — dengan Tab
// ─────────────────────────────────────────────────────────────────────────────
class _HelpdeskTicketView extends StatefulWidget {
  const _HelpdeskTicketView();

  @override
  State<_HelpdeskTicketView> createState() => _HelpdeskTicketViewState();
}

class _HelpdeskTicketViewState extends State<_HelpdeskTicketView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final ctrl = Get.find<TicketController>();
  final authCtrl = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    // Load semua tiket saat pertama dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.fetchTickets();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => _FilterSheet(ctrl: ctrl),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Ditugaskan'),
            Tab(text: 'Belum Dihandle'),
          ],
        ),
      ),
      body: Column(
        children: [
          _SearchBar(ctrl: ctrl),
          _FilterChips(ctrl: ctrl),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoadingList.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final myId = authCtrl.currentUser.value?.id;
              final allTickets = ctrl.tickets;
              final myTickets = allTickets
                  .where((t) => t.assignedTo?.id == myId)
                  .toList();
              final unhandled = allTickets
                  .where(
                    (t) =>
                        t.assignedTo == null &&
                        (t.status == 'open' || t.status == 'in_progress'),
                  )
                  .toList();

              return TabBarView(
                controller: _tabCtrl,
                children: [
                  _TicketTabContent(
                    tickets: allTickets,
                    emptyTitle: 'Tidak ada tiket',
                    showAssignee: true,
                    onLoadMore: () => ctrl.fetchTickets(loadMore: true),
                    isLoadingMore: ctrl.isLoadingMore.value,
                    onRefresh: ctrl.refreshTickets,
                  ),
                  _TicketTabContent(
                    tickets: myTickets,
                    emptyTitle: 'Tidak ada tiket yang ditugaskan ke Anda',
                    emptySubtitle: 'Ambil tiket dari tab "Belum Dihandle"',
                    showAssignee: false,
                    onRefresh: ctrl.refreshTickets,
                  ),
                  _TicketTabContent(
                    tickets: unhandled,
                    emptyTitle: 'Tidak ada tiket yang perlu dihandle',
                    showAssignee: true,
                    onRefresh: ctrl.refreshTickets,
                    // Tampilkan tombol self-assign
                    showSelfAssign: true,
                    selfAssignUserId: myId,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB CONTENT (shared)
// ─────────────────────────────────────────────────────────────────────────────
class _TicketTabContent extends StatelessWidget {
  final List<TicketModel> tickets;
  final String emptyTitle;
  final String? emptySubtitle;
  final bool showAssignee;
  final bool showSelfAssign;
  final String? selfAssignUserId;
  final Future<void> Function() onRefresh;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const _TicketTabContent({
    required this.tickets,
    required this.emptyTitle,
    this.emptySubtitle,
    required this.showAssignee,
    required this.onRefresh,
    this.showSelfAssign = false,
    this.selfAssignUserId,
    this.onLoadMore,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: Icons.confirmation_number_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == tickets.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return TicketCard(
            ticket: tickets[i],
            showAssignee: showAssignee,
            showSelfAssign: showSelfAssign,
            selfAssignUserId: selfAssignUserId,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TicketController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        onChanged: (v) => ctrl.searchQuery.value = v,
        decoration: const InputDecoration(
          hintText: 'Cari tiket...',
          prefixIcon: Icon(Icons.search_rounded, size: 20),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final TicketController ctrl;
  const _FilterChips({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasFilter =
          ctrl.filterStatus.value.isNotEmpty ||
          ctrl.filterPriority.value.isNotEmpty;
      if (!hasFilter) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Filter: ',
              style: TextStyle(fontSize: 12, color: AppColors.grey500),
            ),
            if (ctrl.filterStatus.value.isNotEmpty)
              _chip(ctrl.filterStatus.value, () => ctrl.setFilter(status: '')),
            if (ctrl.filterPriority.value.isNotEmpty)
              _chip(
                ctrl.filterPriority.value,
                () => ctrl.setFilter(priority: ''),
              ),
            TextButton(
              onPressed: ctrl.clearFilters,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Hapus semua',
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final TicketController ctrl;
  const _FilterSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Tiket', style: AppTextStyles.titleLarge),
            const SizedBox(height: 20),
            Text('Status', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['', 'open', 'assigned', 'in_progress', 'closed']
                  .map(
                    (s) => Obx(
                      () => ChoiceChip(
                        label: Text(s.isEmpty ? 'Semua' : s),
                        selected: ctrl.filterStatus.value == s,
                        onSelected: (_) {
                          ctrl.setFilter(status: s);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Prioritas', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['', 'low', 'medium', 'high', 'critical']
                  .map(
                    (p) => Obx(
                      () => ChoiceChip(
                        label: Text(p.isEmpty ? 'Semua' : p),
                        selected: ctrl.filterPriority.value == p,
                        onSelected: (_) {
                          ctrl.setFilter(priority: p);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TICKET CARD
// ─────────────────────────────────────────────────────────────────────────────
class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final bool showAssignee;
  final bool showSelfAssign;
  final String? selfAssignUserId;

  const TicketCard({
    super.key,
    required this.ticket,
    this.showAssignee = false,
    this.showSelfAssign = false,
    this.selfAssignUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = ticket.priority == 'critical';

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.ticketDetail, arguments: ticket.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCritical
                ? AppColors.error.withOpacity(0.5)
                : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            width: isCritical ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${ticket.category}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ),
                StatusBadge(status: ticket.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.title,
              style: AppTextStyles.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Assignee info (untuk helpdesk)
            if (showAssignee) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 13,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.assignedTo?.name ?? 'Belum di-assign',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: ticket.assignedTo == null
                            ? AppColors.warning
                            : AppColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PriorityBadge(priority: ticket.priority),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.timeAgo(ticket.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
                if (ticket.comments.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 13,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.comments.length}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),

                // Tombol "Ambil Tiket" — self assign
                if (showSelfAssign && selfAssignUserId != null)
                  GestureDetector(
                    onTap: () {
                      final ticketCtrl = Get.find<TicketController>();
                      ticketCtrl.assignTicket(ticket.id, selfAssignUserId!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ambil',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
