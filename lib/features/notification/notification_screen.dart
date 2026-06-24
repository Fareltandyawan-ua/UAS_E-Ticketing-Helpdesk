import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_widgets.dart';
import '../../routes/app_routes.dart';
import 'notification_model.dart';
import 'notification_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  late NotificationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<NotificationController>();
    WidgetsBinding.instance.addObserver(this);
    // Refresh setiap kali screen ini pertama kali dibuka / menjadi aktif
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.fetchNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh saat app kembali ke foreground
    if (state == AppLifecycleState.resumed) {
      _ctrl.fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tombol back hanya tampil jika ada rute sebelumnya (bukan dari tab)
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        // Hanya tampilkan back button jika bisa kembali
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Get.back(),
              )
            : null,
        automaticallyImplyLeading: canPop,
        actions: [
          // Refresh manual
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _ctrl.fetchNotifications,
          ),
          Obx(() {
            if (_ctrl.unreadCount.value == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: _ctrl.markAllRead,
              child: const Text(
                'Baca semua',
                style: TextStyle(fontSize: 12),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctrl.notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: _ctrl.fetchNotifications,
            child: const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: EmptyState(
                  title: 'Tidak ada notifikasi',
                  subtitle: 'Notifikasi update tiket akan muncul di sini',
                  icon: Icons.notifications_none_outlined,
                ),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _ctrl.fetchNotifications,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _ctrl.notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) {
              final notif = _ctrl.notifications[i];
              return _NotificationTile(
                notif: notif,
                onTap: () async {
                  if (!notif.isRead) _ctrl.markRead(notif.id);
                  if (notif.ticketId != null) {
                    final exists = await _ctrl.ticketExists(notif.ticketId!);
                    if (!exists) {
                      _ctrl.fetchNotifications();
                      Get.snackbar(
                        'Tiket tidak tersedia',
                        'Tiket ini sudah dihapus.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.warning,
                        colorText: Colors.white,
                      );
                      return;
                    }
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
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.isRead
            ? null
            : AppColors.primaryContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  color: notif.isRead
                      ? AppColors.grey400
                      : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                          color: AppColors.grey500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.timeAgo(notif.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.grey400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
