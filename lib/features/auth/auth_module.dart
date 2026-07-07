import 'package:get/get.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/get_cached_user_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/refresh_profile_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/send_password_reset_email_usecase.dart';
import 'domain/usecases/update_password_usecase.dart';
import 'presentation/auth_controller.dart';

/// DI registration untuk Auth feature.
///
/// Dipanggil sekali di `main.dart` sebelum `runApp`. Setelah ini, controller
/// & semua dependency-nya tersedia via `Get.find<T>()`.
///
/// Pattern: datasources & repository sebagai `permanent` singleton (proses-lifetime).
/// Controller di-`put` permanent supaya tetap hidup di seluruh app.
class AuthModule {
  AuthModule._();

  static void register() {
    // Datasources
    Get.put<AuthRemoteDatasource>(AuthRemoteDatasource(), permanent: true);
    Get.put<AuthLocalDatasource>(AuthLocalDatasource(), permanent: true);

    // Repository
    Get.put<AuthRepository>(
      AuthRepositoryImpl(
        remote: Get.find<AuthRemoteDatasource>(),
        local: Get.find<AuthLocalDatasource>(),
      ),
      permanent: true,
    );

    // Use cases
    final repo = Get.find<AuthRepository>();
    Get.put<LoginUseCase>(LoginUseCase(repo), permanent: true);
    Get.put<RegisterUseCase>(RegisterUseCase(repo), permanent: true);
    Get.put<LogoutUseCase>(LogoutUseCase(repo), permanent: true);
    Get.put<SendPasswordResetEmailUseCase>(
      SendPasswordResetEmailUseCase(repo),
      permanent: true,
    );
    Get.put<UpdatePasswordUseCase>(UpdatePasswordUseCase(repo), permanent: true);
    Get.put<RefreshProfileUseCase>(RefreshProfileUseCase(repo), permanent: true);
    Get.put<GetCachedUserUseCase>(GetCachedUserUseCase(repo), permanent: true);

    // Controller
    Get.put<AuthController>(
      AuthController(
        loginUseCase: Get.find<LoginUseCase>(),
        registerUseCase: Get.find<RegisterUseCase>(),
        logoutUseCase: Get.find<LogoutUseCase>(),
        sendPasswordResetEmailUseCase:
            Get.find<SendPasswordResetEmailUseCase>(),
        updatePasswordUseCase: Get.find<UpdatePasswordUseCase>(),
        refreshProfileUseCase: Get.find<RefreshProfileUseCase>(),
        getCachedUserUseCase: Get.find<GetCachedUserUseCase>(),
      ),
      permanent: true,
    );
  }
}
