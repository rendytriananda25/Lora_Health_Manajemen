/// ═══════════════════════════════════════════════════════════════
/// App Constants — Konfigurasi umum yang sering digunakan.
/// ═══════════════════════════════════════════════════════════════

class AppConstants {
  AppConstants._(); // Prevent instantiation

  // ─── APP INFO ──────────────────────────────────────────────
  static const String appName = 'Lora Assistant';
  static const String appVersion = '1.0.0';

  // ─── FIREBASE PATHS ────────────────────────────────────────
  /// Gunakan path ini supaya konsisten di seluruh app.
  static String userPath(String uid) => 'users/$uid';
  static String historyPath(String uid) => 'users/$uid/history';
  static String sportsPath(String uid) => 'users/$uid/sports';
  static String favoriteSportsPath(String uid) => 'users/$uid/favorite_sports';
  static String profilePath(String uid) => 'users/$uid/profile';
  static String gamificationPath(String uid) => 'users/$uid/gamification';
  static String nutritionPath() => 'app_data/nutrition';
  static String workoutPath() => 'app_data/workouts';

  // ─── SHARED PREFERENCES KEYS ──────────────────────────────
  static const String prefIsDarkMode = 'isDarkMode';
  static const String prefLanguage = 'app_language';
  static const String prefUserPhoto = 'user_local_photo';
  static const String prefLastSync = 'last_sync_time';

  // ─── SESSION RESET TIMES ──────────────────────────────────
  /// Jam reset sesi olahraga (pagi & sore)
  static const int morningResetHour = 5;   // 05:00
  static const int afternoonResetHour = 15; // 15:00

  // ─── WORKOUT DEFAULTS ──────────────────────────────────────
  static const double defaultWeight = 60.0;
  static const int snapThresholdPercent = 60; // SwipeButton snap threshold
  static const int recommendationRotationSec = 5;

  // ─── TIMEOUTS ──────────────────────────────────────────────
  static const Duration firebaseTimeout = Duration(seconds: 10);
  static const Duration apiTimeout = Duration(seconds: 8);
}
