import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_widgets.dart';
import '../../routes/app_routes.dart';
import 'notification_model.dart';
import 'notification_controller.dart';

// ─────────────────────────────────────────────
// NOTIFICATION SCREEN
// ─────────────────────────────────────────────
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (ctrl.unreadCount.value == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: ctrl.markAllRead,
              child: const Text(
                'Tandai semua dibaca',
                style: TextStyle(fontSize: 12),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.notifications.isEmpty) {
          return const EmptyState(
            title: 'Tidak ada notifikasi',
            subtitle: 'Notifikasi update tiket akan muncul di sini',
            icon: Icons.notifications_none_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: ctrl.fetchNotifications,
          child: ListView.separated(
            itemCount: ctrl.notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) {
              final notif = ctrl.notifications[i];
              return _NotificationTile(
                notif: notif,
                onTap: () {
                  if (!notif.isRead) ctrl.markRead(notif.id);
                  if (notif.ticketId != null) {
                    Get.toNamed(
                      AppRoutes.ticketDetail,
                      arguments: notif.ticketId,
                    );
                  }
                },
              );
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;

  const _NotificationTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: notif.isRead
            ? null
            : AppColors.primaryContainer.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notif.isRead
                      ? AppColors.grey100
                      : AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notif.ticketId != null
                      ? Icons.confirmation_number_outlined
                      : Icons.notifications_outlined,
                  color:
                      notif.isRead ? AppColors.grey400 : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: notif.isRead
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.timeAgo(notif.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Trailing unread indicator
              if (!notif.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
