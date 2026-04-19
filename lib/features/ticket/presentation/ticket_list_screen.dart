import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../routes/app_routes.dart';
import 'ticket_controller.dart';
import '../data/ticket_model.dart';

class TicketListScreen extends StatelessWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TicketController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, ctrl),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => ctrl.searchQuery.value = v,
              decoration: const InputDecoration(
                hintText: 'Cari tiket...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Filter chips
          Obx(() {
            final hasFilter = ctrl.filterStatus.value.isNotEmpty ||
                ctrl.filterPriority.value.isNotEmpty;
            if (!hasFilter) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text('Filter: ',
                      style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                  if (ctrl.filterStatus.value.isNotEmpty)
                    _chip(ctrl.filterStatus.value, () =>
                        ctrl.setFilter(status: '')),
                  if (ctrl.filterPriority.value.isNotEmpty)
                    _chip(ctrl.filterPriority.value, () =>
                        ctrl.setFilter(priority: '')),
                  TextButton(
                    onPressed: ctrl.clearFilters,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero),
                    child: const Text('Hapus semua',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.error)),
                  ),
                ],
              ),
            );
          }),

          // List
          Expanded(
            child: Obx(() {
              if (ctrl.isLoadingList.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ctrl.tickets.isEmpty) {
                return EmptyState(
                  title: 'Belum Ada Tiket',
                  subtitle: 'Buat tiket baru untuk melaporkan masalah Anda',
                  icon: Icons.confirmation_number_outlined,
                  actionLabel: 'Buat Tiket',
                  onAction: () => Get.toNamed(AppRoutes.createTicket),
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.refreshTickets,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ctrl.tickets.length +
                      (ctrl.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == ctrl.tickets.length) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    return TicketCard(ticket: ctrl.tickets[index]);
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
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, TicketController ctrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
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
              children: ['', 'open', 'in_progress', 'resolved', 'closed']
                  .map((s) => Obx(() => ChoiceChip(
                        label: Text(s.isEmpty ? 'Semua' : s),
                        selected: ctrl.filterStatus.value == s,
                        onSelected: (_) {
                          ctrl.setFilter(status: s);
                          Navigator.pop(context);
                        },
                      )))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Prioritas', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  ['', 'low', 'medium', 'high', 'critical']
                      .map((p) => Obx(() => ChoiceChip(
                            label: Text(p.isEmpty ? 'Semua' : p),
                            selected: ctrl.filterPriority.value == p,
                            onSelected: (_) {
                              ctrl.setFilter(priority: p);
                              Navigator.pop(context);
                            },
                          )))
                      .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final TicketModel ticket;

  const TicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.ticketDetail,
        arguments: ticket.id,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${ticket.id} • ${ticket.category}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.grey500),
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
            const SizedBox(height: 6),
            Text(
              ticket.description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                PriorityBadge(priority: ticket.priority),
                const Spacer(),
                const Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.timeAgo(ticket.createdAt),
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400),
                ),
                if (ticket.comments.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.comments.length}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.grey400),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
