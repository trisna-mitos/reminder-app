import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service untuk menangani upload dan download file dari Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Upload foto SIM dan return URL-nya
  Future<String> uploadLicensePhoto({
    required String userId,
    required File imageFile,
    String? oldPhotoUrl,
  }) async {
    try {
      // Compress image sebelum upload
      final compressedFile = await _compressImage(imageFile);

      // Generate nama file unik
      final fileName = '${_uuid.v4()}.jpg';
      final path = 'licenses/$userId/$fileName';

      // Upload ke Firebase Storage
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(compressedFile);

      // Dapatkan download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Hapus file lama jika ada
      if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
        await deletePhotoFromUrl(oldPhotoUrl);
      }

      // Hapus file compressed temporary
      await compressedFile.delete();

      return downloadUrl;
    } catch (e) {
      print('Error saat upload foto: $e');
      rethrow;
    }
  }

  /// Compress image sebelum upload (maksimal 1MB)
  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${_uuid.v4()}.jpg';

      // Compress dengan quality 80% dan max width 1920px
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (result == null) {
        throw Exception('Gagal compress image');
      }

      return File(result.path);
    } catch (e) {
      print('Error saat compress image: $e');
      // Jika gagal compress, return file original
      return file;
    }
  }

  /// Hapus foto dari URL
  Future<void> deletePhotoFromUrl(String photoUrl) async {
    try {
      // Extract path dari URL
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      print('Error saat hapus foto: $e');
      // Tidak throw error karena file mungkin sudah dihapus
    }
  }

  /// Hapus foto berdasarkan path
  Future<void> deletePhotoFromPath(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      print('Error saat hapus foto by path: $e');
    }
  }

  /// Hapus semua foto user
  Future<void> deleteAllUserPhotos(String userId) async {
    try {
      final ref = _storage.ref().child('licenses/$userId');
      final listResult = await ref.listAll();

      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      print('Error saat hapus semua foto user: $e');
    }
  }

  /// Download foto ke local storage untuk offline access
  Future<File?> downloadPhotoToLocal(String photoUrl) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = photoUrl.split('/').last.split('?').first;
      final file = File('${dir.path}/$fileName');

      // Download file
      final ref = _storage.refFromURL(photoUrl);
      await ref.writeToFile(file);

      return file;
    } catch (e) {
      print('Error saat download foto: $e');
      return null;
    }
  }

  /// Mendapatkan ukuran file
  Future<int> getFileSize(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      print('Error saat get file size: $e');
      return 0;
    }
  }

  /// Check apakah file ada di storage
  Future<bool> photoExists(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }
}
