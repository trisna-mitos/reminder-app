import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

/// Service untuk menangani autentikasi pengguna
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream untuk mendengarkan perubahan status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Mendapatkan user yang sedang login
  User? get currentUser => _auth.currentUser;

  /// Sign in dengan Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User membatalkan sign-in
        return null;
      }

      // Mendapatkan auth details dari request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Membuat credential untuk Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in ke Firebase dengan credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Membuat atau update data user di Firestore
      if (userCredential.user != null) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
          isGuest: false,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          notificationsEnabled: true,
        );

        // Simpan atau update user di Firestore
        await _saveUserToFirestore(userModel);

        return userModel;
      }

      return null;
    } catch (e) {
      print('Error saat sign in dengan Google: $e');
      rethrow;
    }
  }

  /// Masuk sebagai guest (tanpa autentikasi)
  Future<UserModel?> signInAsGuest() async {
    try {
      // Sign in anonymous di Firebase
      final UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: null,
          displayName: 'Pengguna Tamu',
          photoUrl: null,
          isGuest: true,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          notificationsEnabled: true,
        );

        return userModel;
      }

      return null;
    } catch (e) {
      print('Error saat sign in sebagai guest: $e');
      rethrow;
    }
  }

  /// Simpan data user ke Firestore
  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        // Update last login jika user sudah ada
        await userDoc.update({
          'lastLogin': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Buat user baru jika belum ada
        await userDoc.set(user.toMap());
      }
    } catch (e) {
      print('Error saat menyimpan user ke Firestore: $e');
      rethrow;
    }
  }

  /// Mendapatkan data user dari Firestore
  Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        return UserModel.fromMap(userDoc.data()!);
      }

      return null;
    } catch (e) {
      print('Error saat mengambil user dari Firestore: $e');
      return null;
    }
  }

  /// Update setting notifikasi user
  Future<void> updateNotificationSettings(String uid, bool enabled) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'notificationsEnabled': enabled,
      });
    } catch (e) {
      print('Error saat update setting notifikasi: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out dari Google jika user login dengan Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out dari Firebase
      await _auth.signOut();
    } catch (e) {
      print('Error saat sign out: $e');
      rethrow;
    }
  }

  /// Convert guest account ke akun Google
  Future<UserModel?> convertGuestToGoogleAccount() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null || !currentUser.isAnonymous) {
        throw Exception('User bukan guest atau tidak login');
      }

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link anonymous account dengan Google credential
      final UserCredential userCredential =
          await currentUser.linkWithCredential(credential);

      if (userCredential.user != null) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
          isGuest: false,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          notificationsEnabled: true,
        );

        await _saveUserToFirestore(userModel);

        return userModel;
      }

      return null;
    } catch (e) {
      print('Error saat convert guest ke Google account: $e');
      rethrow;
    }
  }

  /// Delete akun guest dan semua datanya
  Future<void> deleteGuestAccount() async {
    try {
      final user = _auth.currentUser;

      if (user != null && user.isAnonymous) {
        await user.delete();
      }
    } catch (e) {
      print('Error saat menghapus akun guest: $e');
      rethrow;
    }
  }
}
