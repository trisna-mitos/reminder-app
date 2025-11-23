# 🔥 Firebase Setup Guide Lengkap

Panduan lengkap untuk setup Firebase untuk aplikasi SIM Reminder.

## 📋 Daftar Isi
1. [Buat Firebase Project](#1-buat-firebase-project)
2. [Setup Android](#2-setup-android)
3. [Setup iOS](#3-setup-ios)
4. [Firebase Authentication](#4-firebase-authentication)
5. [Cloud Firestore](#5-cloud-firestore)
6. [Firebase Storage](#6-firebase-storage)
7. [Firebase Cloud Messaging](#7-firebase-cloud-messaging)
8. [Google Sign-In](#8-google-sign-in)

---

## 1. Buat Firebase Project

### Langkah-langkah:

1. **Buka Firebase Console**
   - Kunjungi https://console.firebase.google.com/
   - Login dengan akun Google

2. **Create New Project**
   - Klik "Add project" atau "Tambah project"
   - Project name: `SIM Reminder` (atau nama lain)
   - Klik "Continue"

3. **Google Analytics** (Optional)
   - Enable/disable Google Analytics sesuai kebutuhan
   - Jika enable, pilih atau buat Analytics account
   - Klik "Create project"

4. **Tunggu Project Selesai Dibuat**
   - Proses biasanya 1-2 menit
   - Klik "Continue" setelah selesai

---

## 2. Setup Android

### Langkah A: Register Android App

1. **Tambah Android App**
   - Di Firebase Console, klik icon Android (robot hijau)
   - Atau klik "Add app" → pilih Android

2. **Package Name**
   - Package name: `com.reminderapp.sim_reminder`
   - **PENTING**: Harus sama persis dengan package di `android/app/build.gradle`

3. **App Nickname** (Optional)
   - Nickname: "SIM Reminder Android"

4. **SHA-1** (Diperlukan untuk Google Sign-In)
   - Buka terminal
   - Jalankan command:
   ```bash
   # Untuk debug key
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   - Copy SHA-1 fingerprint
   - Paste di field SHA-1

5. **Register App**
   - Klik "Register app"

### Langkah B: Download Config File

1. **Download google-services.json**
   - Klik "Download google-services.json"
   - File akan ter-download

2. **Letakkan File di Project**
   - Copy file `google-services.json`
   - Paste ke folder: `android/app/`
   - Path lengkap: `android/app/google-services.json`

3. **JANGAN commit google-services.json ke Git**
   - Tambahkan ke `.gitignore`:
   ```
   android/app/google-services.json
   ```

### Langkah C: Verify Setup

File yang sudah ada di project:
- ✅ `android/app/build.gradle` - sudah ada Google Services plugin
- ✅ `android/build.gradle` - sudah ada classpath
- ✅ `android/app/src/main/AndroidManifest.xml` - permissions sudah ada

---

## 3. Setup iOS

### Langkah A: Register iOS App

1. **Tambah iOS App**
   - Di Firebase Console, klik icon iOS (Apple)
   - Atau klik "Add app" → pilih iOS

2. **Bundle ID**
   - Bundle ID: `com.reminderapp.simReminder`
   - **PENTING**: Harus sama dengan Bundle Identifier di Xcode

3. **App Nickname** (Optional)
   - Nickname: "SIM Reminder iOS"

4. **App Store ID** (Optional)
   - Kosongkan untuk development

5. **Register App**
   - Klik "Register app"

### Langkah B: Download Config File

1. **Download GoogleService-Info.plist**
   - Klik "Download GoogleService-Info.plist"

2. **Letakkan File di Project**
   - Buka Xcode
   - Buka `ios/Runner.xcworkspace`
   - Drag & drop `GoogleService-Info.plist` ke project Runner
   - **CENTANG**: "Copy items if needed"
   - **CENTANG**: Target "Runner"

3. **JANGAN commit GoogleService-Info.plist ke Git**
   - Tambahkan ke `.gitignore`:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

### Langkah C: Setup di Xcode

1. **Buka Xcode**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Update Bundle Identifier**
   - Pilih project "Runner" di sidebar
   - Pilih target "Runner"
   - Tab "General"
   - Bundle Identifier: `com.reminderapp.simReminder`

3. **Add Capabilities**
   - Tab "Signing & Capabilities"
   - Klik "+ Capability"
   - Tambahkan:
     - ✅ Push Notifications
     - ✅ Background Modes
       - Centang: Remote notifications
       - Centang: Background fetch

---

## 4. Firebase Authentication

### Setup Google Sign-In

1. **Aktifkan Authentication**
   - Di Firebase Console
   - Build → Authentication
   - Klik "Get started"

2. **Enable Google Provider**
   - Tab "Sign-in method"
   - Klik "Google"
   - Toggle "Enable"
   - Project public-facing name: "SIM Reminder"
   - Support email: (email Anda)
   - Klik "Save"

3. **Enable Anonymous Provider** (untuk Guest mode)
   - Tab "Sign-in method"
   - Klik "Anonymous"
   - Toggle "Enable"
   - Klik "Save"

### Setup Google Cloud Console

1. **Buka Google Cloud Console**
   - https://console.cloud.google.com/
   - Pilih project Firebase Anda

2. **Enable Google Sign-In API**
   - Navigation menu → APIs & Services → Library
   - Search: "Google Sign-In API"
   - Klik → Enable

3. **Buat OAuth 2.0 Credentials**

   **Android OAuth:**
   - APIs & Services → Credentials
   - Create Credentials → OAuth 2.0 Client ID
   - Application type: Android
   - Name: "SIM Reminder Android"
   - Package name: `com.reminderapp.sim_reminder`
   - SHA-1: (paste SHA-1 fingerprint)
   - Klik "Create"

   **iOS OAuth:**
   - Create Credentials → OAuth 2.0 Client ID
   - Application type: iOS
   - Name: "SIM Reminder iOS"
   - Bundle ID: `com.reminderapp.simReminder`
   - Klik "Create"

4. **Update iOS Info.plist**
   - Copy iOS Client ID
   - Buka `ios/Runner/Info.plist`
   - Cari: `com.googleusercontent.apps.YOUR-CLIENT-ID`
   - Ganti `YOUR-CLIENT-ID` dengan Client ID (tanpa `.apps.googleusercontent.com`)

---

## 5. Cloud Firestore

### Setup Database

1. **Buat Firestore Database**
   - Build → Firestore Database
   - Klik "Create database"

2. **Security Rules**
   - Pilih "Start in production mode"
   - Klik "Next"

3. **Location**
   - Pilih: `asia-southeast2 (Jakarta)`
   - Atau region terdekat
   - Klik "Enable"

### Setup Security Rules

1. **Di Firestore Console**
   - Tab "Rules"
   - Replace dengan rules berikut:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isSignedIn();
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);

      // Licenses subcollection
      match /licenses/{licenseId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId);
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
      }
    }
  }
}
```

2. **Publish Rules**
   - Klik "Publish"

### Setup Indexes (Optional)

Indexes akan auto-generate saat query pertama dijalankan.

---

## 6. Firebase Storage

### Setup Storage

1. **Buat Storage**
   - Build → Storage
   - Klik "Get started"

2. **Security Rules**
   - Start in production mode
   - Klik "Next"

3. **Location**
   - Pilih sama dengan Firestore: `asia-southeast2`
   - Klik "Done"

### Setup Security Rules

1. **Di Storage Console**
   - Tab "Rules"
   - Replace dengan rules berikut:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // License photos
    match /licenses/{userId}/{fileName} {
      // Allow read if signed in and is owner
      allow read: if isOwner(userId);

      // Allow write if signed in and is owner
      // File size max 10MB
      // Only images
      allow write: if isOwner(userId)
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');

      // Allow delete if owner
      allow delete: if isOwner(userId);
    }
  }
}
```

2. **Publish Rules**
   - Klik "Publish"

---

## 7. Firebase Cloud Messaging

### Android Setup

1. **FCM Sudah Auto-Configured**
   - File `google-services.json` sudah include FCM config
   - AndroidManifest.xml sudah include FCM service

2. **Test FCM**
   - Build → Cloud Messaging
   - Klik "Send your first message"
   - Test dengan device/emulator yang running

### iOS Setup

1. **Upload APNs Key** (Production only)
   - Perlu Apple Developer Account
   - Project Settings → Cloud Messaging tab
   - Upload APNs authentication key

2. **Development Mode**
   - FCM works dengan APNs development certificate
   - Auto-configured oleh Xcode

---

## 8. Google Sign-In

### Verify Setup

Checklist yang harus sudah selesai:

#### Android
- ✅ SHA-1 fingerprint ditambahkan di Firebase
- ✅ OAuth 2.0 Client ID untuk Android dibuat
- ✅ Package name: `com.reminderapp.sim_reminder`
- ✅ `google-services.json` di `android/app/`

#### iOS
- ✅ Bundle ID: `com.reminderapp.simReminder`
- ✅ OAuth 2.0 Client ID untuk iOS dibuat
- ✅ Client ID di `Info.plist` sudah update
- ✅ `GoogleService-Info.plist` di Xcode project

### Test Google Sign-In

```bash
flutter run
```

1. Tap "Masuk dengan Google"
2. Pilih akun Google
3. Harus berhasil login dan redirect ke Home

Jika error:
- Check SHA-1 fingerprint
- Re-download `google-services.json`
- Verify package name/bundle ID
- Check Client ID di Info.plist

---

## ✅ Checklist Final

Sebelum production:

### Firebase Console
- ✅ Authentication enabled (Google + Anonymous)
- ✅ Firestore database created dengan rules
- ✅ Storage created dengan rules
- ✅ FCM configured

### Android
- ✅ `google-services.json` tersedia
- ✅ SHA-1 registered
- ✅ OAuth Client ID created

### iOS
- ✅ `GoogleService-Info.plist` tersedia
- ✅ Bundle ID configured
- ✅ OAuth Client ID created
- ✅ Info.plist updated dengan Client ID
- ✅ Push Notifications capability added

### Test
- ✅ Google Sign-In works
- ✅ Guest mode works
- ✅ Add license works
- ✅ Photo upload works
- ✅ Notifications works

---

## 🆘 Troubleshooting

### Error: "Google Sign-In failed"
**Solusi:**
1. Verify SHA-1 fingerprint di Firebase Console
2. Re-download `google-services.json`
3. Clean & rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Error: "Firestore permission denied"
**Solusi:**
1. Check Firestore rules
2. Verify user authenticated
3. Check user ID match dengan document path

### Error: "Storage upload failed"
**Solusi:**
1. Check Storage rules
2. Verify file size < 10MB
3. Check file type is image

### Error: "Notifications not showing"
**Solusi:**
1. Check notification permissions di device settings
2. Verify FCM token generated
3. Test dengan foreground notification first

---

## 📞 Support

Jika masih ada masalah:
- Check official Firebase docs: https://firebase.google.com/docs
- Flutter Fire docs: https://firebase.flutter.dev/
