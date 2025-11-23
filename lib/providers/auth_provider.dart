import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

/// Provider untuk menangani autentikasi
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final LocalStorageService _localStorage = LocalStorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;

  /// Initialize auth provider
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check Firebase auth state
      final firebaseUser = _authService.currentUser;

      if (firebaseUser != null) {
        if (firebaseUser.isAnonymous) {
          // Guest user
          _currentUser = UserModel(
            uid: firebaseUser.uid,
            displayName: 'Pengguna Tamu',
            isGuest: true,
            createdAt: DateTime.now(),
          );
        } else {
          // Authenticated user - get from Firestore
          _currentUser = await _authService.getUserFromFirestore(firebaseUser.uid);

          // If not found in Firestore, create from Firebase user
          if (_currentUser == null) {
            _currentUser = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email,
              displayName: firebaseUser.displayName,
              photoUrl: firebaseUser.photoURL,
              isGuest: false,
              createdAt: DateTime.now(),
              lastLogin: DateTime.now(),
            );
          }
        }

        // Save to local storage
        await _localStorage.saveUser(_currentUser!);
      } else {
        // Check local storage
        _currentUser = await _localStorage.getUser();
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('Error initialize auth: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Sign in dengan Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signInWithGoogle();

      if (user != null) {
        _currentUser = user;
        await _localStorage.saveUser(user);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error sign in dengan Google: $e');
      _isLoading = false;
      _errorMessage = 'Gagal masuk dengan Google. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Sign in sebagai guest
  Future<bool> signInAsGuest() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signInAsGuest();

      if (user != null) {
        _currentUser = user;
        await _localStorage.saveUser(user);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error sign in sebagai guest: $e');
      _isLoading = false;
      _errorMessage = 'Gagal masuk sebagai tamu. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Convert guest ke Google account
  Future<bool> convertGuestToGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.convertGuestToGoogleAccount();

      if (user != null) {
        _currentUser = user;
        await _localStorage.saveUser(user);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error convert guest to Google: $e');
      _isLoading = false;
      _errorMessage = 'Gagal mengubah akun. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Update notification setting
  Future<void> updateNotificationSetting(bool enabled) async {
    try {
      if (_currentUser != null) {
        // Update di Firestore jika bukan guest
        if (!_currentUser!.isGuest) {
          await _authService.updateNotificationSettings(_currentUser!.uid, enabled);
        }

        // Update di local storage
        await _localStorage.saveNotificationSetting(enabled);

        // Update current user
        _currentUser = _currentUser!.copyWith(notificationsEnabled: enabled);
        await _localStorage.saveUser(_currentUser!);

        notifyListeners();
      }
    } catch (e) {
      print('Error update notification setting: $e');
      _errorMessage = 'Gagal update pengaturan notifikasi.';
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Jika guest, hapus data lokal
      if (_currentUser?.isGuest == true) {
        await _localStorage.clearAllData();
        await _authService.deleteGuestAccount();
      } else {
        // Jika authenticated user, hanya hapus user dari local storage
        await _localStorage.deleteUser();
      }

      await _authService.signOut();

      _currentUser = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('Error sign out: $e');
      _isLoading = false;
      _errorMessage = 'Gagal keluar. Silakan coba lagi.';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
