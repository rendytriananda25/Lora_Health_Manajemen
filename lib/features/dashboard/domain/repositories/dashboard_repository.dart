import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/features/dashboard/domain/entities/weather_entity.dart';
import 'package:lora_1/features/dashboard/domain/entities/user_profile_entity.dart';

abstract class DashboardRepository {
  Future<Result<WeatherEntity>> getWeatherData({String langCode = 'id'});

  Future<Result<UserProfileEntity>> getUserProfile();

  Future<Result<Map<String, dynamic>>> getNutritionData();

  Future<Result<int>> checkDailyLogin();

  Stream<int> watchUserExp();

  Stream<String> watchUserName();
}
