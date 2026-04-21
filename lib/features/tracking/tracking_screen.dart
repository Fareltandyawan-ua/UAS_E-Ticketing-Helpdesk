import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_widgets.dart';
import '../ticket/presentation/ticket_controller.dart';
import '../ticket/presentation/ticket_list_screen.dart';
import '../../routes/app_routes.dart';

// ─────────────────────────────────────────────
// HISTORY SCREEN
// ─────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TicketController _ctrl = Get.find<TicketController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Tiket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoadingHistory.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctrl.historyList.isEmpty) {
          return const EmptyState(
            title: 'Belum ada riwayat',
            subtitle:
                'Tiket yang sudah selesai atau ditutup akan tampil di sini',
            icon: Icons.history_rounded,
          );
        }
        return RefreshIndicator(
          onRefresh: _ctrl.fetchHistory,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _ctrl.historyList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => TicketCard(ticket: _ctrl.historyList[i]),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// TRACKING SCREEN
// ─────────────────────────────────────────────
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TicketController _ctrl = Get.find<TicketController>();
  late String _ticketId;

  @override
  void initState() {
    super.initState();
    _ticketId = Get.arguments as String;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.loadTicketDetail(_ticketId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Tiket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoadingDetail.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final ticket = _ctrl.selectedTicket.value;
        if (ticket == null) {
          return const EmptyState(
            title: 'Tiket tidak ditemukan',
            icon: Icons.error_outline,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.title,
                            style: AppTextStyles.titleLarge,
                          ),
                        ),
                        StatusBadge(status: ticket.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#${ticket.id} • ${ticket.category}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Riwayat Penanganan', style: AppTextStyles.titleLarge),
              const SizedBox(height: 16),

              if (_ctrl.trackingList.isEmpty)
                const EmptyState(
                  title: 'Belum ada perubahan status',
                  icon: Icons.track_changes_outlined,
                )
              else
                _buildTimeline(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final list = _ctrl.trackingList;
    return Column(
      children: List.generate(list.length, (i) {
        final item = list[i];
        final isLast = i == list.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _statusColor(item.status).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _statusColor(item.status),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _statusIcon(item.status),
                      color: _statusColor(item.status),
                      size: 18,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.borderLight,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      StatusBadge(status: item.status),
                      const SizedBox(height: 6),
                      Text(item.description, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 13,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.changedBy?.name ?? 'System',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.grey400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.access_time_outlined,
                            size: 13,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatWithTime(item.createdAt),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.statusOpen;
      case 'in_progress':
        return AppColors.statusInProgress;
      case 'resolved':
        return AppColors.statusResolved;
      case 'closed':
        return AppColors.statusClosed;
      default:
        return AppColors.grey400;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.folder_open_outlined;
      case 'in_progress':
        return Icons.sync_rounded;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'closed':
        return Icons.archive_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}
