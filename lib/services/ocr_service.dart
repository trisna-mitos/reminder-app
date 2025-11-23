import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

/// Service untuk OCR (Optical Character Recognition) menggunakan ML Kit
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Ekstrak text dari image
  Future<RecognizedText> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText;
    } catch (e) {
      print('Error saat recognize text: $e');
      rethrow;
    }
  }

  /// Extract data SIM dari recognized text
  Future<Map<String, String?>> extractLicenseData(File imageFile) async {
    try {
      final recognizedText = await recognizeText(imageFile);
      final text = recognizedText.text;

      return {
        'licenseNumber': _extractLicenseNumber(text),
        'licenseType': _extractLicenseType(text),
        'ownerName': _extractOwnerName(text),
        'expirationDate': _extractExpirationDate(text),
      };
    } catch (e) {
      print('Error saat extract license data: $e');
      return {
        'licenseNumber': null,
        'licenseType': null,
        'ownerName': null,
        'expirationDate': null,
      };
    }
  }

  /// Extract nomor SIM
  /// Format: 1234-5678-901234 atau 12345678901234
  String? _extractLicenseNumber(String text) {
    try {
      // Pattern untuk nomor SIM Indonesia
      // Format: 4 digit - 4 digit - 6 digit atau 14 digit berurutan
      final patterns = [
        RegExp(r'\d{4}[-\s]?\d{4}[-\s]?\d{6}'),
        RegExp(r'\b\d{14}\b'),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          return match.group(0)?.replaceAll(RegExp(r'[\s-]'), '');
        }
      }

      return null;
    } catch (e) {
      print('Error saat extract license number: $e');
      return null;
    }
  }

  /// Extract tipe SIM (SIM A, SIM B, SIM C)
  String? _extractLicenseType(String text) {
    try {
      final upperText = text.toUpperCase();

      // Cari pattern "SIM A", "SIM B", "SIM C"
      final patterns = [
        RegExp(r'SIM\s*[ABC]'),
        RegExp(r'\b[ABC]\b'), // Single letter A, B, or C
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(upperText);
        if (match != null) {
          final matchText = match.group(0)!;
          if (matchText.contains('A')) return 'SIM A';
          if (matchText.contains('B')) return 'SIM B';
          if (matchText.contains('C')) return 'SIM C';
        }
      }

      return null;
    } catch (e) {
      print('Error saat extract license type: $e');
      return null;
    }
  }

  /// Extract nama pemilik
  /// Biasanya ada setelah kata "NAMA" atau di baris tertentu
  String? _extractOwnerName(String text) {
    try {
      final lines = text.split('\n');

      // Cari line yang mengandung "NAMA"
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].toUpperCase();

        if (line.contains('NAMA') || line.contains('NAME')) {
          // Ambil text setelah "NAMA" di line yang sama
          final nameParts = lines[i].split(RegExp(r'NAMA|NAME', caseSensitive: false));
          if (nameParts.length > 1) {
            final name = nameParts[1].trim();
            if (name.isNotEmpty && _isValidName(name)) {
              return _formatName(name);
            }
          }

          // Atau ambil line berikutnya
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1].trim();
            if (nextLine.isNotEmpty && _isValidName(nextLine)) {
              return _formatName(nextLine);
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Error saat extract owner name: $e');
      return null;
    }
  }

  /// Extract tanggal kadaluarsa
  /// Format Indonesia: DD-MM-YYYY atau DD/MM/YYYY
  String? _extractExpirationDate(String text) {
    try {
      // Pattern untuk tanggal Indonesia
      final patterns = [
        RegExp(r'\d{2}[-/]\d{2}[-/]\d{4}'), // DD-MM-YYYY atau DD/MM/YYYY
        RegExp(r'\d{2}\s+\d{2}\s+\d{4}'), // DD MM YYYY
      ];

      final allDates = <DateTime>[];

      for (var pattern in patterns) {
        final matches = pattern.allMatches(text);
        for (var match in matches) {
          final dateStr = match.group(0);
          if (dateStr != null) {
            try {
              // Parse tanggal
              final parts = dateStr.split(RegExp(r'[-/\s]+'));
              if (parts.length == 3) {
                final day = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final year = int.parse(parts[2]);

                // Validasi tanggal
                if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
                  final date = DateTime(year, month, day);

                  // Hanya ambil tanggal yang di masa depan (kemungkinan expiry date)
                  if (date.isAfter(DateTime.now())) {
                    allDates.add(date);
                  }
                }
              }
            } catch (e) {
              continue;
            }
          }
        }
      }

      // Ambil tanggal terdekat di masa depan
      if (allDates.isNotEmpty) {
        allDates.sort();
        final closestDate = allDates.first;
        return DateFormat('dd-MM-yyyy').format(closestDate);
      }

      return null;
    } catch (e) {
      print('Error saat extract expiration date: $e');
      return null;
    }
  }

  /// Validasi apakah string adalah nama yang valid
  bool _isValidName(String text) {
    // Nama harus mengandung huruf dan tidak terlalu panjang
    if (text.length > 50 || text.length < 3) return false;

    // Harus mengandung minimal huruf
    if (!RegExp(r'[a-zA-Z]').hasMatch(text)) return false;

    // Tidak boleh mengandung terlalu banyak angka
    final digitCount = RegExp(r'\d').allMatches(text).length;
    if (digitCount > text.length / 2) return false;

    return true;
  }

  /// Format nama dengan proper capitalization
  String _formatName(String name) {
    // Hapus karakter special dan extra whitespace
    name = name.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();

    // Capitalize setiap kata
    return name.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Dispose text recognizer
  Future<void> dispose() async {
    await _textRecognizer.close();
  }

  /// Get all recognized text (untuk debugging)
  Future<String> getAllText(File imageFile) async {
    try {
      final recognizedText = await recognizeText(imageFile);
      return recognizedText.text;
    } catch (e) {
      print('Error saat get all text: $e');
      return '';
    }
  }

  /// Get recognized text dengan blocks (untuk debugging)
  Future<List<TextBlock>> getTextBlocks(File imageFile) async {
    try {
      final recognizedText = await recognizeText(imageFile);
      return recognizedText.blocks;
    } catch (e) {
      print('Error saat get text blocks: $e');
      return [];
    }
  }
}
