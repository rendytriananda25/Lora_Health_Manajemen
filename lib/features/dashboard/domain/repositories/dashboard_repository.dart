import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/features/dashboard/domain/entities/weather_entity.dart';
import 'package:lora_1/features/dashboard/domain/entities/user_profile_entity.dart';

/// Kontrak repository untuk Dashboard.
/// Domain Layer HANYA tahu interface ini. Tidak tahu implementasinya.
/// Data Layer yang akan mengimplementasikan kontrak ini.
abstract class DashboardRepository {
  /// Ambil data cuaca, AQI, dan UV berdasarkan lokasi saat ini.
  Future<Result<WeatherEntity>> getWeatherData({String langCode = 'id'});

  /// Ambil profil user dari Firebase + SharedPreferences.
  Future<Result<UserProfileEntity>> getUserProfile();

  /// Ambil data nutrisi (online-first, fallback ke lokal).
  Future<Result<Map<String, dynamic>>> getNutritionData();

  /// Cek daily login dan kembalikan jumlah EXP yang didapat.
  Future<Result<int>> checkDailyLogin();

  /// Stream untuk mendengarkan perubahan EXP secara realtime.
  Stream<int> watchUserExp();

  /// Stream untuk mendengarkan perubahan nama user secara realtime.
  Stream<String> watchUserName();
}
