import 'package:intl/intl.dart';

/// Helper untuk formatting tanggal dalam Bahasa Indonesia
class DateHelper {
  /// Format tanggal ke DD MMM YYYY (contoh: 15 Jan 2024)
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  /// Format tanggal lengkap (contoh: Senin, 15 Januari 2024)
  static String formatFullDate(DateTime date) {
    final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  /// Format tanggal untuk input (DD-MM-YYYY)
  static String formatInputDate(DateTime date) {
    final formatter = DateFormat('dd-MM-yyyy');
    return formatter.format(date);
  }

  /// Parse tanggal dari string DD-MM-YYYY
  static DateTime? parseInputDate(String dateString) {
    try {
      final formatter = DateFormat('dd-MM-yyyy');
      return formatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Hitung selisih hari dari sekarang
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Get text countdown dalam Bahasa Indonesia
  static String getCountdownText(DateTime expirationDate) {
    final now = DateTime.now();
    final daysRemaining = daysBetween(now, expirationDate);

    if (daysRemaining < 0) {
      return 'Kadaluarsa ${daysRemaining.abs()} hari yang lalu';
    } else if (daysRemaining == 0) {
      return 'Kadaluarsa hari ini';
    } else if (daysRemaining == 1) {
      return 'Kadaluarsa besok';
    } else {
      return 'Kadaluarsa dalam $daysRemaining hari';
    }
  }

  /// Get warna berdasarkan status kadaluarsa
  static CountdownStatus getCountdownStatus(DateTime expirationDate) {
    final now = DateTime.now();
    final daysRemaining = daysBetween(now, expirationDate);

    if (daysRemaining < 0) {
      return CountdownStatus.expired;
    } else if (daysRemaining <= 7) {
      return CountdownStatus.expiringSoon;
    } else {
      return CountdownStatus.active;
    }
  }

  /// Check apakah tanggal valid
  static bool isValidDate(int day, int month, int year) {
    if (year < 1900 || year > 2100) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1) return false;

    // Check maksimal hari per bulan
    final daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    // Leap year
    if (month == 2 && _isLeapYear(year)) {
      return day <= 29;
    }

    return day <= daysInMonth[month - 1];
  }

  /// Check apakah tahun kabisat
  static bool _isLeapYear(int year) {
    if (year % 4 != 0) return false;
    if (year % 100 != 0) return true;
    if (year % 400 != 0) return false;
    return true;
  }

  /// Get tanggal minimal untuk SIM (hari ini)
  static DateTime getMinDate() {
    return DateTime.now();
  }

  /// Get tanggal maksimal untuk SIM (10 tahun dari sekarang)
  static DateTime getMaxDate() {
    final now = DateTime.now();
    return DateTime(now.year + 10, now.month, now.day);
  }
}

/// Status countdown untuk styling
enum CountdownStatus {
  active, // > 7 hari
  expiringSoon, // <= 7 hari
  expired, // < 0 hari
}
