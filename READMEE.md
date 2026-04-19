# E-Ticketing Helpdesk — Flutter Mobile App

Aplikasi mobile E-Ticketing Helpdesk berbasis Flutter untuk pelaporan, monitoring,
dan penyelesaian masalah IT atau layanan lainnya.

---

## Fitur Utama

| Fitur | FR | Deskripsi |
|---|---|---|
| Login & Register | FR-001, FR-003 | Autentikasi user dengan JWT |
| Logout | FR-002 | Keluar dari sesi |
| Reset Password | FR-004 | Kirim link reset ke email |
| Manajemen Tiket (User) | FR-005 | Buat, lihat, komentar tiket |
| Manajemen Tiket (Admin/Helpdesk) | FR-006 | Update status, assign tiket |
| Notifikasi | FR-007 | Push notification via FCM |
| Dashboard Statistik | FR-008 | Total & distribusi tiket |
| Riwayat Tiket | FR-010 | Semua tiket selesai/ditutup |
| Tracking Tiket | FR-011 | Timeline perubahan status |
| Dark/Light Mode | NFR | Toggle tema |

---

## Teknologi

- **Framework**: Flutter 3.x
- **State Management**: GetX
- **HTTP Client**: Dio
- **Notifikasi**: Firebase Cloud Messaging (FCM)
- **Storage**: flutter_secure_storage + shared_preferences
- **Chart**: fl_chart
- **File Upload**: image_picker + file_picker

---

## Cara Menjalankan

### 1. Clone & install dependencies
```bash
git clone https://github.com/USERNAME/nim_nama_kelas_uts.git
cd nim_nama_kelas_uts
flutter pub get
```

### 2. Setup Firebase
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Konfigurasi Firebase (butuh project Firebase)
flutterfire configure
```

### 3. Konfigurasi API
Edit `lib/core/constants/api_endpoints.dart`:
```dart
static const String baseUrl = 'https://YOUR_API_URL/api/v1';
```

### 4. Jalankan aplikasi
```bash
# Debug mode
flutter run

# Release APK
flutter build apk --release
```

### 5. Jalankan tests
```bash
flutter test
```

---

## Struktur Project

```
lib/
├── core/
│   ├── theme/          # AppTheme, AppColors, AppTextStyles
│   ├── constants/      # ApiEndpoints, AppStrings
│   ├── utils/          # Validators, DateFormatter, FilePickerHelper
│   ├── widgets/        # CustomButton, CustomTextField, StatusBadge, dll
│   ├── network/        # DioClient, AuthInterceptor, ErrorInterceptor
│   └── storage/        # SecureStorage, LocalStorage
├── features/
│   ├── auth/           # Login, Register, ForgotPassword (FR-001~004)
│   ├── dashboard/      # Statistik tiket (FR-008)
│   ├── ticket/         # CRUD tiket, komentar (FR-005~006)
│   ├── notification/   # FCM notification (FR-007)
│   ├── tracking/       # Timeline & riwayat (FR-010~011)
│   └── profile/        # Profil & edit profil
├── routes/             # AppRoutes, AppPages, Middleware
├── main_screen.dart    # Bottom navigation
├── splash_screen.dart  # Splash + auth check
└── main.dart           # Entry point
```

---

## Format Nama Repository

```
NIM_NAMA_KELAS_uts
Contoh: 234567890_budisantoso_TI2A_uts
```

---

## Catatan

- Backend API **belum disertakan** dalam repo ini (sesuai scope SRS)
- Endpoint API dapat disesuaikan di `ApiEndpoints`
- Untuk mock/testing tanpa backend, gunakan tools seperti **Mocktail** atau **json-server**
