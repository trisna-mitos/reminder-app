import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/license_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/ocr_service.dart';

/// Provider untuk menangani license management
class LicenseProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  final LocalStorageService _localStorage = LocalStorageService();
  final NotificationService _notificationService = NotificationService();
  final OcrService _ocrService = OcrService();

  List<LicenseModel> _licenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Uuid _uuid = const Uuid();

  List<LicenseModel> get licenses => _licenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get licenses yang akan kadaluarsa
  List<LicenseModel> get expiringSoonLicenses {
    return _licenses.where((license) => license.isExpiringSoon).toList();
  }

  /// Get licenses yang sudah kadaluarsa
  List<LicenseModel> get expiredLicenses {
    return _licenses.where((license) => license.isExpired).toList();
  }

  /// Get licenses yang masih valid
  List<LicenseModel> get activeLicenses {
    return _licenses.where((license) => !license.isExpired).toList();
  }

  /// Load licenses untuk user (dari Firestore atau local storage)
  Future<void> loadLicenses({
    required String userId,
    required bool isGuest,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (isGuest) {
        // Load dari local storage
        _licenses = await _localStorage.getAllLicenses();
      } else {
        // Load dari Firestore
        _databaseService.getLicenses(userId).listen((licenses) {
          _licenses = licenses;
          notifyListeners();
        });
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('Error load licenses: $e');
      _isLoading = false;
      _errorMessage = 'Gagal memuat data SIM.';
      notifyListeners();
    }
  }

  /// Extract data dari foto menggunakan OCR
  Future<Map<String, String?>> extractDataFromPhoto(File photoFile) async {
    try {
      return await _ocrService.extractLicenseData(photoFile);
    } catch (e) {
      print('Error extract data from photo: $e');
      return {
        'licenseNumber': null,
        'licenseType': null,
        'ownerName': null,
        'expirationDate': null,
      };
    }
  }

  /// Add license baru
  Future<bool> addLicense({
    required String userId,
    required bool isGuest,
    required String licenseNumber,
    required String licenseType,
    required String ownerName,
    required DateTime expirationDate,
    File? photoFile,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String? photoUrl;

      // Upload foto
      if (photoFile != null) {
        if (isGuest) {
          // Simpan ke local storage
          final licenseId = _uuid.v4();
          photoUrl = await _localStorage.savePhotoLocally(photoFile, licenseId);
        } else {
          // Upload ke Firebase Storage
          photoUrl = await _storageService.uploadLicensePhoto(
            userId: userId,
            imageFile: photoFile,
          );
        }
      }

      // Create license model
      final license = LicenseModel(
        id: _uuid.v4(),
        licenseNumber: licenseNumber,
        licenseType: licenseType,
        ownerName: ownerName,
        expirationDate: expirationDate,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      // Save license
      if (isGuest) {
        await _localStorage.saveLicense(license);
        _licenses.add(license);
        _licenses.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
      } else {
        final docId = await _databaseService.addLicense(
          userId: userId,
          license: license,
        );
        // License akan otomatis muncul di stream
      }

      // Schedule notification
      await _notificationService.scheduleLicenseReminder(license);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error add license: $e');
      _isLoading = false;
      _errorMessage = 'Gagal menambahkan SIM. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Update license
  Future<bool> updateLicense({
    required String userId,
    required bool isGuest,
    required String licenseId,
    required String licenseNumber,
    required String licenseType,
    required String ownerName,
    required DateTime expirationDate,
    File? newPhotoFile,
    String? currentPhotoUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String? photoUrl = currentPhotoUrl;

      // Upload foto baru jika ada
      if (newPhotoFile != null) {
        if (isGuest) {
          // Hapus foto lama
          if (currentPhotoUrl != null) {
            await _localStorage.deleteLocalPhoto(currentPhotoUrl);
          }
          // Simpan foto baru
          photoUrl = await _localStorage.savePhotoLocally(newPhotoFile, licenseId);
        } else {
          // Upload ke Firebase Storage
          photoUrl = await _storageService.uploadLicensePhoto(
            userId: userId,
            imageFile: newPhotoFile,
            oldPhotoUrl: currentPhotoUrl,
          );
        }
      }

      // Update data
      if (isGuest) {
        final license = await _localStorage.getLicenseById(licenseId);
        if (license != null) {
          final updatedLicense = license.copyWith(
            licenseNumber: licenseNumber,
            licenseType: licenseType,
            ownerName: ownerName,
            expirationDate: expirationDate,
            photoUrl: photoUrl,
            updatedAt: DateTime.now(),
          );
          await _localStorage.updateLicense(updatedLicense);

          // Update in list
          final index = _licenses.indexWhere((l) => l.id == licenseId);
          if (index != -1) {
            _licenses[index] = updatedLicense;
            _licenses.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
          }

          // Update notification
          await _notificationService.scheduleLicenseReminder(updatedLicense);
        }
      } else {
        await _databaseService.updateLicense(
          userId: userId,
          licenseId: licenseId,
          data: {
            'licenseNumber': licenseNumber,
            'licenseType': licenseType,
            'ownerName': ownerName,
            'expirationDate': expirationDate,
            'photoUrl': photoUrl,
          },
        );

        // Get updated license for notification
        final updatedLicense = await _databaseService.getLicenseById(
          userId: userId,
          licenseId: licenseId,
        );
        if (updatedLicense != null) {
          await _notificationService.scheduleLicenseReminder(updatedLicense);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error update license: $e');
      _isLoading = false;
      _errorMessage = 'Gagal mengubah SIM. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Delete license
  Future<bool> deleteLicense({
    required String userId,
    required bool isGuest,
    required String licenseId,
    String? photoUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Hapus foto
      if (photoUrl != null) {
        if (isGuest) {
          await _localStorage.deleteLocalPhoto(photoUrl);
        } else {
          await _storageService.deletePhotoFromUrl(photoUrl);
        }
      }

      // Hapus license
      if (isGuest) {
        await _localStorage.deleteLicense(licenseId);
        _licenses.removeWhere((l) => l.id == licenseId);
      } else {
        await _databaseService.deleteLicense(
          userId: userId,
          licenseId: licenseId,
        );
      }

      // Cancel notifications
      await _notificationService.cancelLicenseReminder(licenseId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error delete license: $e');
      _isLoading = false;
      _errorMessage = 'Gagal menghapus SIM. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Get license by ID
  LicenseModel? getLicenseById(String id) {
    try {
      return _licenses.firstWhere((license) => license.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Dispose
  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
