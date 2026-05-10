import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lora_1/features/dashboard/domain/entities/weather_entity.dart';
import 'package:lora_1/features/dashboard/domain/entities/user_profile_entity.dart';
import 'package:lora_1/features/dashboard/domain/entities/food_entity.dart';
import 'package:lora_1/features/dashboard/domain/usecases/get_weather_data.dart';
import 'package:lora_1/features/dashboard/domain/usecases/get_user_profile.dart';
import 'package:lora_1/features/dashboard/domain/usecases/generate_recommendations.dart';
import 'package:lora_1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:lora_1/features/gamification/rank_system.dart';
import 'package:lora_1/core/usecases/usecase.dart';

class DashboardProvider extends ChangeNotifier {
  // ─── USECASES ──────────────────────────────────────────────
  final GetWeatherData _getWeatherData;
  final GetUserProfile _getUserProfile;
  final GenerateRecommendations _generateRecommendations;
  final GenerateDailyPlan _generateDailyPlan;
  final GetEnvironmentDetail _getEnvironmentDetail;
  final DashboardRepository _repository;

  DashboardProvider({
    required GetWeatherData getWeatherData,
    required GetUserProfile getUserProfile,
    required DashboardRepository repository,
  }) : _getWeatherData = getWeatherData,
       _getUserProfile = getUserProfile,
       _repository = repository,
       _generateRecommendations = GenerateRecommendations(),
       _generateDailyPlan = GenerateDailyPlan(),
       _getEnvironmentDetail = GetEnvironmentDetail();

  // ─── STATE ─────────────────────────────────────────────────
  WeatherEntity weather = WeatherEntity.empty();
  UserProfileEntity userProfile = UserProfileEntity.empty();
  Map<String, dynamic>? nutritionData;
  List<FoodEntity> dailyPlan = [];
  List<String> recommendationList = ['Menganalisis minatmu...'];
  int currentRecIndex = 0;
  RankData currentRank = RankSystem.ranks[0];
  int currentExp = 0;
  bool isLoading = true;
  String? errorMessage;

  // ─── SUBSCRIPTIONS ─────────────────────────────────────────
  Timer? _rotationTimer;
  StreamSubscription<int>? _expSubscription;
  StreamSubscription<String>? _nameSubscription;

  // ─── INIT ──────────────────────────────────────────────────
  /// Panggil sekali saat Dashboard pertama kali dibuat.
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    await loadUserProfile();
    await loadWeather();
    await loadNutritionData();

    _startExpListener();
    _startNameListener();

