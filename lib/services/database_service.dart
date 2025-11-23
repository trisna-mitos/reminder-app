import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/license_model.dart';

/// Service untuk menangani operasi database Firestore
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mendapatkan referensi koleksi licenses untuk user tertentu
  CollectionReference _licensesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('licenses');
  }

  /// Menambahkan license baru
  Future<String> addLicense({
    required String userId,
    required LicenseModel license,
  }) async {
    try {
      final docRef = await _licensesCollection(userId).add(license.toMap());
      return docRef.id;
    } catch (e) {
      print('Error saat menambahkan license: $e');
      rethrow;
    }
  }

  /// Mendapatkan semua licenses milik user
  Stream<List<LicenseModel>> getLicenses(String userId) {
    try {
      return _licensesCollection(userId)
          .orderBy('expirationDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return LicenseModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      print('Error saat mengambil licenses: $e');
      rethrow;
    }
  }

  /// Mendapatkan single license berdasarkan ID
  Future<LicenseModel?> getLicenseById({
    required String userId,
    required String licenseId,
  }) async {
    try {
      final doc = await _licensesCollection(userId).doc(licenseId).get();

      if (doc.exists && doc.data() != null) {
        return LicenseModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }

      return null;
    } catch (e) {
      print('Error saat mengambil license by ID: $e');
      return null;
    }
  }

  /// Update license
  Future<void> updateLicense({
    required String userId,
    required String licenseId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Tambahkan timestamp update
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _licensesCollection(userId).doc(licenseId).update(data);
    } catch (e) {
      print('Error saat update license: $e');
      rethrow;
    }
  }

  /// Update seluruh license
  Future<void> replaceLicense({
    required String userId,
    required String licenseId,
    required LicenseModel license,
  }) async {
    try {
      final updatedLicense = license.copyWith(
        updatedAt: DateTime.now(),
      );

      await _licensesCollection(userId)
          .doc(licenseId)
          .set(updatedLicense.toMap());
    } catch (e) {
      print('Error saat replace license: $e');
      rethrow;
    }
  }

  /// Hapus license
  Future<void> deleteLicense({
    required String userId,
    required String licenseId,
  }) async {
    try {
      await _licensesCollection(userId).doc(licenseId).delete();
    } catch (e) {
      print('Error saat menghapus license: $e');
      rethrow;
    }
  }

  /// Mendapatkan licenses yang akan kadaluarsa (dalam 7 hari)
  Stream<List<LicenseModel>> getExpiringSoonLicenses(String userId) {
    try {
      final now = DateTime.now();
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      return _licensesCollection(userId)
          .where('expirationDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('expirationDate',
              isLessThanOrEqualTo: Timestamp.fromDate(sevenDaysFromNow))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return LicenseModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      print('Error saat mengambil expiring licenses: $e');
      rethrow;
    }
  }

  /// Mendapatkan licenses yang sudah kadaluarsa
  Stream<List<LicenseModel>> getExpiredLicenses(String userId) {
    try {
      final now = DateTime.now();

      return _licensesCollection(userId)
          .where('expirationDate', isLessThan: Timestamp.fromDate(now))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return LicenseModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      print('Error saat mengambil expired licenses: $e');
      rethrow;
    }
  }

  /// Mendapatkan jumlah total licenses
  Future<int> getLicenseCount(String userId) async {
    try {
      final snapshot = await _licensesCollection(userId).get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error saat menghitung license: $e');
      return 0;
    }
  }

  /// Hapus semua licenses user (untuk guest yang logout)
  Future<void> deleteAllUserLicenses(String userId) async {
    try {
      final snapshot = await _licensesCollection(userId).get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error saat menghapus semua licenses: $e');
      rethrow;
    }
  }

  /// Batch update licenses (untuk migrasi data guest ke akun Google)
  Future<void> batchUpdateLicenses({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final snapshot = await _licensesCollection(fromUserId).get();

      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        // Tambahkan ke user baru
        final newDocRef = _licensesCollection(toUserId).doc();
        batch.set(newDocRef, doc.data());

        // Hapus dari user lama
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error saat batch update licenses: $e');
      rethrow;
    }
  }
}
