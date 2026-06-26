import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'secrets.dart';

class ApiConstants {
  ApiConstants._();

  static String get firebaseDatabaseUrl =>
      dotenv.env['FIREBASE_DATABASE_URL'] ?? 'https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app';

  static String get weatherApiKey => Secrets.weatherApiKey;
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  static String weatherUrl(double lat, double lon, {String lang = 'id'}) =>
      '$weatherBaseUrl/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric&lang=$lang';

  static String aqiUrl(double lat, double lon) =>
      '$weatherBaseUrl/air_pollution?lat=$lat&lon=$lon&appid=$weatherApiKey';

  static String uvUrl(double lat, double lon) =>
      'https://api.openweathermap.org/data/2.5/uvi?lat=$lat&lon=$lon&appid=$weatherApiKey';
}
