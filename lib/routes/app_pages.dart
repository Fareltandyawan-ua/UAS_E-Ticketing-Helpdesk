import 'package:get/get.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/dashboard/presentation/dashboard_controller.dart';
import '../features/ticket/presentation/ticket_controller.dart';
import '../features/ticket/presentation/ticket_detail_screen.dart';
import '../features/ticket/presentation/create_ticket_screen.dart';
import '../features/notification/notification_controller.dart';
import '../features/notification/notification_screen.dart';
import '../features/tracking/tracking_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/admin/presentation/admin_controller.dart';
import '../features/admin/presentation/admin_screen.dart';
import 'app_routes.dart';
import '../main_screen.dart';
import '../splash_screen.dart';

class AppPages {
  AppPages._();

  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
    GetPage(name: AppRoutes.register, page: () => RegisterScreen()),
    GetPage(name: AppRoutes.forgotPassword, page: () => ForgotPasswordScreen()),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DashboardController>(() => DashboardController());
        Get.lazyPut<TicketController>(() => TicketController());
        Get.lazyPut<NotificationController>(() => NotificationController());
        // AdminController hanya diinisialisasi jika user adalah admin
        final authCtrl = Get.find<AuthController>();
        if (authCtrl.isAdmin) {
          Get.lazyPut<AdminController>(() => AdminController());
        }
      }),
    ),
    GetPage(
      name: AppRoutes.ticketDetail,
      page: () => const TicketDetailScreen(),
    ),
    GetPage(
      name: AppRoutes.createTicket,
      page: () => CreateTicketScreen(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationScreen(),
    ),
    GetPage(
      name: AppRoutes.tracking,
      page: () => const TrackingScreen(),
    ),
    GetPage(name: AppRoutes.history, page: () => const HistoryScreen()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
    GetPage(name: AppRoutes.editProfile, page: () => EditProfileScreen()),
    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AdminController>(() => AdminController());
      }),
    ),
  ];
}
