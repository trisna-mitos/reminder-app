# 🚀 Quick Start Guide

Panduan cepat untuk menjalankan aplikasi SIM Reminder.

## ⚡ Setup Cepat (5 Menit)

### 1. Prerequisites
```bash
# Check Flutter
flutter --version

# Harus Flutter 3.0.0 atau lebih baru
```

### 2. Clone & Install
```bash
# Clone repository
git clone <repository-url>
cd reminder-app

# Install dependencies
flutter pub get
```

### 3. Setup Firebase (WAJIB)

**Langkah Minimal:**

1. **Buat Firebase Project**
   - Buka https://console.firebase.google.com/
   - Create new project

2. **Download Config Files**
   - **Android**: Download `google-services.json` → letakkan di `android/app/`
   - **iOS**: Download `GoogleService-Info.plist` → tambahkan via Xcode

3. **Enable Services di Firebase Console**
   - ✅ Authentication (Google + Anonymous)
   - ✅ Firestore Database
   - ✅ Storage
   - ✅ Cloud Messaging

4. **Setup Google Sign-In**
   - Tambahkan SHA-1 fingerprint untuk Android
   - Buat OAuth Client ID di Google Cloud Console

📖 **Detail lengkap**: Lihat [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

### 4. Run App
```bash
# Android
flutter run

# iOS
cd ios
pod install
cd ..
flutter run
```

## 🎯 Test Checklist

Setelah app running, test fitur-fitur ini:

- [ ] **Welcome Screen** muncul untuk first-time user
- [ ] **Login dengan Google** berhasil
- [ ] **Mode Tamu** berhasil
- [ ] **Tambah SIM** dengan kamera
- [ ] **OCR** auto-fill data
- [ ] **Simpan SIM** berhasil
- [ ] **List SIM** muncul di home
- [ ] **Detail SIM** bisa dibuka
- [ ] **Delete SIM** berhasil
- [ ] **Notifikasi** permission diminta

## 📁 File Penting

| File | Lokasi | Fungsi |
|------|--------|--------|
| `google-services.json` | `android/app/` | Android Firebase config |
| `GoogleService-Info.plist` | `ios/Runner/` | iOS Firebase config |
| `main.dart` | `lib/` | Entry point aplikasi |
| `pubspec.yaml` | Root | Dependencies |

## 🔧 Common Issues

### "SHA-1 fingerprint" diperlukan
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
Copy SHA-1 → tambahkan di Firebase Console

### Google Sign-In Error
1. Re-download `google-services.json`
2. Verify package name: `com.reminderapp.sim_reminder`
3. Clean & rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

### Build Error
```bash
# Clean project
flutter clean
rm -rf ios/Pods
cd ios && pod install && cd ..
flutter pub get
flutter run
```

## 📱 Build APK/IPA

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS IPA
```bash
flutter build ios --release
# Buka Xcode untuk archive & export
```

## 🎨 Struktur Code

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
├── services/              # Business logic
├── providers/             # State management
├── screens/               # UI screens
├── widgets/               # Reusable widgets
└── utils/                 # Helpers & themes
```

## 📞 Need Help?

- 📖 Full Documentation: [README.md](README.md)
- 🔥 Firebase Setup: [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- 🐛 Issues: Open GitHub issue

## ✅ Next Steps

1. ✅ Setup Firebase
2. ✅ Test semua fitur
3. ✅ Customize theme (optional)
4. ✅ Add fonts (optional)
5. ✅ Build release version
6. ✅ Deploy to Play Store / App Store

Happy Coding! 🎉
