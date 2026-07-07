/// Backward-compatible shim.
///
/// File ini sebelumnya berisi class `UserModel` lengkap. Setelah refactor
/// Clean Architecture, `UserModel` pindah ke `models/user_model.dart` dan
/// `User` entity di domain layer. File ini sekarang hanya re-export keduanya
/// supaya import lama (`import '.../data/auth_model.dart';`) di feature lain
/// tetap jalan tanpa perubahan.
library;

export 'models/user_model.dart';
export '../domain/entities/user.dart';
