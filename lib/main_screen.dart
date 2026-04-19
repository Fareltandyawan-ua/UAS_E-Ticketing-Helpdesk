import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/ticket/presentation/ticket_list_screen.dart';
import 'features/notification/notification_controller.dart';
import 'features/notification/notification_screen.dart';
import 'features/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    TicketListScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number_rounded),
              label: 'Tiket',
            ),
            BottomNavigationBarItem(
              icon: _NotifIcon(active: false),
              activeIcon: _NotifIcon(active: true),
              label: 'Notifikasi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
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
