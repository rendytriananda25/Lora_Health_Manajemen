import 'package:flutter/foundation.dart';
import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/core/errors/failures.dart';
import 'package:lora_1/core/errors/exceptions.dart';
import 'package:lora_1/features/dashboard/domain/entities/weather_entity.dart';
import 'package:lora_1/features/dashboard/domain/entities/user_profile_entity.dart';
import 'package:lora_1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:lora_1/features/dashboard/data/datasources/weather_remote_datasource.dart';
import 'package:lora_1/features/dashboard/data/datasources/user_remote_datasource.dart';
import 'package:lora_1/features/dashboard/data/nutrition_data.dart';

/// Implementasi DashboardRepository.
/// Tugasnya:
///   1. Panggil DataSource untuk ambil data mentah
///   2. Tangkap exception → ubah jadi Failure
///   3. Konversi data mentah → Entity
class DashboardRepositoryImpl implements DashboardRepository {
  final WeatherRemoteDataSource weatherDataSource;
  final UserRemoteDataSource userDataSource;

  DashboardRepositoryImpl({
    required this.weatherDataSource,
    required this.userDataSource,
  });

  @override
  Future<Result<WeatherEntity>> getWeatherData({String langCode = 'id'}) async {
    try {
      final raw = await weatherDataSource.fetchWeatherAndAQI(langCode: langCode);
      final wData = raw['weather'];
      final aData = raw['aqi'];

      final entity = WeatherEntity(
        city: wData['name'] ?? 'Unknown',
        temperature: wData['main']['temp'].toInt().toString(),
        condition: wData['weather'][0]['description'] ?? '',
        aqi: (aData['list'][0]['main']['aqi'] as int) * 25,
        uvIndex: (100 - (wData['clouds']['all'] as num).toDouble()) / 10,
      );

      return Result.right(entity);
    } on ServerException catch (e) {
      return Result.left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('WeatherRepo Error: $e');
      return Result.left(ServerFailure('Gagal memuat data cuaca'));
    }
  }

  @override
  Future<Result<UserProfileEntity>> getUserProfile() async {
    try {
      final raw = await userDataSource.fetchUserProfile();

      final entity = UserProfileEntity(
        name: raw['name'] ?? 'User',
        localPhotoPath: raw['localPhotoPath'],
        fitnessLevel: raw['fitnessLevel'] ?? 'NEVER',
        fitnessGoal: raw['fitnessGoal'] ?? 'KEEP_FIT',
        favoriteSports: List<String>.from(raw['favoriteSports'] ?? []),
        exp: 0, // EXP dihandle oleh stream terpisah
      );

      return Result.right(entity);
    } on ServerException catch (e) {
      return Result.left(AuthFailure(e.message));
    } catch (e) {
      debugPrint('UserProfileRepo Error: $e');
      return Result.left(ServerFailure('Gagal memuat profil'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getNutritionData() async {
    try {
      // Online-first, fallback ke lokal
      var data = await NutritionData.fetchFromFirebase();
      data ??= NutritionData.foodRecommendations;
      return Result.right(data);
    } catch (e) {
      // Fallback ke data lokal jika error
      return Result.right(NutritionData.foodRecommendations);
    }
  }

  @override
  Future<Result<int>> checkDailyLogin() async {
    try {
      final gained = await userDataSource.checkDailyLogin();
      return Result.right(gained);
    } catch (e) {
      return Result.left(ServerFailure('Gagal cek daily login'));
    }
  }

  @override
  Stream<int> watchUserExp() => userDataSource.watchUserExp();

  @override
  Stream<String> watchUserName() => userDataSource.watchUserName();
}