    isLoading = false;
    notifyListeners();
  }

  /// Panggil saat pull-to-refresh.
  Future<void> refresh() async {
    await loadUserProfile();
    await loadWeather();
    await loadNutritionData();
  }

  // ─── LOAD FUNCTIONS ────────────────────────────────────────
  Future<void> loadWeather({String langCode = 'id'}) async {
    final result = await _getWeatherData(WeatherParams(langCode: langCode));
    result.fold(
      (failure) {
        weather = WeatherEntity(
          city: 'Koneksi Gagal',
          temperature: '--',
          condition: '',
          aqi: weather.aqi,
          uvIndex: weather.uvIndex,
        );
      },
      (data) {
        weather = data;
        _startRecommendationRotation();
      },
    );
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    final result = await _getUserProfile(const NoParams());
    result.fold(
      (failure) => errorMessage = failure.message,
      (data) => userProfile = data,
    );
    notifyListeners();
  }

  Future<void> loadNutritionData({TranslateFunction? translate}) async {
    final result = await _repository.getNutritionData();
    result.fold(
      (failure) => debugPrint('Nutrition Error: ${failure.message}'),
      (data) {
        nutritionData = data;
        // Daily plan akan di-generate saat widget memanggil generateDailyPlan()
      },
    );
    notifyListeners();
  }

  /// Check daily login dan kembalikan jumlah EXP didapat.
  Future<int> checkDailyLogin() async {
    final result = await _repository.checkDailyLogin();
    return result.fold((failure) => 0, (gained) => gained);
  }

  // ─── BUSINESS LOGIC (delegasi ke UseCase) ──────────────────
  List<String> getRecommendations({required TranslateFunction translate}) {
    double temp = double.tryParse(weather.temperature) ?? 25.0;
    return _generateRecommendations(
      temperature: temp,
      userGoal: userProfile.fitnessGoal,
      userFavorites: userProfile.favoriteSports,
      translate: translate,
    );
  }

  Map<String, dynamic> getAQIDetail(TranslateFunction translate) =>
      _getEnvironmentDetail.getAQIDetail(weather.aqi, translate);

  Map<String, dynamic> getUVDetail(TranslateFunction translate) =>
      _getEnvironmentDetail.getUVDetail(weather.uvIndex, translate);

  void generateDailyPlanFromFoods(List<FoodEntity> allFoods) {
    dailyPlan = _generateDailyPlan(allFoods);
    notifyListeners();
  }

  void clearDailyPlan() {
    dailyPlan = [];
    notifyListeners();
  }

  /// Buat daftar makanan dari data nutrisi mentah.
  List<FoodEntity> getFoodList({
    required TranslateFunction translateName,
    required TranslateFunction translateGoalReason,
  }) {
    final sourceData = nutritionData ?? {};
    final goalKey = sourceData.containsKey(userProfile.fitnessGoal)
        ? userProfile.fitnessGoal
        : 'KEEP_FIT';

    if (!sourceData.containsKey(goalKey)) return [];

    final goalData = Map<String, dynamic>.from(sourceData[goalKey] as Map);
    List<dynamic> rawFoods = goalData['foods'] ?? [];

    return rawFoods.map((e) {
      final f = Map<String, dynamic>.from(e as Map);
      bool isGood = f['type'] == 'good';
      String targetGoalReason = isGood
          ? (goalData['reason_good'] ?? '')
          : (goalData['reason_bad'] ?? '');

      return FoodEntity(
        rawName: f['name'],
        displayName: translateName(f['name']),
        rating: isGood ? 5 : 2,
        description:
            "${f['cal']} kcal • ${f['reason'] ?? translateGoalReason(targetGoalReason)}",
        icon: _getFoodIcon(f['name']),
        type: f['type'],
      );
    }).toList();
  }

  IconData _getFoodIcon(String name) {
    String l = name.toLowerCase();
    if (l.contains('ayam') || l.contains('daging')) return Icons.dinner_dining;
    if (l.contains('ikan')) return Icons.set_meal;
    if (l.contains('telur')) return Icons.egg;
    if (l.contains('nasi') || l.contains('oat')) return Icons.rice_bowl;
    if (l.contains('sayur') || l.contains('buah')) return Icons.eco;
    if (l.contains('susu') || l.contains('drink')) return Icons.local_drink;
    if (l.contains('goreng') || l.contains('junk')) return Icons.fastfood;
    return Icons.restaurant;
  }

  // ─── LISTENERS ─────────────────────────────────────────────
  void _startRecommendationRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (recommendationList.length > 1) {
        currentRecIndex = (currentRecIndex + 1) % recommendationList.length;
        notifyListeners();
      }
    });
  }

  void _startExpListener() {
    _expSubscription?.cancel();
    _expSubscription = _repository.watchUserExp().listen(
      (exp) {
        currentExp = exp;
        currentRank = RankSystem.getRank(exp);
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Exp listener error: $error");
      },
    );
  }

  void _startNameListener() {
    _nameSubscription?.cancel();
    _nameSubscription = _repository.watchUserName().listen(
      (name) {
        if (name.isNotEmpty && name != userProfile.name) {
          userProfile = UserProfileEntity(
            name: name,
            localPhotoPath: userProfile.localPhotoPath,
            fitnessLevel: userProfile.fitnessLevel,
            fitnessGoal: userProfile.fitnessGoal,
            favoriteSports: userProfile.favoriteSports,
            exp: userProfile.exp,
          );
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint("Name listener error: $error");
      },
    );
  }

  /// Panggil setelah navigasi dari halaman Setting (update foto).
  void updateLocalPhoto(String? path) {
    userProfile = UserProfileEntity(
      name: userProfile.name,
      localPhotoPath: path,
      fitnessLevel: userProfile.fitnessLevel,
      fitnessGoal: userProfile.fitnessGoal,
      favoriteSports: userProfile.favoriteSports,
      exp: userProfile.exp,
    );
    notifyListeners();
  }

  void clearUserData() {
    _rotationTimer?.cancel();
    _expSubscription?.cancel();
    _nameSubscription?.cancel();
    userProfile = UserProfileEntity.empty();
    dailyPlan = [];
    currentExp = 0;
    currentRank = RankSystem.ranks[0];
    notifyListeners();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _expSubscription?.cancel();
    _nameSubscription?.cancel();
    super.dispose();
  }
}
