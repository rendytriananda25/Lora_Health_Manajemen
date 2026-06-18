import 'package:shared_preferences/shared_preferences.dart';

class SessionCompletionService {

  static String _getCurrentSessionId() {
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (now.hour >= 15) {
      return "${dateStr}_sore";
    } else if (now.hour >= 5) {
      return "${dateStr}_pagi";
    } else {
      final yesterday = now.subtract(const Duration(days: 1));
      final yDateStr =
          "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
      return "${yDateStr}_sore";
    }
  }

  static Future<void> markSessionCompleted({required String sport}) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = _getCurrentSessionId();
    final sportKey = sport.toUpperCase().replaceAll(' ', '_');
    final key = "session_done_${sportKey}_$sessionId";

    await prefs.setBool(key, true);
    await prefs.setString("last_session_key_$sportKey", key);
  }

  static Future<bool> isCurrentSessionCompleted({required String sport}) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = _getCurrentSessionId();
    final sportKey = sport.toUpperCase().replaceAll(' ', '_');
    final key = "session_done_${sportKey}_$sessionId";

    return prefs.getBool(key) ?? false;
  }

  static String getCurrentSessionLabel() {
    final now = DateTime.now();
    if (now.hour >= 15) return "Sesi Sore";
    if (now.hour >= 5) return "Sesi Pagi";
    return "Sesi Malam";
  }

  static Duration getTimeUntilNextSession() {
    final now = DateTime.now();

    DateTime nextReset;
    if (now.hour < 5) {
      nextReset = DateTime(now.year, now.month, now.day, 5, 0);
    } else if (now.hour < 15) {
      nextReset = DateTime(now.year, now.month, now.day, 15, 0);
    } else {
      nextReset = DateTime(now.year, now.month, now.day + 1, 5, 0);
    }

    return nextReset.difference(now);
  }

  static String formatDuration(Duration d) {
    int hours = d.inHours;
    int minutes = d.inMinutes % 60;
    if (hours > 0) return "${hours}j ${minutes}m";
    return "${minutes} menit";
  }

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
