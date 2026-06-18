import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/core/errors/failures.dart';
import 'package:lora_1/core/errors/exceptions.dart';
import 'package:lora_1/features/dashboard/domain/entities/weather_entity.dart';
import 'package:lora_1/features/dashboard/domain/entities/user_profile_entity.dart';
import 'package:lora_1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:lora_1/features/dashboard/data/datasources/weather_remote_datasource.dart';
import 'package:lora_1/features/dashboard/data/datasources/user_remote_datasource.dart';
import 'package:lora_1/features/dashboard/data/nutrition_data.dart';
import 'package:geocoding/geocoding.dart';

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

      String preciseLocation = wData['name'] ?? 'Unknown';
      try {
        final lat = (wData['coord']['lat'] as num).toDouble();
        final lon = (wData['coord']['lon'] as num).toDouble();
        final placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            preciseLocation = place.subLocality!;
          } else if (place.locality != null && place.locality!.isNotEmpty) {
            preciseLocation = place.locality!;
          }
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      final entity = WeatherEntity(
        city: preciseLocation,
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
        exp: 0,
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
      var data = await NutritionData.fetchFromFirebase();
      data ??= NutritionData.foodRecommendations;
      return Result.right(data);
    } catch (e) {
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
  Future<Result<Map<String, dynamic>?>> getLatestBmiFromHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Result.right(null);
      }

      final ref = FirebaseDatabase.instance.ref("users/${user.uid}/history");
      final snapshot = await ref.orderByChild('time').limitToLast(10).get();

      if (!snapshot.exists) {
        return Result.right(null);
      }

      final historyList = snapshot.value as Map<dynamic, dynamic>;
      Map<String, dynamic>? latestBmi;

      for (var entry in historyList.entries) {
        final item = Map<String, dynamic>.from(entry.value as Map);
        if (item['type'] == 'BMI') {
          latestBmi = {
            'score': double.tryParse(item['bmi_score']?.toString() ?? '0') ?? 0.0,
            'status': item['status'] ?? '',
            'weight': item['weight'],
            'height': item['height'],
            'time': item['time'],
          };
        }
      }

      return Result.right(latestBmi);
    } catch (e) {
      debugPrint('Error getting latest BMI: $e');
      return Result.right(null);
    }
  }

  @override
  Stream<int> watchUserExp() => userDataSource.watchUserExp();

  @override
  Stream<String> watchUserName() => userDataSource.watchUserName();
}
