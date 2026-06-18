import 'package:lora_1/features/bmi/domain/entities/bmi_result_entity.dart';
import 'package:lora_1/features/dashboard/domain/usecases/generate_recommendations.dart';

class BmiStatus {
  final double score;
  final String status; // underweight, normal, overweight, obese
  final String category; // FAT_LOSS, MUSCLE_GAIN, MAINTAIN

  const BmiStatus({
    required this.score,
    required this.status,
    required this.category,
  });

  factory BmiStatus.fromBmiResult(BmiResultEntity entity) {
    final normalizedStatus = entity.status.toLowerCase();
    String category;

    if (normalizedStatus.contains('underweight')) {
      category = 'MUSCLE_GAIN';
    } else if (normalizedStatus.contains('overweight') ||
        normalizedStatus.contains('obesity')) {
      category = 'FAT_LOSS';
    } else {
      category = 'MAINTAIN';
    }

    return BmiStatus(
      score: entity.score,
      status: normalizedStatus,
      category: category,
    );
  }
}

class PersonalizedRecommendationData {
  final String workoutFocus;
  final String nutritionFocus;
  final List<String> workoutTips;
  final List<String> nutritionTips;
  final String hydrationAdvice;
  final String calorieGuideline;
  final String proteinGuideline;
  final String priority; // HIGH, MEDIUM, LOW

  const PersonalizedRecommendationData({
    required this.workoutFocus,
    required this.nutritionFocus,
    required this.workoutTips,
    required this.nutritionTips,
    required this.hydrationAdvice,
    required this.calorieGuideline,
    required this.proteinGuideline,
    required this.priority,
  });
}

class PersonalizedRecommendationEngine {
  static PersonalizedRecommendationData generate({
    required BmiStatus bmiStatus,
    required double temperature,
    required String weatherCondition,
    required String userGoal,
    required String fitnessLevel,
    required List<String> favoriteSports,
    required TranslateFunction translate,
  }) {
    final workoutFocus = _determineWorkoutFocus(
      bmiStatus,
      userGoal,
      temperature,
      translate,
    );

    final nutritionFocus = _determineNutritionFocus(
      bmiStatus,
      userGoal,
      temperature,
      translate,
    );

    final workoutTips = _generateWorkoutTips(
      bmiStatus,
      temperature,
      weatherCondition,
      fitnessLevel,
      translate,
    );

    final nutritionTips = _generateNutritionTips(
      bmiStatus,
      temperature,
      weatherCondition,
      userGoal,
      translate,
    );

    final hydrationAdvice = _getHydrationAdvice(
      temperature,
      bmiStatus.score,
      translate,
    );

    final calorieGuideline = _getCalorieGuideline(
      bmiStatus,
      userGoal,
      fitnessLevel,
      translate,
    );

    final proteinGuideline = _getProteinGuideline(
      bmiStatus,
      userGoal,
      translate,
    );

    final priority = _determinePriority(bmiStatus, userGoal);

    return PersonalizedRecommendationData(
      workoutFocus: workoutFocus,
      nutritionFocus: nutritionFocus,
      workoutTips: workoutTips,
      nutritionTips: nutritionTips,
      hydrationAdvice: hydrationAdvice,
      calorieGuideline: calorieGuideline,
      proteinGuideline: proteinGuideline,
      priority: priority,
    );
  }

  static String _determineWorkoutFocus(
    BmiStatus bmi,
    String userGoal,
    double temp,
    TranslateFunction translate,
  ) {
    if (bmi.category == 'FAT_LOSS' || bmi.status == 'overweight' || bmi.status == 'obese') {
      return translate('engine.workoutCardio');
    } else if (bmi.category == 'MUSCLE_GAIN' || bmi.status == 'underweight') {
      return translate('engine.workoutStrength');
    }
    return translate('engine.workoutBalanced');
  }

  static String _determineNutritionFocus(
    BmiStatus bmi,
    String userGoal,
    double temp,
    TranslateFunction translate,
  ) {
    if (bmi.category == 'FAT_LOSS') {
      return temp >= 28
          ? translate('engine.nutritionLowCalHighHydration')
          : translate('engine.nutritionHighProteinLowCal');
    } else if (bmi.category == 'MUSCLE_GAIN') {
      return translate('engine.nutritionHighProteinSurplus');
    }
    return temp >= 28
        ? translate('engine.nutritionBalancedLightMeals')
        : translate('engine.nutritionBalanced');
  }

