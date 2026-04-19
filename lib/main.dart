import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/local_storage.dart';
import 'features/auth/presentation/auth_controller.dart';
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

  // Inisialisasi locale Indonesia agar DateFormat('id_ID') tidak crash
  await initializeDateFormatting('id_ID', null);

  DioClient.instance.init();

  Get.put(AuthController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
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
