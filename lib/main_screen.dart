import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/dashboard_controller.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/ticket/presentation/ticket_controller.dart';
import 'features/ticket/presentation/ticket_list_screen.dart';
import 'features/notification/notification_controller.dart';
import 'features/notification/notification_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/admin/presentation/admin_screen.dart';
import 'features/auth/presentation/auth_controller.dart';

/// Controller untuk mengelola tab aktif di MainScreen dari mana saja
class MainTabController extends GetxController {
  final RxInt currentIndex = 0.obs;
  int _prevIndex = 0;

  @override
  void onInit() {
    super.onInit();
    // Setiap kali tab berubah, trigger refresh data pada tab yang dituju
    ever(currentIndex, _onTabChanged);
  }

  void _onTabChanged(int newIndex) {
    if (newIndex == _prevIndex) return;
    _prevIndex = newIndex;

    switch (newIndex) {
      case 0: // Dashboard
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().fetchStats();
        }
        break;
      case 1: // Tiket
        if (Get.isRegistered<TicketController>()) {
          Get.find<TicketController>().refreshTickets();
        }
        break;
      case 2: // Notifikasi
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().fetchNotifications();
        }
        break;
    }
  }

  void switchToTab(int index) => currentIndex.value = index;

  /// Tab index untuk Tiket (index 1 selalu)
  void goToTickets() => switchToTab(1);

  /// Tab index untuk Notifikasi (index 2 selalu)
  void goToNotifications() => switchToTab(2);
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabCtrl = Get.put(MainTabController(), permanent: true);
    final authCtrl = Get.find<AuthController>();

    return Obx(() {
      final isAdmin    = authCtrl.isAdmin;
      final isHelpdesk = authCtrl.isHelpdesk;

      final pages = <Widget>[
        const DashboardScreen(),
        const TicketListScreen(),
        const NotificationScreen(),
        if (isAdmin) const AdminScreen(),
        const ProfileScreen(),
      ];

      final navItems = <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.confirmation_number_outlined),
          activeIcon: const Icon(Icons.confirmation_number_rounded),
          label: isHelpdesk ? 'Kelola' : 'Tiket',
        ),
        BottomNavigationBarItem(
          icon: _NotifIcon(active: false),
          activeIcon: _NotifIcon(active: true),
          label: 'Notifikasi',
        ),
        if (isAdmin)
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admin',
          ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ];

      final safeIndex =
          tabCtrl.currentIndex.value.clamp(0, pages.length - 1);

      return Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: (i) => tabCtrl.currentIndex.value = i,
            items: navItems,
          ),
        ),
      );
    });
  }
}

/// Icon notifikasi dengan badge jumlah unread
class _NotifIcon extends StatelessWidget {
  final bool active;
  const _NotifIcon({required this.active});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();
    return Obx(() {
      final count = ctrl.unreadCount.value;
      return Badge(
        isLabelVisible: count > 0,
        label: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        child: Icon(
          active
              ? Icons.notifications_rounded
              : Icons.notifications_outlined,
        ),
      );
    });
  }
}
