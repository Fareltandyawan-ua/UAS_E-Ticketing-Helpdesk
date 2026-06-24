import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../ticket/presentation/ticket_controller.dart';
import '../../ticket/presentation/ticket_list_screen.dart';
import '../../../main_screen.dart';
import 'dashboard_controller.dart';

/// Helper — switch ke tab Tiket (index 1) via MainTabController
void _goToTickets() {
  if (Get.isRegistered<MainTabController>()) {
    Get.find<MainTabController>().goToTickets();
  } else {
    Get.toNamed(AppRoutes.main);
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashCtrl = Get.find<DashboardController>();
    final authCtrl = Get.find<AuthController>();
    final ticketCtrl = Get.find<TicketController>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await dashCtrl.fetchStats();
          await ticketCtrl.refreshTickets();
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              titleSpacing: 20,
              title: Row(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  Text('HelpDesk',
                      style: AppTextStyles.headingSmall
                          .copyWith(color: AppColors.primary)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Get.toNamed(AppRoutes.notifications),
                ),
                const SizedBox(width: 8),
              ],
              surfaceTintColor: Colors.transparent,
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${authCtrl.currentUser.value?.name ?? "User"} 👋',
                              style: AppTextStyles.headingMedium,
                            ),
                            Text(
                              'Selamat datang di E-Ticketing Helpdesk',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.grey500),
                            ),
                          ],
                        )),
                    const SizedBox(height: 24),

                    // Stats cards
                    Text('Ringkasan Tiket',
                        style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),

                    Obx(() {
                      final s = dashCtrl.stats.value;
                      if (dashCtrl.isLoading.value) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      return Column(
                        children: [
                          // Total card
                          _TotalCard(total: s.total),
                          const SizedBox(height: 12),

                          // Status grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _StatCard(
                                label: 'Dibuka',
                                value: s.open,
                                color: AppColors.statusOpen,
                                bgColor: AppColors.statusOpenBg,
                                icon: Icons.folder_open_outlined,
                                onTap: () => _goToTickets(),
                              ),
                              _StatCard(
                                label: 'Ditugaskan',
                                value: s.assigned,
                                color: AppColors.statusAssigned,
                                bgColor: AppColors.statusAssignedBg,
                                icon: Icons.assignment_turned_in_outlined,
                                onTap: () => _goToTickets(),
                              ),
                              _StatCard(
                                label: 'Diproses',
                                value: s.inProgress,
                                color: AppColors.statusInProgress,
                                bgColor: AppColors.statusInProgressBg,
                                icon: Icons.sync_outlined,
                                onTap: () => _goToTickets(),
                              ),
                              _StatCard(
                                label: 'Ditutup',
                                value: s.closed,
                                color: AppColors.statusClosed,
                                bgColor: AppColors.statusClosedBg,
                                icon: Icons.archive_outlined,
                                onTap: () => _goToTickets(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Kartu khusus Helpdesk ──────────────────────
                          Obx(() {
                            if (!authCtrl.isHelpdesk) {
                              return const SizedBox.shrink();
                            }
                            final s = dashCtrl.stats.value;
                            return Column(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 420;
                                    final cards = [
                                      _StatCard(
                                        label: 'Ditugaskan ke Saya',
                                        value: s.assignedToMe,
                                        color: AppColors.primary,
                                        bgColor: AppColors.primaryContainer,
                                        icon: Icons.assignment_ind_outlined,
                                        onTap: () => _goToTickets(),
                                      ),
                                      _StatCard(
                                        label: 'Belum Ditugaskan',
                                        value: s.unassigned,
                                        color: AppColors.warning,
                                        bgColor: const Color(0xFFFFF8E1),
                                        icon: Icons.person_search_outlined,
                                        onTap: () => _goToTickets(),
                                      ),
                                    ];

                                    if (isNarrow) {
                                      return Column(
                                        children: [
                                          cards[0],
                                          const SizedBox(height: 12),
                                          cards[1],
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(child: cards[0]),
                                        const SizedBox(width: 12),
                                        Expanded(child: cards[1]),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }),

                          // Pie chart
                          if (s.total > 0) _PieChartCard(stats: s),
                        ],
                      );
                    }),

                    const SizedBox(height: 24),

                    // Quick actions
                    Text('Aksi Cepat', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    Obx(() {
                      final isHelpdesk = authCtrl.isHelpdesk;
                      final actions = <Widget>[
                        if (!isHelpdesk)
                          _QuickAction(
                            label: 'Buat Tiket',
                            icon: Icons.add_circle_outline,
                            color: AppColors.primary,
                            onTap: () => Get.toNamed(AppRoutes.createTicket),
                          ),
                        _QuickAction(
                          label: isHelpdesk ? 'Kelola Tiket' : 'Tiket Saya',
                          icon: Icons.confirmation_number_outlined,
                          color: AppColors.secondary,
                          onTap: () => _goToTickets(),
                        ),
                        _QuickAction(
                          label: 'Riwayat',
                          icon: Icons.history_rounded,
                          color: AppColors.info,
                          onTap: () => Get.toNamed(AppRoutes.history),
                        ),
                        if (authCtrl.isAdmin)
                          _QuickAction(
                            label: 'Manajemen\nUser',
                            icon: Icons.manage_accounts_outlined,
                            color: const Color(0xFF7B1FA2),
                            onTap: () => Get.toNamed(AppRoutes.admin),
                          ),
                      ];

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = constraints.maxWidth < 420
                              ? (constraints.maxWidth - 12) / 2
                              : (constraints.maxWidth - 24) / 3;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: actions
                                .map((action) => SizedBox(
                                      width: itemWidth.clamp(120, 220).toDouble(),
                                      child: action,
                                    ))
                                .toList(),
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 24),

                    // Recent tickets
                    Row(
                      children: [
                        Text('Tiket Terbaru', style: AppTextStyles.titleLarge),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _goToTickets(),
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Obx(() {
                      if (ticketCtrl.isLoadingList.value) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (ticketCtrl.tickets.isEmpty) {
                        return EmptyState(
                          title: 'Belum ada tiket',
                          subtitle:
                              'Buat tiket baru untuk memulai',
                          icon: Icons.inbox_outlined,
                          actionLabel: 'Buat Tiket',
                          onAction: () =>
                              Get.toNamed(AppRoutes.createTicket),
                        );
                      }
                      final recent = ticketCtrl.tickets.take(5).toList();
                      return Column(
                        children: recent
                            .map((t) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: TicketCard(ticket: t),
                                ))
                            .toList(),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final int total;

  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Tiket',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white70)),
              const SizedBox(height: 4),
              Text('$total',
                  style: AppTextStyles.displayMedium
                      .copyWith(color: Colors.white)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.confirmation_number_rounded,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$value',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(color: color),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final stats;

  const _PieChartCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribusi Status', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: stats.open.toDouble(),
                    color: AppColors.statusOpen,
                    title: '${stats.open}',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: stats.assigned.toDouble(),
                    color: AppColors.statusAssigned,
                    title: '${stats.assigned}',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: stats.inProgress.toDouble(),
                    color: AppColors.statusInProgress,
                    title: '${stats.inProgress}',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: stats.closed.toDouble(),
                    color: AppColors.statusClosed,
                    title: '${stats.closed}',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Legend(color: AppColors.statusOpen, label: 'Dibuka'),
              _Legend(
                  color: AppColors.statusAssigned, label: 'Ditugaskan'),
              _Legend(
                  color: AppColors.statusInProgress, label: 'Diproses'),
              _Legend(color: AppColors.statusClosed, label: 'Ditutup'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: color),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
