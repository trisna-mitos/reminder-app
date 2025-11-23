# SIM Reminder - Aplikasi Pengingat SIM Indonesia

Aplikasi mobile untuk mengelola dan mendapatkan pengingat otomatis untuk perpanjangan Surat Izin Mengemudi (SIM) di Indonesia.

## 🚀 Fitur Utama

### ✨ Fitur Lengkap
- **📸 Scan Otomatis** - Ambil foto SIM dan data terisi otomatis dengan OCR (ML Kit)
- **🔔 Notifikasi Pintar** - Pengingat 7 hari sebelum kadaluarsa dengan notifikasi harian
- **☁️ Sinkronisasi Cloud** - Data tersimpan di Firebase untuk akses dari berbagai perangkat
- **👤 Mode Tamu** - Gunakan tanpa akun untuk data lokal
- **🔐 Google Sign-In** - Login mudah dan aman dengan akun Google
- **📱 Kelola Multiple SIM** - Simpan SIM A, B, dan C dalam satu aplikasi
- **⏱️ Countdown Timer** - Lihat sisa hari sebelum kadaluarsa
- **🖼️ Simpan Foto SIM** - Foto tersimpan di Firebase Storage atau lokal

### 🎨 UI/UX
- **Material Design 3** - Desain modern dan clean
- **Bahasa Indonesia 100%** - Semua teks dalam Bahasa Indonesia
- **Responsive** - Mendukung berbagai ukuran layar
- **Warna Professional** - Skema warna biru dan putih

## 📋 Tech Stack

- **Framework**: Flutter (Latest Stable)
- **State Management**: Provider
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging
- **OCR**: ML Kit Text Recognition
- **Local Storage**: Hive
- **Image Handling**: image_picker, image_cropper, flutter_image_compress
- **Notifications**: flutter_local_notifications + FCM

## 📦 Instalasi & Setup

### Prerequisites
- Flutter SDK (3.0.0 atau lebih baru)
- Android Studio / Xcode
- Firebase Account
- Google Cloud Console Account (untuk Google Sign-In)

### Langkah 1: Clone Repository
```bash
git clone <repository-url>
cd reminder-app
```

### Langkah 2: Install Dependencies
```bash
flutter pub get
```

### Langkah 3: Setup Firebase

#### 3.1 Buat Firebase Project
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Add project" atau "Tambah project"
3. Masukkan nama project (contoh: "SIM Reminder")
4. Ikuti wizard setup hingga selesai

#### 3.2 Setup Firebase untuk Android

1. **Tambahkan Android App di Firebase Console**
   - Klik icon Android di Firebase Console
   - Package name: `com.reminderapp.sim_reminder`
   - Klik "Register app"

2. **Download google-services.json**
   - Download file `google-services.json`
   - Letakkan di folder: `android/app/google-services.json`

3. **Aktifkan Firebase Services**
   - Di Firebase Console, aktifkan:
     - ✅ Authentication (Google Sign-In)
     - ✅ Cloud Firestore
     - ✅ Storage
     - ✅ Cloud Messaging

#### 3.3 Setup Firebase untuk iOS

1. **Tambahkan iOS App di Firebase Console**
   - Klik icon iOS di Firebase Console
   - Bundle ID: `com.reminderapp.simReminder`
   - Klik "Register app"

2. **Download GoogleService-Info.plist**
   - Download file `GoogleService-Info.plist`
   - Letakkan di folder: `ios/Runner/GoogleService-Info.plist`

3. **Update Info.plist**
   - File sudah tersedia di `ios/Runner/Info.plist`
   - Update `CFBundleURLSchemes` dengan Client ID dari Firebase

### Langkah 4: Setup Google Sign-In

