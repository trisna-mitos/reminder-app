import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/license_model.dart';
import '../models/user_model.dart';

/// Service untuk menangani local storage (untuk guest mode)
class LocalStorageService {
  static const String _licensesBoxName = 'licenses';
  static const String _userBoxName = 'user';
  static const String _settingsBoxName = 'settings';

  /// Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  /// Open semua boxes
  Future<void> openBoxes() async {
    await Hive.openBox(_licensesBoxName);
    await Hive.openBox(_userBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  /// Close semua boxes
  Future<void> closeBoxes() async {
    await Hive.box(_licensesBoxName).close();
    await Hive.box(_userBoxName).close();
    await Hive.box(_settingsBoxName).close();
  }

  // ========== LICENSE OPERATIONS ==========

  /// Simpan license ke local storage
  Future<void> saveLicense(LicenseModel license) async {
    try {
      final box = Hive.box(_licensesBoxName);
      await box.put(license.id, jsonEncode(license.toJson()));
    } catch (e) {
      print('Error saat menyimpan license ke local: $e');
      rethrow;
    }
  }

  /// Mendapatkan semua licenses dari local storage
  Future<List<LicenseModel>> getAllLicenses() async {
    try {
      final box = Hive.box(_licensesBoxName);
      final licenses = <LicenseModel>[];

      for (var key in box.keys) {
        final jsonString = box.get(key) as String;
        final license = LicenseModel.fromJson(jsonDecode(jsonString));
        licenses.add(license);
      }

      // Sort by expiration date
      licenses.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

      return licenses;
    } catch (e) {
      print('Error saat mengambil licenses dari local: $e');
      return [];
    }
  }

  /// Mendapatkan license berdasarkan ID
  Future<LicenseModel?> getLicenseById(String id) async {
    try {
      final box = Hive.box(_licensesBoxName);
      final jsonString = box.get(id) as String?;

      if (jsonString != null) {
        return LicenseModel.fromJson(jsonDecode(jsonString));
      }

      return null;
    } catch (e) {
      print('Error saat mengambil license by ID dari local: $e');
      return null;
    }
  }

  /// Update license di local storage
  Future<void> updateLicense(LicenseModel license) async {
    try {
      final box = Hive.box(_licensesBoxName);
      final updatedLicense = license.copyWith(updatedAt: DateTime.now());
      await box.put(updatedLicense.id, jsonEncode(updatedLicense.toJson()));
    } catch (e) {
      print('Error saat update license di local: $e');
      rethrow;
    }
  }

  /// Hapus license dari local storage
  Future<void> deleteLicense(String id) async {
    try {
      final box = Hive.box(_licensesBoxName);
      await box.delete(id);
    } catch (e) {
      print('Error saat hapus license dari local: $e');
      rethrow;
    }
  }

  /// Hapus semua licenses
  Future<void> deleteAllLicenses() async {
    try {
      final box = Hive.box(_licensesBoxName);
      await box.clear();
    } catch (e) {
      print('Error saat hapus semua licenses dari local: $e');
      rethrow;
    }
  }

  /// Mendapatkan jumlah licenses
  Future<int> getLicenseCount() async {
    try {
      final box = Hive.box(_licensesBoxName);
      return box.length;
    } catch (e) {
      print('Error saat menghitung licenses: $e');
      return 0;
    }
  }

  // ========== USER OPERATIONS ==========

  /// Simpan user data
  Future<void> saveUser(UserModel user) async {
    try {
      final box = Hive.box(_userBoxName);
      await box.put('current_user', jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saat menyimpan user ke local: $e');
      rethrow;
    }
  }

  /// Mendapatkan user data
  Future<UserModel?> getUser() async {
    try {
      final box = Hive.box(_userBoxName);
      final jsonString = box.get('current_user') as String?;

      if (jsonString != null) {
        return UserModel.fromJson(jsonDecode(jsonString));
      }

      return null;
    } catch (e) {
      print('Error saat mengambil user dari local: $e');
      return null;
    }
  }

  /// Hapus user data
  Future<void> deleteUser() async {
    try {
      final box = Hive.box(_userBoxName);
      await box.delete('current_user');
    } catch (e) {
      print('Error saat hapus user dari local: $e');
      rethrow;
    }
  }

  // ========== SETTINGS OPERATIONS ==========

  /// Simpan notification setting
  Future<void> saveNotificationSetting(bool enabled) async {
    try {
      final box = Hive.box(_settingsBoxName);
      await box.put('notifications_enabled', enabled);
    } catch (e) {
      print('Error saat menyimpan notification setting: $e');
      rethrow;
    }
  }

  /// Mendapatkan notification setting
  Future<bool> getNotificationSetting() async {
    try {
      final box = Hive.box(_settingsBoxName);
      return box.get('notifications_enabled', defaultValue: true) as bool;
    } catch (e) {
      print('Error saat mengambil notification setting: $e');
      return true;
    }
  }

  /// Simpan onboarding status
  Future<void> saveOnboardingCompleted(bool completed) async {
    try {
      final box = Hive.box(_settingsBoxName);
      await box.put('onboarding_completed', completed);
    } catch (e) {
      print('Error saat menyimpan onboarding status: $e');
      rethrow;
    }
  }

  /// Check apakah onboarding sudah selesai
  Future<bool> isOnboardingCompleted() async {
    try {
      final box = Hive.box(_settingsBoxName);
      return box.get('onboarding_completed', defaultValue: false) as bool;
    } catch (e) {
      print('Error saat check onboarding status: $e');
      return false;
    }
  }

  // ========== LOCAL PHOTO STORAGE ==========

  /// Simpan foto ke local directory
  Future<String> savePhotoLocally(File photoFile, String licenseId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${directory.path}/license_photos');

      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      final fileName = '${licenseId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await photoFile.copy('${photoDir.path}/$fileName');

      return savedFile.path;
    } catch (e) {
      print('Error saat menyimpan foto locally: $e');
      rethrow;
    }
  }

  /// Hapus foto dari local directory
  Future<void> deleteLocalPhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error saat hapus foto local: $e');
    }
  }

  /// Hapus semua foto local
  Future<void> deleteAllLocalPhotos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${directory.path}/license_photos');

      if (await photoDir.exists()) {
        await photoDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error saat hapus semua foto local: $e');
    }
  }

  // ========== CLEAR ALL DATA ==========

  /// Hapus semua data local (untuk logout guest)
  Future<void> clearAllData() async {
    try {
      await deleteAllLicenses();
      await deleteUser();
      await deleteAllLocalPhotos();
      // Keep settings untuk preferences
    } catch (e) {
      print('Error saat clear all data: $e');
      rethrow;
    }
  }
}
