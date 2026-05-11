
class AppConstants {
  AppConstants._();

  static const String appName = 'Lora Assistant';
  static const String appVersion = '1.0.0';

  static String userPath(String uid) => 'users/$uid';
  static String historyPath(String uid) => 'users/$uid/history';
  static String sportsPath(String uid) => 'users/$uid/sports';
  static String favoriteSportsPath(String uid) => 'users/$uid/favorite_sports';
  static String profilePath(String uid) => 'users/$uid/profile';
  static String gamificationPath(String uid) => 'users/$uid/gamification';
  static String nutritionPath() => 'app_data/nutrition';
  static String workoutPath() => 'app_data/workouts';

  static const String prefIsDarkMode = 'isDarkMode';
  static const String prefLanguage = 'app_language';
  static const String prefUserPhoto = 'user_local_photo';
  static const String prefLastSync = 'last_sync_time';

  static const int morningResetHour = 5;
  static const int afternoonResetHour = 15;

  static const double defaultWeight = 60.0;
  static const int snapThresholdPercent = 60;
  static const int recommendationRotationSec = 5;

  static const Duration firebaseTimeout = Duration(seconds: 10);
  static const Duration apiTimeout = Duration(seconds: 8);
}
