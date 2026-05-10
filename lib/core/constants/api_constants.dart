class ApiConstants {
  ApiConstants._(); // Prevent instantiation

  // ─── FIREBASE ──────────────────────────────────────────────
  static const String firebaseDatabaseUrl =
      'https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app';

  // ─── OPENWEATHERMAP ────────────────────────────────────────
  static const String weatherApiKey = 'd0fa6ab4f8080a9265e6a1bdf035fad0';
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  /// Endpoint cuaca berdasarkan koordinat.
  static String weatherUrl(double lat, double lon, {String lang = 'id'}) =>
      '$weatherBaseUrl/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric&lang=$lang';

  /// Endpoint Air Quality Index (AQI) berdasarkan koordinat.
  static String aqiUrl(double lat, double lon) =>
      '$weatherBaseUrl/air_pollution?lat=$lat&lon=$lon&appid=$weatherApiKey';

  /// Endpoint UV Index berdasarkan koordinat.
  static String uvUrl(double lat, double lon) =>
      'https://api.openweathermap.org/data/2.5/uvi?lat=$lat&lon=$lon&appid=$weatherApiKey';
}
