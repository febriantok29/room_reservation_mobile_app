import 'package:intl/intl.dart';

/// Utility class untuk format tanggal yang readable
class DateFormatter {
  static final _dayNames = {
    1: 'Senin',
    2: 'Selasa',
    3: 'Rabu',
    4: 'Kamis',
    5: 'Jumat',
    6: 'Sabtu',
    7: 'Minggu',
  };

  static final _monthNames = {
    1: 'Januari',
    2: 'Februari',
    3: 'Maret',
    4: 'April',
    5: 'Mei',
    6: 'Juni',
    7: 'Juli',
    8: 'Agustus',
    9: 'September',
    10: 'Oktober',
    11: 'November',
    12: 'Desember',
  };

  /// Format: "Jumat, 31 Desember 2024"
  static String fullDate(DateTime date) {
    date = date.toLocal(); // Konversi ke timezone lokal
    final day = _dayNames[date.weekday] ?? '';
    final month = _monthNames[date.month] ?? '';
    return '$day, ${date.day} $month ${date.year}';
  }

  /// Format: "31 Des 2024"
  static String shortDate(DateTime date) {
    date = date.toLocal();
    final formatter = DateFormat('d MMM y', 'id_ID');
    return formatter.format(date);
  }

  /// Format: "31/12/2024"
  static String numericDate(DateTime date) {
    date = date.toLocal();
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  /// Format: "15:30"
  static String time(DateTime date) {
    date = date.toLocal();
    final formatter = DateFormat('HH:mm');
    return formatter.format(date);
  }

  /// Format: "31 Des 2024, 15:30"
  static String shortDateTime(DateTime date) {
    date = date.toLocal();
    return '${shortDate(date)}, ${time(date)}';
  }

  /// Format: "Jumat, 31 Desember 2024 15:30"
  static String fullDateTime(DateTime date) {
    date = date.toLocal();
    return '${fullDate(date)} ${time(date)}';
  }

  /// Format: "5 menit yang lalu", "2 jam yang lalu", dst
  static String timeAgo(DateTime date) {
    date = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return shortDate(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  /// Parse ISO string ke DateTime dengan timezone yang benar
  static DateTime? parseFromIso(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString).toLocal();
    } catch (e) {
      return null;
    }
  }

  /// Format DateTime ke ISO string
  static String toIso(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}
