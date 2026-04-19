import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message = 'Terjadi kesalahan. Silakan coba lagi.';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      message = 'Koneksi timeout. Periksa jaringan Anda.';
    } else if (err.type == DioExceptionType.connectionError) {
      message = 'Tidak dapat terhubung ke server.';
    } else if (err.response != null) {
      switch (err.response!.statusCode) {
        case 400:
          message = err.response?.data['message'] ?? 'Permintaan tidak valid.';
          break;
        case 401:
          message = 'Sesi telah berakhir. Silakan login kembali.';
          break;
        case 403:
          message = 'Anda tidak memiliki akses ke fitur ini.';
          break;
        case 404:
          message = 'Data tidak ditemukan.';
          break;
        case 422:
          message = err.response?.data['message'] ?? 'Data tidak valid.';
          break;
        case 500:
          message = 'Kesalahan server. Silakan coba lagi nanti.';
          break;
        default:
          message = err.response?.data['message'] ?? message;
      }
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: message,
        message: message,
      ),
    );
  }
}
