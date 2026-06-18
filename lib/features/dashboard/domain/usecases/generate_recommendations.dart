import 'package:flutter/material.dart';
import 'package:lora_1/features/dashboard/domain/entities/food_entity.dart';
import 'package:lora_1/features/dashboard/domain/usecases/personalized_recommendation_engine.dart';

typedef TranslateFunction = String Function(String key);

class GenerateRecommendations {
  List<String> call({
    required double temperature,
    required String userGoal,
    required List<String> userFavorites,
    required BmiStatus? bmiStatus,
    String weatherCondition = 'clear',
    String fitnessLevel = 'SOMETIMES',
    required TranslateFunction translate,
  }) {
    if (userFavorites.isEmpty) {
      return [translate('dashboard.selectSportFirst')];
    }

    if (bmiStatus == null) {
      return _generateFallbackTips(temperature, userGoal, translate);
    }

    final recommendation = PersonalizedRecommendationEngine.generate(
      bmiStatus: bmiStatus,
      temperature: temperature,
      weatherCondition: weatherCondition,
      userGoal: userGoal,
      fitnessLevel: fitnessLevel,
      favoriteSports: userFavorites,
      translate: translate,
    );

    return recommendation.workoutTips;
  }

  List<String> _generateFallbackTips(
    double temperature,
    String userGoal,
    TranslateFunction translate,
  ) {
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

class GenerateDailyPlan {
  List<FoodEntity> call(
    List<FoodEntity> allFoods, {
    String? bmiCategory,
    double? temperature,
    String? weatherCondition,
  }) {
    var goodFoods = allFoods.where((f) => f.type == 'good').toList();

    if (goodFoods.isEmpty) return [];

    if (bmiCategory != null) {
      goodFoods = _filterByBmiCategory(goodFoods, bmiCategory);
    }

    if (temperature != null && temperature >= 28) {
      goodFoods = _prioritizeLightFoods(goodFoods);
    }

    if (weatherCondition != null && weatherCondition.toLowerCase().contains('rain')) {
      goodFoods = _prioritizeWarmingFoods(goodFoods);
    }

    goodFoods.shuffle();
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

  List<FoodEntity> _filterByBmiCategory(
    List<FoodEntity> foods,
    String bmiCategory,
  ) {
    if (bmiCategory == 'FAT_LOSS') {
      return foods
          .where((f) =>
              f.rawName.toUpperCase().contains('TELUR') ||
              f.rawName.toUpperCase().contains('AYAM') ||
              f.rawName.toUpperCase().contains('IKAN') ||
              f.rawName.toUpperCase().contains('SAYUR') ||
              f.rawName.toUpperCase().contains('BUAH'))
          .toList();
    } else if (bmiCategory == 'MUSCLE_GAIN') {
      return foods
          .where((f) =>
              f.rawName.toUpperCase().contains('DAGING') ||
              f.rawName.toUpperCase().contains('AYAM') ||
              f.rawName.toUpperCase().contains('IKAN') ||
              f.rawName.toUpperCase().contains('TELUR') ||
              f.rawName.toUpperCase().contains('TEMPE') ||
              f.rawName.toUpperCase().contains('NASI MERAH') ||
              f.rawName.toUpperCase().contains('OATMEAL'))
          .toList();
    }
    return foods;
  }

  List<FoodEntity> _prioritizeLightFoods(List<FoodEntity> foods) {
    return foods
        .where((f) =>
            f.rawName.toUpperCase().contains('SAYUR') ||
            f.rawName.toUpperCase().contains('BUAH') ||
            f.rawName.toUpperCase().contains('AIR') ||
            f.rawName.toUpperCase().contains('SMOOTHIE'))
        .toList()
        .isNotEmpty
        ? foods
            .where((f) =>
                f.rawName.toUpperCase().contains('SAYUR') ||
                f.rawName.toUpperCase().contains('BUAH') ||
                f.rawName.toUpperCase().contains('AIR') ||
                f.rawName.toUpperCase().contains('SMOOTHIE'))
            .toList()
        : foods;
  }

  List<FoodEntity> _prioritizeWarmingFoods(List<FoodEntity> foods) {
    return foods
        .where((f) =>
            f.rawName.toUpperCase().contains('SUP') ||
            f.rawName.toUpperCase().contains('SOTO') ||
            f.rawName.toUpperCase().contains('AYAM'))
        .toList()
        .isNotEmpty
        ? foods
            .where((f) =>
                f.rawName.toUpperCase().contains('SUP') ||
                f.rawName.toUpperCase().contains('SOTO') ||
                f.rawName.toUpperCase().contains('AYAM'))
            .toList()
        : foods;
  }
}

class GetEnvironmentDetail {
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
