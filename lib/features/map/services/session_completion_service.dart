import 'package:shared_preferences/shared_preferences.dart';

/// 🔄 SERVICE: Track apakah sesi olahraga sudah dilakukan di window saat ini
///
/// RESET SCHEDULE:
/// - Jam 05:00 → Sesi Pagi dimulai (reset)
/// - Jam 15:00 → Sesi Sore dimulai (reset)
///
/// Setelah user menyelesaikan workout:
/// - Saran olahraga dikosongkan
/// - Muncul kembali saat masuk window sesi berikutnya
class SessionCompletionService {
  // Key format: "session_done_{sport}_{session_id}"
  // session_id = "{tanggal}_{pagi/sore}" contoh: "2026-05-02_pagi"

  /// Tentukan sesi saat ini (pagi/sore) berdasarkan jam
  static String _getCurrentSessionId() {
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (now.hour >= 15) {
      // Jam 15:00+ = Sesi Sore
      return "${dateStr}_sore";
    } else if (now.hour >= 5) {
      // Jam 05:00 - 14:59 = Sesi Pagi
      return "${dateStr}_pagi";
    } else {
      // Jam 00:00 - 04:59 = Masih sesi sore kemarin
      final yesterday = now.subtract(const Duration(days: 1));
      final yDateStr =
          "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
      return "${yDateStr}_sore";
    }
  }

  /// Tandai sesi olahraga sudah selesai
  static Future<void> markSessionCompleted({required String sport}) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = _getCurrentSessionId();
    final sportKey = sport.toUpperCase().replaceAll(' ', '_');
    final key = "session_done_${sportKey}_$sessionId";

    await prefs.setBool(key, true);
    await prefs.setString("last_session_key_$sportKey", key);
  }

  /// Cek apakah sesi olahraga saat ini sudah dilakukan
  static Future<bool> isCurrentSessionCompleted({required String sport}) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = _getCurrentSessionId();
    final sportKey = sport.toUpperCase().replaceAll(' ', '_');
    final key = "session_done_${sportKey}_$sessionId";

    return prefs.getBool(key) ?? false;
  }

  /// Ambil label sesi saat ini
  static String getCurrentSessionLabel() {
    final now = DateTime.now();
    if (now.hour >= 15) return "Sesi Sore";
    if (now.hour >= 5) return "Sesi Pagi";
    return "Sesi Malam";
  }

  /// Hitung berapa lama lagi sampai sesi berikutnya reset
  static Duration getTimeUntilNextSession() {
    final now = DateTime.now();

    DateTime nextReset;
    if (now.hour < 5) {
      // Sebelum jam 5 pagi → reset jam 5 pagi hari ini
      nextReset = DateTime(now.year, now.month, now.day, 5, 0);
    } else if (now.hour < 15) {
      // Sebelum jam 3 sore → reset jam 3 sore hari ini
      nextReset = DateTime(now.year, now.month, now.day, 15, 0);
    } else {
      // Setelah jam 3 sore → reset jam 5 pagi besok
      nextReset = DateTime(now.year, now.month, now.day + 1, 5, 0);
    }

    return nextReset.difference(now);
  }

  /// Format durasi ke string readable ("3j 25m")
  static String formatDuration(Duration d) {
    int hours = d.inHours;
    int minutes = d.inMinutes % 60;
    if (hours > 0) return "${hours}j ${minutes}m";
    return "${minutes} menit";
  }

  /// Bersihkan data sesi lama (opsional, bisa dipanggil periodic)
  static Future<void> cleanOldSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    for (String key in allKeys) {
      if (key.startsWith("session_done_") &&
          !key.contains(todayStr) &&
          !key.contains(yesterdayStr)) {
        await prefs.remove(key);
      }
    }
  }
}
