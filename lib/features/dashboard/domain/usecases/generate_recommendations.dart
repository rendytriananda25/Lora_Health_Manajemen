import 'package:flutter/material.dart';
import 'package:lora_1/features/dashboard/domain/entities/food_entity.dart';

/// UseCase: Generate rekomendasi olahraga berdasarkan cuaca & goal.
/// Logika bisnis ini dipindahkan dari _generateSmartRecommendations di widget.
class GenerateRecommendations {
  /// Hasilkan daftar saran olahraga berdasarkan suhu dan tujuan user.
  List<String> call({
    required double temperature,
    required String userGoal,
    required List<String> userFavorites,
    required TranslateFunction translate,
  }) {
    if (userFavorites.isEmpty) {
      return [translate('dashboard.selectSportFirst')];
    }

    List<String> tips = [];

    if (userGoal == 'WEIGHT_LOSS') {
      tips.add(translate('dashboard.focusBurnCalorie'));
      tips.add(
        temperature >= 28
            ? translate('dashboard.hotWeatherIndoor')
            : temperature < 18
            ? translate('dashboard.coldWeatherWarmup')
            : translate('dashboard.priorityCardio'),
      );
    } else if (userGoal == 'MUSCLE_GAIN') {
      tips.add(translate('dashboard.focusStrength'));
      tips.add(
        temperature >= 28
            ? translate('dashboard.hotWeatherRest')
            : translate('dashboard.priorityStrength'),
      );
    } else {
      tips.add(translate('dashboard.focusBalanced'));
      tips.add(translate('dashboard.priorityMobility'));
    }

    return tips;
  }
}

/// UseCase: Generate daily meal plan dari daftar makanan.
/// Logika bisnis ini dipindahkan dari _generateDailyPlan di widget.
class GenerateDailyPlan {
  /// Pilih 3 makanan acak bertipe 'good' dan beri label waktu makan.
  List<FoodEntity> call(List<FoodEntity> allFoods) {
    // 1. Filter hanya makanan "good"
    final goodFoods = allFoods.where((f) => f.type == 'good').toList();

    if (goodFoods.isEmpty) return [];

    // 2. Acak urutan
    goodFoods.shuffle();

    // 3. Ambil 3 pertama & kasih label waktu makan
    final selected = goodFoods.take(3).toList();

    final hour = DateTime.now().hour;
    String mealTime = 'MAKAN MALAM';
    if (hour >= 4 && hour < 11) {
      mealTime = 'SARAPAN';
    } else if (hour >= 11 && hour < 16) {
      mealTime = 'MAKAN SIANG';
    }

    return selected.map((food) => FoodEntity(
      rawName: food.rawName,
      displayName: food.displayName,
      rating: food.rating,
      description: food.description,
      icon: food.icon,
      type: food.type,
      mealTime: mealTime,
    )).toList();
  }
}

/// UseCase: Tentukan detail AQI (status, warna, tips).
/// Logika bisnis ini dipindahkan dari _getAQIDetail di widget.
class GetEnvironmentDetail {
  /// Analisis AQI dan kembalikan status + tips.
  Map<String, dynamic> getAQIDetail(int aqi, TranslateFunction translate) {
    if (aqi <= 50) {
      return {
        'status': translate('dashboard.aqiGood'),
        'color': Colors.greenAccent,
        'tips': translate('dashboard.aqiTipGood'),
      };
    } else if (aqi <= 100) {
      return {
        'status': translate('dashboard.aqiModerate'),
        'color': Colors.yellowAccent,
        'tips': translate('dashboard.aqiTipModerate'),
      };
    } else {
      return {
        'status': translate('dashboard.aqiUnhealthy'),
        'color': Colors.redAccent,
        'tips': translate('dashboard.aqiTipUnhealthy'),
      };
    }
  }

  /// Analisis UV Index dan kembalikan status + tips.
  Map<String, dynamic> getUVDetail(double uv, TranslateFunction translate) {
    if (uv <= 2) {
      return {
        'status': translate('dashboard.uvLow'),
        'color': Colors.greenAccent,
        'tips': translate('dashboard.uvTipLow'),
      };
    } else if (uv <= 5) {
      return {
        'status': translate('dashboard.uvModerate'),
        'color': Colors.yellowAccent,
        'tips': translate('dashboard.uvTipModerate'),
      };
    } else {
      return {
        'status': translate('dashboard.uvHigh'),
        'color': Colors.orangeAccent,
        'tips': translate('dashboard.uvTipHigh'),
      };
    }
  }
}

/// Alias untuk fungsi translate supaya UseCase tidak bergantung pada LanguageProvider.
typedef TranslateFunction = String Function(String key);
