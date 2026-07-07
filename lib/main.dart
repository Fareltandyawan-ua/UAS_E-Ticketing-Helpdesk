import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'core/network/dio_client.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/local_storage.dart';
import 'features/auth/auth_module.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'core/network/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables dari file .env
  await dotenv.load(fileName: '.env');

  await SupabaseService.init();

  // Init local notification (channel, permission Android 13+)
  await LocalNotificationService.init();

  // Inisialisasi locale Indonesia agar DateFormat('id_ID') tidak crash
  await initializeDateFormatting('id_ID', null);

  DioClient.instance.init();

  // Register dependency injection auth feature (Clean Architecture).
  // Setelah ini, AuthController & semua dependency-nya tersedia via Get.find().
  AuthModule.register();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _listenAuthEvents();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final saved = await LocalStorage.getThemeMode();
    setState(() {
      _themeMode = saved == 'dark'
          ? ThemeMode.dark
          : saved == 'light'
          ? ThemeMode.light
          : ThemeMode.system;
    });
  }

  /// Saat user klik link reset password dari email → Supabase emit event
  /// passwordRecovery. Arahkan ke ResetPasswordScreen dalam mode recovery.
  void _listenAuthEvents() {
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        Get.offAllNamed(AppRoutes.resetPassword, arguments: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HelpDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      locale: const Locale('id', 'ID'),
    );
  }
}
