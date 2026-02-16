import 'dart:async';
import 'dart:convert';
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

// ✅ IMPORT HALAMAN LAIN
import 'package:lora_1/features/settings/setting_page.dart';
import 'package:lora_1/screen/statistic.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- STATE VARIABLES ---
  String userName = "User";
  String apiTemp = "--";
  String currentCity = "Memuat Lokasi...";
  String weatherCondition = "Memuat...";
  List<String> userFavorites = [];
  String userLevel = "NEVER";
  String userGoal = "KEEP_FIT";
  List<String> recommendationList = ["Menganalisis minatmu..."];
  int currentRecIndex = 0;
  Timer? _rotationTimer;
  StreamSubscription<DatabaseEvent>? _profileSubscription;
  int currentAQI = 0;
  double currentUV = 0.0;
  String environmentalTips = "Menyiapkan tips untukmu...";
  Map<String, dynamic>?
  _onlineNutritionData; // ✅ Variabel untuk data dari Firebase

  final String apiKey = "d0fa6ab4f8080a9265e6a1bdf035fad0";

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _profileSubscription?.cancel();
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
      }
    } catch (e) {
      debugPrint("Firebase Error: $e");
    }
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
    final weatherUrl =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id";
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
          currentUV = (100 - wData['clouds']['all'].toDouble()) / 10;
          environmentalTips =
              "${_getAQIDetail(currentAQI)['tips']} ${_getUVDetail(currentUV)['tips']}";
          recommendationList = _generateSmartRecommendations(
            wData['main']['temp'].toDouble(),
          );
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
      });
    }
  }

  Map<String, dynamic> _getAQIDetail(int aqi) => aqi <= 50
      ? {
          "status": "Baik",
          "color": Colors.greenAccent,
          "tips": "Aman tanpa masker.",
        }
      : aqi <= 100
      ? {
          "status": "Sedang",
          "color": Colors.yellowAccent,
          "tips": "Asma harap waspada.",
        }
      : {
          "status": "Tidak Sehat",
          "color": Colors.redAccent,
          "tips": "Gunakan masker!",
        };
  Map<String, dynamic> _getUVDetail(double uv) => uv <= 2
      ? {
          "status": "Rendah",
          "color": Colors.greenAccent,
          "tips": "Aman luar ruangan.",
        }
      : uv <= 5
      ? {
          "status": "Sedang",
          "color": Colors.yellowAccent,
          "tips": "Gunakan sunscreen.",
        }
      : {
          "status": "Tinggi",
          "color": Colors.orangeAccent,
          "tips": "Kurangi paparan siang.",
        };

  List<String> _generateSmartRecommendations(double temp) {
    if (userFavorites.isEmpty) return ["Yuk pilih olahraga dulu di Settings!"];
    List<String> tips = [];
    if (userGoal == "WEIGHT_LOSS") {
      tips.add("Fokus: Bakar kalori & kardio.");
      tips.add(
        temp >= 28
            ? "Cuaca Panas: Latihan indoor."
            : temp < 18
            ? "Cuaca Dingin: Pemanasan lama."
            : "Prioritas: Cardio & HIIT.",
      );
    } else if (userGoal == "MUSCLE_GAIN") {
      tips.add("Fokus: Kekuatan & repetisi.");
      tips.add(
        temp >= 28
            ? "Cuaca Panas: Istirahat sering."
            : "Prioritas: Strength Training.",
      );
    } else {
      tips.add("Fokus: Latihan seimbang.");
      tips.add("Prioritas: Mobility.");
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

    return foods.map((f) {
      bool isGood = f['type'] == 'good';
      return {
        "name": f['name'],
        "rating": isGood ? 5 : 2,
        // 🔥 OTOMATIS TAMPILKAN KALORI DI DESKRIPSI
        "desc":
            "${f['cal']} kkal • ${f['reason'] ?? (isGood ? goalData['reason_good'] : goalData['reason_bad'])}",
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
    // Agar dashboard rebuild saat bahasa berubah
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context); // ✅ Theme Provider

    var aqiInfo = _getAQIDetail(currentAQI);
    var uvInfo = _getUVDetail(currentUV);

    return Scaffold(
      backgroundColor: theme.bgColor, // ✅ Adaptive Background
      body: Stack(
        children: [
          // KONTEN UTAMA - Paling Bawah di Stack
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 140, 20, 150),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherCard(theme), // Pass theme
                    const SizedBox(height: 30),
                    Text(
                      lang.translate('dashboard.environmentStatus'),
                      style: TextStyle(
                        color: theme.textColor, // ✅ Adaptive Text
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildStatCard(
                          lang.translate('dashboard.airQuality'),
                          aqiInfo['status'],
                          Icons.air,
                          aqiInfo['color'],
                          theme,
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                          lang.translate('dashboard.uvIndex'),
                          uvInfo['status'],
                          Icons.sunny,
                          uvInfo['color'],
                          theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildTipsCard(environmentalTips, lang, theme),
                    const SizedBox(height: 30),
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
              onProfileTap: () => Navigator.of(context).push(_createRoute()),
            ),
          ),
        ],
      ),
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
            Divider(color: theme.textColor.withOpacity(0.1), height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                recommendationList.isNotEmpty
                    ? recommendationList[currentRecIndex]
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
                  recommendationList.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentRecIndex == i
                          ? const Color(0xFF008BFF)
                          : theme.textColor.withOpacity(0.2),
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
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF008BFF),
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
                color: theme.textColor.withOpacity(0.54),
                fontSize: 12,
              ),
            ),
          ),
          Divider(color: theme.textColor.withOpacity(0.1), height: 1),
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
}
