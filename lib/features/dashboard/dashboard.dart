import 'dart:async';
import 'dart:convert';
import 'dart:math'; // ✅ Add Random
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
// ✅ IMPORT PECAHAN WIDGET
import 'widgets/glass_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/nutrition_carousel.dart';
import 'data/nutrition_data.dart'; // ✅ Import Data Baru
import 'data/food_translator.dart'; // ✅ Import Translator
import 'package:lora_1/core/utils/app_size.dart'; // ✅ Responsive


// ✅ IMPORT HALAMAN LAIN
import 'package:lora_1/features/settings/setting_page.dart';
import 'package:lora_1/screen/statistic.dart';
import 'package:lora_1/features/gamification/rank_system.dart';
import 'package:lora_1/features/gamification/badge_service.dart'; // Added

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- STATE VARIABLES ---
  String userName = "User";
  String? localPhotoPath; // ✅ Foto lokal user
  String apiTemp = "--";
  String currentCity = "Memuat Lokasi...";
  String weatherCondition = "Memuat...";
  List<String> userFavorites = [];
  String userLevel = "NEVER";
  String userGoal = "KEEP_FIT";
  List<String> recommendationList = ["Menganalisis minatmu..."];
  List<Map<String, dynamic>> dailyPlan = []; // ✅ Daily Plan Storage
  int currentRecIndex = 0;
  Timer? _rotationTimer;
  StreamSubscription<DatabaseEvent>? _profileSubscription;
  int currentAQI = 0;
  double currentUV = 0.0;
  String environmentalTips = "Menyiapkan tips untukmu...";
  Map<String, dynamic>?
  _onlineNutritionData; // ✅ Variabel untuk data dari Firebase

  RankData currentRank = RankSystem.ranks[0]; // Default No Rank
  int currentExp = 0; // State for Exp
  final GlobalKey rankIconKey = GlobalKey(); // Key for animation
  StreamSubscription<DatabaseEvent>? _rankSubscription;

  final String apiKey = "d0fa6ab4f8080a9265e6a1bdf035fad0";

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  String _lastLangCode = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final langService = Provider.of<LanguageProvider>(context);
    if (_lastLangCode != langService.currentLanguage) {
      if (_lastLangCode.isNotEmpty) {
        // Re-fetch cuaca agar status awan dll ter-update ke bahasa target.
        _fetchEnvironmentData();
      }
      _lastLangCode = langService.currentLanguage;
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _rotationTimer?.cancel();
    _profileSubscription?.cancel();
    _rankSubscription?.cancel();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS ---
  Future<void> _initDashboard() async {
    await _fetchUserProfile();
    await _fetchEnvironmentData();
    await _syncNutritionData(); // ✅ Panggil fungsi sync
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final level = prefs.getString('user_fitness_level') ?? "NEVER";
        final goal = prefs.getString('user_fitness_goal') ?? "KEEP_FIT";
        final savedPhoto = prefs.getString('user_local_photo');
        final profileSnap = await FirebaseDatabase.instance
            .ref("users/${user.uid}")
            .get();
        String resolvedName = user.displayName ?? "User";
        if (profileSnap.exists && profileSnap.value is Map) {
          final data = Map<String, dynamic>.from(profileSnap.value as Map);
          resolvedName =
              data['username']?.toString() ??
              data['full_name']?.toString() ??
              resolvedName;
        }
        if (!mounted) return;
        setState(() {
          userName = resolvedName;
          userLevel = level;
          userGoal = goal;
          localPhotoPath = savedPhoto;
        });

        _profileSubscription?.cancel();
        _profileSubscription = FirebaseDatabase.instance
            .ref("users/${user.uid}")
            .onValue
            .listen((event) {
              if (!mounted || event.snapshot.value is! Map) return;
              final data = Map<String, dynamic>.from(
                event.snapshot.value as Map,
              );
              final liveName =
                  data['username']?.toString() ?? data['full_name']?.toString();
              if (liveName != null &&
                  liveName.isNotEmpty &&
                  liveName != userName) {
                setState(() => userName = liveName);
              }
            });

        final snapshot = await FirebaseDatabase.instance
            .ref("users/${user.uid}/favorite_sports")
            .get();
        if (snapshot.exists)
          userFavorites = List<String>.from(snapshot.value as List);

        // Listen to Rank/EXP
        _rankSubscription?.cancel();
        _rankSubscription = FirebaseDatabase.instance
            .ref("users/${user.uid}/gamification/exp")
            .onValue
            .listen((event) {
              if (mounted) {
                int exp = 0;
                if (event.snapshot.exists) {
                  exp = int.tryParse(event.snapshot.value.toString()) ?? 0;
                }
                setState(() {
                  currentExp = exp; // Update Exp
                  currentRank = RankSystem.getRank(exp);
                });
              }
            });

        // Check Daily Login
        _checkDailyLogin(user.uid);
      }
    } catch (e) {
      debugPrint("Firebase Error: $e");
    }
  }

  // 🔥 DAILY LOGIN CHECK
  Future<void> _checkDailyLogin(String uid) async {
    // Delay slightly to ensure dashboard is ready
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // Real Logic: Check Last Login Date
    int gained = await BadgeService.checkDailyLogin(uid);
    if (gained > 0 && mounted) {
      _showFlyingExp(gained);
    }
  }

  // 🔥 FLYING EXP ANIMATION
  void _showFlyingExp(int amount) {
    // Find Target Position (Rank Icon)
    Offset targetPos = Offset(
      MediaQuery.of(context).size.width - 50,
      60,
    ); // Default fallback

    final RenderBox? targetBox =
        rankIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox != null) {
      targetPos = targetBox.localToGlobal(Offset.zero);
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: _DailyLoginOverlay(
            endPos: targetPos,
            amount: amount,
            onFinished: () {
              if (entry.mounted) entry.remove();
            },
          ),
        );
      },
    );

    Overlay.of(context).insert(entry);
  }

  Future<void> _fetchEnvironmentData() async {
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {}
    if (!mounted) return;
    double lat = pos?.latitude ?? -7.9666;
    double lon = pos?.longitude ?? 112.6326;
    final langService = Provider.of<LanguageProvider>(context, listen: false);
    String langCode = langService.currentLanguage == 'ja' ? 'ja' : langService.currentLanguage == 'es' ? 'es' : langService.currentLanguage == 'id' ? 'id' : 'en';

    final weatherUrl =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=$langCode";
    final aqiUrl =
        "https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey";
    try {
      final results = await Future.wait([
        http.get(Uri.parse(weatherUrl)),
        http.get(Uri.parse(aqiUrl)),
      ]);
      if (results[0].statusCode == 200 &&
          results[1].statusCode == 200 &&
          mounted) {
        final wData = json.decode(results[0].body);
        final aData = json.decode(results[1].body);
        setState(() {
          apiTemp = wData['main']['temp'].toInt().toString();
          currentCity = wData['name'];
          weatherCondition = wData['weather'][0]['description'];
          currentAQI = aData['list'][0]['main']['aqi'] * 25;
          final lang = Provider.of<LanguageProvider>(context, listen: false);
          currentUV = (100 - wData['clouds']['all'].toDouble()) / 10;
          environmentalTips =
              "${_getAQIDetail(currentAQI, lang)['tips']} ${_getUVDetail(currentUV, lang)['tips']}";
          // Rekomendasi tidak perlu disave ke state statis, ini dihandle build()
          _startRecommendationRotation();
        });
      }
    } catch (e) {
      if (mounted) setState(() => currentCity = "Koneksi Gagal");
    }
  }

  // 🔥 FUNGSI BARU: Sinkronisasi Data Makanan
  Future<void> _syncNutritionData() async {
    // 1. Coba ambil dari Firebase
    var data = await NutritionData.fetchFromFirebase();

    // 2. Kalau kosong (offline/belum ada data), pakai data lokal sebagai cadangan
    if (data == null) {
      data = NutritionData.foodRecommendations;
    }

    if (mounted) {
      setState(() {
        _onlineNutritionData = data;
        _generateDailyPlan(); // ✅ Buat Menu Harian
      });
    }
  }

  // 🔥 LOGIC: PILIH 3 MAKANAN ACAK UNTUK MENU HARIAN
  void _generateDailyPlan() {
    final allFoods = _getFoodList();

    // 1. Filter hanya makanan "Good"
    final goodFoods = allFoods.where((f) => f['type'] == 'good').toList();

    if (goodFoods.isEmpty) {
      dailyPlan = [];
      return;
    }

    // 2. Acak urutan
    final random = Random();
    goodFoods.shuffle(random);

    // 3. Ambil 3 pertama & kasih label waktu makan (heuristic simple)
    List<Map<String, dynamic>> selected = goodFoods.take(3).toList();

    // Labeling Manual biar terlihat seperti menu (Pagi/Siang/Malam)
    // Note: Ini random, belum tentu benar secara nutrisi (misal Nasi di Pagi), tapi cukup buat MVP
    final hour = DateTime.now().hour;
    String mealTime = "MAKAN MALAM";
    if (hour >= 4 && hour < 11) mealTime = "SARAPAN";
    else if (hour >= 11 && hour < 16) mealTime = "MAKAN SIANG";
    for (var item in selected) {
      item['mealTimeRaw'] = mealTime;
    }



    dailyPlan = selected;
  }

  Map<String, dynamic> _getAQIDetail(int aqi, LanguageProvider lang) => aqi <= 50
      ? {
          "status": lang.translate('dashboard.aqiGood'),
          "color": Colors.greenAccent,
          "tips": lang.translate('dashboard.aqiTipGood'),
        }
      : aqi <= 100
      ? {
          "status": lang.translate('dashboard.aqiModerate'),
          "color": Colors.yellowAccent,
          "tips": lang.translate('dashboard.aqiTipModerate'),
        }
      : {
          "status": lang.translate('dashboard.aqiUnhealthy'),
          "color": Colors.redAccent,
          "tips": lang.translate('dashboard.aqiTipUnhealthy'),
        };
  Map<String, dynamic> _getUVDetail(double uv, LanguageProvider lang) => uv <= 2
      ? {
          "status": lang.translate('dashboard.uvLow'),
          "color": Colors.greenAccent,
          "tips": lang.translate('dashboard.uvTipLow'),
        }
      : uv <= 5
      ? {
          "status": lang.translate('dashboard.uvModerate'),
          "color": Colors.yellowAccent,
          "tips": lang.translate('dashboard.uvTipModerate'),
        }
      : {
          "status": lang.translate('dashboard.uvHigh'),
          "color": Colors.orangeAccent,
          "tips": lang.translate('dashboard.uvTipHigh'),
        };

  List<String> _generateSmartRecommendations(double temp, LanguageProvider lang) {
    if (userFavorites.isEmpty) return [lang.translate('dashboard.selectSportFirst')];
    List<String> tips = [];
    if (userGoal == "WEIGHT_LOSS") {
      tips.add(lang.translate('dashboard.focusBurnCalorie'));
      tips.add(
        temp >= 28
            ? lang.translate('dashboard.hotWeatherIndoor')
            : temp < 18
            ? lang.translate('dashboard.coldWeatherWarmup')
            : lang.translate('dashboard.priorityCardio'),
      );
    } else if (userGoal == "MUSCLE_GAIN") {
      tips.add(lang.translate('dashboard.focusStrength'));
      tips.add(
        temp >= 28
            ? lang.translate('dashboard.hotWeatherRest')
            : lang.translate('dashboard.priorityStrength'),
      );
    } else {
      tips.add(lang.translate('dashboard.focusBalanced'));
      tips.add(lang.translate('dashboard.priorityMobility'));
    }
    return tips;
  }

  void _startRecommendationRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && recommendationList.length > 1)
        setState(() {
          currentRecIndex = (currentRecIndex + 1) % recommendationList.length;
        });
    });
  }

  List<Map<String, dynamic>> _getFoodList() {
    // ✅ Gunakan data online jika ada, jika tidak gunakan data lokal (fallback)
    final sourceData =
        _onlineNutritionData ?? NutritionData.foodRecommendations;

    // Safety check: Pastikan key ada, kalau tidak default ke KEEP_FIT
    final goalKey = sourceData.containsKey(userGoal) ? userGoal : "KEEP_FIT";
    final goalData = Map<String, dynamic>.from(sourceData[goalKey] as Map);

    // Handle List dynamic dari Firebase agar aman dikonversi ke List<Map>
    List<dynamic> rawFoods = goalData['foods'] ?? [];
    List<Map<String, dynamic>> foods = rawFoods
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return foods.map((f) {
      bool isGood = f['type'] == 'good';
      
      String targetGoalReason = isGood ? goalData['reason_good'] : goalData['reason_bad'];

      return {
        "raw_name": f['name'], // 🔥 RAW NAME FOR DYNAMIC TRANS
        "name": FoodTranslator.translateName(f['name'], lang),
        "rating": isGood ? 5 : 2,
        // 🔥 OTOMATIS TAMPILKAN KALORI DI DESKRIPSI
        "desc":
            "${f['cal']} kcal • ${f['reason'] ?? FoodTranslator.translateGoalReason(targetGoalReason, lang)}",
        "icon": _getFoodIcon(f['name']),
        "type": f['type'],
      };
    }).toList();
  }

  IconData _getFoodIcon(String name) {
    String l = name.toLowerCase();
    return l.contains("ayam") || l.contains("daging")
        ? Icons.dinner_dining
        : l.contains("ikan")
        ? Icons.set_meal
        : l.contains("telur")
        ? Icons.egg
        : l.contains("nasi") || l.contains("oat")
        ? Icons.rice_bowl
        : l.contains("sayur") || l.contains("buah")
        ? Icons.eco
        : l.contains("susu") || l.contains("drink")
        ? Icons.local_drink
        : l.contains("goreng") || l.contains("junk")
        ? Icons.fastfood
        : Icons.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    // Agar dashboard rebuild saat bahasa berubah
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    var aqiInfo = _getAQIDetail(currentAQI, lang);
    var uvInfo = _getUVDetail(currentUV, lang);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Stack(
        children: [
          // KONTEN UTAMA - Paling Bawah di Stack
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                AppSize.w(20),
                AppSize.h(140),
                AppSize.w(20),
                AppSize.h(150),
              ),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherCard(theme),
                    SizedBox(height: AppSize.h(30)),
                    Text(
                      lang.translate('dashboard.environmentStatus'),
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: AppSize.sp(17),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSize.h(15)),
                    Row(
                      children: [
                        _buildStatCard(
                          lang.translate('dashboard.airQuality'),
                          aqiInfo['status'],
                          Icons.air,
                          aqiInfo['color'],
                          theme,
                        ),
                        SizedBox(width: AppSize.w(15)),
                        _buildStatCard(
                          lang.translate('dashboard.uvIndex'),
                          uvInfo['status'],
                          Icons.sunny,
                          uvInfo['color'],
                          theme,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSize.h(25)),
                    _buildTipsCard(
                      currentCity == "Memuat Lokasi..." || currentCity == "Koneksi Gagal"
                          ? lang.translate('dashboard.preparingTips')
                          : "${aqiInfo['tips']} ${uvInfo['tips']}",
                      lang,
                      theme,
                    ),
                    SizedBox(height: AppSize.h(30)),
                    // 🔥 SHOW DAILY MENU
                    _buildDailyMealPlan(theme, lang),
                    SizedBox(height: AppSize.h(30)),
                    NutritionCarousel(
                      userGoal: userGoal,
                      allFoods: _getFoodList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // HEADER - Di atas konten, tidak scrollable
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DashboardHeader(
              userName: userName,
              localPhotoPath: localPhotoPath,
              userRank: currentRank,
              currentExp: currentExp,
              rankIconKey: rankIconKey,
              onProfileTap: () async {
                await Navigator.of(context).push(_createRoute());
                if (mounted) {
                  final prefs = await SharedPreferences.getInstance();
                  setState(() {
                    localPhotoPath = prefs.getString('user_local_photo');
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 WIDGET BARU: DAILY MEAL PLAN
  Widget _buildDailyMealPlan(ThemeProvider theme, LanguageProvider lang) {
    if (dailyPlan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('dashboard.dailyPlan'),
          style: TextStyle(
            color: theme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: dailyPlan.map((food) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.boxColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: theme.textColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(food['icon'], color: Colors.green, size: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      FoodTranslator.translateMealTime(food['mealTimeRaw'] ?? "SARAPAN", lang),
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FoodTranslator.translateName(food['raw_name'] ?? food['name'], lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      food['desc'], // Tampilkan alasan juga
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF008BFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard(ThemeProvider theme) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.blueAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            currentCity.toUpperCase(),
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "$apiTemp° Celsius",
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weatherCondition.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF008BFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Colors.orangeAccent,
                  size: 50,
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _dynamicRecommendations.isNotEmpty
                    ? _dynamicRecommendations[currentRecIndex % _dynamicRecommendations.length]
                    : "Memuat...",
                key: ValueKey<int>(currentRecIndex),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (recommendationList.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _dynamicRecommendations.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentRecIndex == i
                          ? const Color(0xFF008BFF)
                          : theme.textColor.withOpacity(0.24),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeProvider theme,
  ) {
    return Expanded(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.54),
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard(
    String tips,
    LanguageProvider lang,
    ThemeProvider theme,
  ) {
    return GlassCard(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF008BFF),
              child: Icon(Icons.lightbulb_outline, color: Colors.white),
            ),
            title: Text(
              lang.translate('dashboard.healthTips'),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              tips,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lang.translate('dashboard.viewProgress'),
                    style: const TextStyle(
                      color: Color(0xFF008BFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF008BFF),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SettingsPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutQuart)),
          ),
          child: child,
        );
      },
    );
  }
  List<String> get _dynamicRecommendations {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return _generateSmartRecommendations(
      double.tryParse(apiTemp) ?? 25.0,
      lang,
    );
  }
}

class _DailyLoginOverlay extends StatefulWidget {
  final Offset endPos;
  final int amount;
  final VoidCallback onFinished;

  const _DailyLoginOverlay({
    required this.endPos,
    required this.amount,
    required this.onFinished,
  });

  @override
  State<_DailyLoginOverlay> createState() => _DailyLoginOverlayState();
}

class _DailyLoginOverlayState extends State<_DailyLoginOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  late AnimationController _flyController;
  late Animation<Offset> _flyAnim;
  late Animation<double> _flyScaleAnim;

  bool _isFlying = false;

  @override
  void initState() {
    super.initState();

    // 1. Controller untuk Pop Up Muncul (Scale Up + Fade In)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    // 2. Controller untuk Terbang (Fly to Target)
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Sequence: Muncul -> Tunggu -> Terbang
    _runSequence();
  }

  void _runSequence() async {
    await _mainController.forward(); // Muncul
    await Future.delayed(const Duration(seconds: 2)); // Tunggu baca

    if (!mounted) return;

    setState(() {
      _isFlying = true;
    });

    // Setup Fly Animation dynamically based on screen center
    final Size size = MediaQuery.of(context).size;
    final Offset start = Offset(size.width / 2, size.height / 2);

    _flyAnim = Tween<Offset>(begin: start, end: widget.endPos).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeInOutBack),
    );

    _flyScaleAnim = Tween<double>(
      begin: 1.5,
      end: 0.5,
    ).animate(_flyController); // Kecilin pas terbang

    await _flyController.forward();
    widget.onFinished();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 1. Background Blur & Dim (Hilang saat terbang)
          if (!_isFlying)
            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (ctx, child) => BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5 * _fadeAnim.value,
                  sigmaY: 5 * _fadeAnim.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.6 * _fadeAnim.value),
                ),
              ),
            ),

          // 2. Content
          if (!_isFlying)
            // TAMPILAN POP UP TENGAH
            Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "DAILY LOGIN",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                        fontSize: 16,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.6),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(Icons.bolt, color: Colors.amber, size: 80),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "+${widget.amount} EXP",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 48,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.amber, blurRadius: 20)],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Terus konsisten ya! 🔥",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            // TAMPILAN SAAT TERBANG (Simpel Icon + Teks)
            AnimatedBuilder(
              animation: _flyController,
              builder: (ctx, child) {
                return Positioned(
                  left: _flyAnim.value.dx - 25, // Center anchor
                  top: _flyAnim.value.dy - 25,
                  child: Transform.scale(
                    scale: _flyScaleAnim.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Colors.amber, size: 50),
                        Text(
                          "+${widget.amount}",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            shadows: [
                              Shadow(blurRadius: 5, color: Colors.black45),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