1. **Buka Google Cloud Console**
   - Pergi ke [Google Cloud Console](https://console.cloud.google.com/)
   - Pilih project Firebase Anda

2. **Aktifkan Google Sign-In API**
   - Navigation Menu → APIs & Services → Library
   - Cari "Google Sign-In API"
   - Klik "Enable"

3. **Buat OAuth 2.0 Client IDs**
   - APIs & Services → Credentials
   - Create Credentials → OAuth 2.0 Client ID

   **Untuk Android:**
   - Application type: Android
   - Package name: `com.reminderapp.sim_reminder`
   - SHA-1: Dapatkan dengan command:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```

   **Untuk iOS:**
   - Application type: iOS
   - Bundle ID: `com.reminderapp.simReminder`

4. **Update iOS Info.plist**
   - Buka `ios/Runner/Info.plist`
   - Ganti `YOUR-CLIENT-ID` dengan iOS Client ID dari Google Cloud Console

### Langkah 5: Setup Firestore Database

1. **Buat Firestore Database**
   - Di Firebase Console, buka Firestore Database
   - Klik "Create Database"
   - Pilih mode: **Start in production mode**
   - Pilih lokasi: **asia-southeast2 (Jakarta)** atau terdekat

2. **Setup Firestore Rules**
   Tambahkan rules berikut di Firestore Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Licenses subcollection
      match /licenses/{licenseId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Langkah 6: Setup Firebase Storage

1. **Buka Storage di Firebase Console**
2. **Klik "Get Started"**
3. **Setup Storage Rules**:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /licenses/{userId}/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Langkah 7: Setup Firebase Cloud Messaging (FCM)

1. **Android Setup**
   - File `google-services.json` sudah include konfigurasi FCM
   - Tidak perlu setup tambahan

2. **iOS Setup**
   - Buka project di Xcode
   - Add capability "Push Notifications"
   - Add capability "Background Modes" → centang "Remote notifications"

### Langkah 8: Build & Run

#### Android
```bash
flutter run
```

#### iOS
```bash
cd ios
pod install
cd ..
flutter run
```

## 🗂️ Struktur Project

```
lib/
├── main.dart                  # Entry point aplikasi
├── models/                    # Data models
│   ├── license_model.dart
│   └── user_model.dart
├── services/                  # Business logic services
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── storage_service.dart
│   ├── local_storage_service.dart
│   ├── ocr_service.dart
│   └── notification_service.dart
├── providers/                 # State management (Provider)
│   ├── auth_provider.dart
│   └── license_provider.dart
├── screens/                   # UI Screens
│   ├── welcome_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── add_license_screen.dart
│   ├── license_detail_screen.dart
│   └── settings_screen.dart
├── widgets/                   # Reusable widgets
│   └── license_card.dart
└── utils/                     # Utilities & helpers
    ├── app_theme.dart
    ├── app_strings.dart
    └── date_helper.dart
```

## 🔥 Firestore Data Structure

```
users/{userId}/
├── email: string
├── displayName: string
├── photoUrl: string
├── isGuest: boolean
├── createdAt: timestamp
├── lastLogin: timestamp
└── notificationsEnabled: boolean

users/{userId}/licenses/{licenseId}/
├── licenseNumber: string
├── licenseType: string (SIM A/B/C)
├── ownerName: string
├── expirationDate: timestamp
├── photoUrl: string
├── createdAt: timestamp
└── updatedAt: timestamp
```

## 📱 Cara Penggunaan

### Untuk User Baru
1. **Welcome Screen** - Lihat onboarding
2. **Login** - Pilih Google Sign-In atau Mode Tamu
3. **Tambah SIM** - Tekan tombol + untuk tambah SIM
4. **Ambil Foto** - Foto SIM dengan kamera
5. **Verifikasi Data** - Data otomatis terisi, edit jika perlu
6. **Simpan** - SIM tersimpan dan notifikasi terjadwal

### Fitur Mode Tamu vs Akun Google

| Fitur | Mode Tamu | Akun Google |
|-------|-----------|-------------|
| Simpan Data | ✅ Lokal | ✅ Cloud |
| Sinkronisasi | ❌ | ✅ |
| Backup Otomatis | ❌ | ✅ |
| Multi Device | ❌ | ✅ |
| Notifikasi | ✅ | ✅ |

## 🔔 Sistem Notifikasi

- **7 Hari Sebelum**: Notifikasi pertama
- **6-1 Hari Sebelum**: Notifikasi harian
- **Hari H**: Notifikasi kadaluarsa
- **Waktu**: Setiap notifikasi jam 09:00 WIB

## 🛠️ Troubleshooting

### Build Failed
```bash
flutter clean
flutter pub get
flutter run
```

### Google Sign-In Error
- Pastikan SHA-1 fingerprint sudah ditambahkan di Firebase Console
- Periksa package name/bundle ID sudah sesuai
- Download ulang `google-services.json` / `GoogleService-Info.plist`

### OCR Tidak Bekerja
- Pastikan ML Kit dependencies sudah ter-install
- Test dengan foto SIM yang jelas dan terang
- OCR butuh pencahayaan yang baik

### Notifikasi Tidak Muncul
- Periksa permission notifikasi di settings HP
- Pastikan FCM token berhasil di-generate
- Test dengan foreground notification dulu

## 📄 License

MIT License - Silakan gunakan untuk project pribadi atau komersial

## 👨‍💻 Developer

Dibuat dengan ❤️ untuk membantu pengendara Indonesia

---

## 📞 Support

Jika ada pertanyaan atau masalah:
- Buka Issue di GitHub
- Email: support@simreminder.com