  static List<String> _generateWorkoutTips(
    BmiStatus bmi,
    double temp,
    String weatherCondition,
    String fitnessLevel,
    TranslateFunction translate,
  ) {
    final tips = <String>[];

    if (bmi.status == 'obese') {
      tips.add(translate('engine.startWithWalkingSwimming'));
      tips.add(translate('engine.avoidHighImpact'));
    } else if (bmi.status == 'overweight') {
      tips.add(translate('engine.prioritizeCardio'));
      tips.add(translate('engine.increaseSessionFrequency'));
    } else if (bmi.status == 'underweight') {
      tips.add(translate('engine.addStrengthTraining'));
      tips.add(translate('engine.increaseMuscleReps'));
    }

    if (temp >= 33) {
      tips.add(translate('engine.earlyMorningOrEveningWorkout'));
    } else if (temp <= 18) {
      tips.add(translate('engine.properWarmupBeforeWorkout'));
    }

    if (fitnessLevel == 'NEVER') {
      tips.add(translate('engine.graduallyIncreaseIntensity'));
    } else if (fitnessLevel == 'DAILY') {
      tips.add(translate('engine.pushForAdvancedTechniques'));
    }

    return tips.take(4).toList();
  }

  static List<String> _generateNutritionTips(
    BmiStatus bmi,
    double temp,
    String weatherCondition,
    String userGoal,
    TranslateFunction translate,
  ) {
    final tips = <String>[];

    if (bmi.category == 'FAT_LOSS') {
      tips.add(translate('engine.prioritizeProteinStayFull'));
      tips.add(translate('engine.avoidProcessedFoods'));
      if (temp >= 28) {
        tips.add(translate('engine.increaseWaterIntake'));
      }
    } else if (bmi.category == 'MUSCLE_GAIN') {
      tips.add(translate('engine.eatInSurplus'));
      tips.add(translate('engine.timeMealsAroundWorkout'));
      tips.add(translate('engine.focusOnCompoundFoods'));
    } else {
      tips.add(translate('engine.maintainBalancedDiet'));
      tips.add(translate('engine.consistentMealTiming'));
    }

    if (weatherCondition.toLowerCase().contains('rain')) {
      tips.add(translate('engine.warmFoodsAndSoups'));
    }

    return tips.take(4).toList();
  }

  static String _getHydrationAdvice(
    double temp,
    double bmiScore,
    TranslateFunction translate,
  ) {
    if (temp >= 33) {
      return translate('engine.hydrate600800MlPerHour');
    } else if (temp >= 28) {
      return translate('engine.hydrate500700MlPerHour');
    } else {
      return translate('engine.hydrate400600MlPerHour');
    }
  }

  static String _getCalorieGuideline(
    BmiStatus bmi,
    String userGoal,
    String fitnessLevel,
    TranslateFunction translate,
  ) {
    if (bmi.category == 'FAT_LOSS') {
      return translate('engine.calorieModerateDeficit');
    } else if (bmi.category == 'MUSCLE_GAIN') {
      return translate('engine.calorieControlledSurplus');
    }
    return translate('engine.calorieMaintenanceLevel');
  }

  static String _getProteinGuideline(
    BmiStatus bmi,
    String userGoal,
    TranslateFunction translate,
  ) {
    if (bmi.category == 'MUSCLE_GAIN' || bmi.status == 'underweight') {
      return translate('engine.protein160200PerKg');
    } else if (bmi.category == 'FAT_LOSS') {
      return translate('engine.protein120140PerKg');
    }
    return translate('engine.protein100120PerKg');
  }

  static String _determinePriority(BmiStatus bmi, String userGoal) {
    if (bmi.status == 'obese' || bmi.status == 'overweight') return 'HIGH';
    if (bmi.status == 'underweight') return 'HIGH';
    if (userGoal == 'WEIGHT_LOSS' || userGoal == 'MUSCLE_GAIN') return 'MEDIUM';
    return 'LOW';
  }
}
