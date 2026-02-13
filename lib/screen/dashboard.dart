import 'dart:async'; 
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:lora_1/screen/statistic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lora_1/features/settings/setting_page.dart';

// ✅ FILE INI STANDALONE - TANPA KONEKSI KE PAGE MANAPUN
// Hanya untuk referensi atau testing isolasi

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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

  int currentAQI = 0;
  double currentUV = 0.0;
  String environmentalTips = "Menyiapkan tips untukmu...";

  final String apiKey = "d0fa6ab4f8080a9265e6a1bdf035fad0"; 

  final Map<String, dynamic> nutritionDatabase = {
    "NEVER": {
      "daily_focus": "Adaptasi metabolisme",
      "calorie_guideline": "Kalori maintenance",
      "protein_guideline": "0.8–1.0 g/kg BB",
      "hydration": "2–2.5 L/hari",
      "expert_note": "WHO: Pola makan seimbang untuk adaptasi tanpa stres metabolik."
    },
    "SOMETIMES": {
      "daily_focus": "Energi latihan ringan",
      "calorie_guideline": "Maintenance / Sedikit Defisit",
      "protein_guideline": "1.0–1.2 g/kg BB",
      "hydration": "2.5–3 L/hari",
      "expert_note": "ACSM: Tingkatkan protein seiring frekuensi latihan."
    },
    "OFTEN": {
      "daily_focus": "Pemulihan otot",
      "calorie_guideline": "Maintenance / Surplus Ringan",
      "protein_guideline": "1.4–1.6 g/kg BB",
      "hydration": "3–3.5 L/hari",
      "expert_note": "ISSN: Protein & Karbo penting untuk intensitas sedang-tinggi."
    },
    "DAILY": {
      "daily_focus": "Performa optimal",
      "calorie_guideline": "Surplus Terkontrol",
      "protein_guideline": "1.6–2.0 g/kg BB",
      "hydration": "3.5–4 L/hari",
      "expert_note": "ACSM: Fokus energi & hidrasi optimal untuk atlet harian."
    }
  };

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel(); 
    super.dispose();
  }

  void _startRecommendationRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && recommendationList.length > 1) {
        setState(() {
          currentRecIndex = (currentRecIndex + 1) % recommendationList.length;
        });
      }
    });
  }

  Future<void> _initDashboard() async {
    await _fetchUserProfile();
    await _fetchEnvironmentData();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        
        final level = prefs.getString('user_fitness_level') ?? "NEVER";
        final goal = prefs.getString('user_fitness_goal') ?? "KEEP_FIT";

        if (!mounted) return;
        setState(() {
          userName = user.displayName ?? "User";
          userLevel = level;
          userGoal = goal; 
        });
        
        final snapshot = await FirebaseDatabase.instance.ref("users/${user.uid}/favorite_sports").get();
        if (snapshot.exists) {
          userFavorites = List<String>.from(snapshot.value as List);
        }
      }
    } catch (e) {
      debugPrint("Firebase Error: $e");
    }
  }

  Map<String, dynamic> _getAQIDetail(int aqi) {
    if (aqi <= 50) return {"status": "Baik", "color": Colors.greenAccent, "tips": "Aman tanpa masker."};
    if (aqi <= 100) return {"status": "Sedang", "color": Colors.yellowAccent, "tips": "Asma harap waspada."};
    return {"status": "Tidak Sehat", "color": Colors.redAccent, "tips": "Gunakan masker!"};
  }

  Map<String, dynamic> _getUVDetail(double uv) {
    if (uv <= 2) return {"status": "Rendah", "color": Colors.greenAccent, "tips": "Aman luar ruangan."};
    if (uv <= 5) return {"status": "Sedang", "color": Colors.yellowAccent, "tips": "Gunakan sunscreen."};
    return {"status": "Tinggi", "color": Colors.orangeAccent, "tips": "Kurangi paparan siang."};
  }

  Future<void> _fetchEnvironmentData() async {
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    } catch (e) { debugPrint("GPS Error: $e"); }

    if (!mounted) return; 
    double lat = pos?.latitude ?? -7.9666;
    double lon = pos?.longitude ?? 112.6326;

    final weatherUrl = "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id";
    final aqiUrl = "https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey";

    try {
      final results = await Future.wait([http.get(Uri.parse(weatherUrl)), http.get(Uri.parse(aqiUrl))]);

      if (!mounted) return; 

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final wData = json.decode(results[0].body);
        final aData = json.decode(results[1].body);

        setState(() {
          apiTemp = wData['main']['temp'].toInt().toString();
          currentCity = wData['name'];
          weatherCondition = wData['weather'][0]['description'];
          
          int rawAQI = aData['list'][0]['main']['aqi'];
          currentAQI = rawAQI * 25;
          double clouds = wData['clouds']['all'].toDouble();
          currentUV = (100 - clouds) / 10;

          environmentalTips = "${_getAQIDetail(currentAQI)['tips']} ${_getUVDetail(currentUV)['tips']}";
          
          recommendationList = _generateSmartRecommendations(wData['main']['temp'].toDouble());
          _startRecommendationRotation();
        });
      }
    } catch (e) {
      if (mounted) setState(() => currentCity = "Koneksi Gagal");
    }
  }

  List<String> _generateSmartRecommendations(double temp) {
    if (userFavorites.isEmpty) return ["Yuk pilih olahraga dulu di Settings!"];
    List<String> tips = [];

    if (userGoal == "WEIGHT_LOSS") {
      tips.add("Fokus: Bakar kalori & kardio.");
      if (temp >= 28) {
        tips.add("Cuaca Panas: Latihan indoor / cardio sedang.");
      } else if (temp < 18) {
        tips.add("Cuaca Dingin: Pemanasan lebih lama.");
      } else {
        tips.add("Prioritas: Cardio, HIIT, atau Full Body Workout.");
      }
    } else if (userGoal == "MUSCLE_GAIN") {
      tips.add("Fokus: Kekuatan & repetisi.");
      if (temp >= 28) {
        tips.add("Cuaca Panas: Istirahat lebih sering.");
      } else {
        tips.add("Prioritas: Strength Training & Progressive Overload.");
      }
    } else {
      tips.add("Fokus: Latihan seimbang & santai.");
      tips.add("Prioritas: Low impact cardio & Mobility.");
    }
    return tips;
  }

  Map<String, dynamic> _getProcessedNutritionData() {
    Map<String, dynamic> baseData = nutritionDatabase[userLevel] ?? nutritionDatabase["NEVER"]!;
    Map<String, dynamic> finalData = Map.from(baseData);
    
    List<String> recommendedFoods = [];
    List<String> badFoods = [];
    String reasonGood = "";
    String reasonBad = "";

    if (userGoal == "WEIGHT_LOSS") {
      finalData['daily_focus'] = "Defisit Kalori & High Protein";
      recommendedFoods = ["Putih Telur", "Sayuran Hijau", "Teh Hijau/Kopi", "Apel/Berry"];
      badFoods = ["Gorengan", "Minuman Boba", "Roti Putih", "Junk Food"];
      reasonGood = "Rendah kalori, tinggi serat & protein.";
      reasonBad = "Kalori kosong, memicu penimbunan lemak.";
    } 
    else if (userGoal == "MUSCLE_GAIN") {
      finalData['daily_focus'] = "Surplus Kalori & Hypertrophy";
      recommendedFoods = ["Daging Sapi/Ayam", "Telur Utuh", "Nasi Merah/Oat", "Whey/Susu"];
      badFoods = ["Alkohol", "Keripik/Snack", "Gula Berlebih", "Soda"];
      reasonGood = "Sumber protein & karbohidrat untuk otot.";
      reasonBad = "Menghambat sintesis protein & recovery.";
    } 
    else { 
      recommendedFoods = ["Buah-buahan", "Ikan & Kacang", "Air Kelapa", "Yoghurt"];
      badFoods = ["Makanan Asin", "Margarin", "Jeroan", "Alkohol"];
      reasonGood = "Kaya vitamin & mineral untuk imunitas.";
      reasonBad = "Meningkatkan risiko darah tinggi/kolesterol.";
    }

    finalData['recommended_foods'] = recommendedFoods;
    finalData['bad_foods'] = badFoods;
    finalData['reason_good'] = reasonGood;
    finalData['reason_bad'] = reasonBad;
    
    return finalData;
  }

  IconData _getFoodIcon(String foodName) {
    String lower = foodName.toLowerCase();
    if (lower.contains("ayam") || lower.contains("daging") || lower.contains("sapi") || lower.contains("protein")) return Icons.dinner_dining;
    if (lower.contains("ikan") || lower.contains("seafood")) return Icons.set_meal;
    if (lower.contains("telur")) return Icons.egg;
    if (lower.contains("nasi") || lower.contains("oat") || lower.contains("bubur") || lower.contains("karbo")) return Icons.rice_bowl;
    if (lower.contains("roti") || lower.contains("kue") || lower.contains("snack") || lower.contains("keripik")) return Icons.bakery_dining;
    if (lower.contains("sayur") || lower.contains("buah") || lower.contains("salad") || lower.contains("apel")) return Icons.eco;
    if (lower.contains("susu") || lower.contains("yogurt") || lower.contains("keju") || lower.contains("whey")) return Icons.local_drink;
    if (lower.contains("kopi") || lower.contains("teh")) return Icons.local_cafe;
    if (lower.contains("air") || lower.contains("mineral") || lower.contains("kelapa")) return Icons.water_drop;
    if (lower.contains("gorengan") || lower.contains("burger") || lower.contains("pizza") || lower.contains("junk")) return Icons.fastfood;
    if (lower.contains("soda") || lower.contains("boba") || lower.contains("alkohol") || lower.contains("bir")) return Icons.local_bar;
    if (lower.contains("gula") || lower.contains("permen") || lower.contains("coklat") || lower.contains("es krim")) return Icons.icecream;
    
    return Icons.restaurant; 
  }

  Widget _buildSmartNutritionCard() {
    final data = _getProcessedNutritionData();
    final recommendedFoods = List<String>.from(data['recommended_foods']);
    final badFoods = List<String>.from(data['bad_foods']);
    
    List<Map<String, dynamic>> allFoods = [];
    
    for (var food in recommendedFoods) {
      allFoods.add({
        "name": food, 
        "rating": 5, 
        "desc": data['reason_good'], 
        "icon": _getFoodIcon(food),
        "type": "good"
      });
    }
    for (var food in badFoods) {
      allFoods.add({
        "name": food, 
        "rating": 2, 
        "desc": data['reason_bad'], 
        "icon": _getFoodIcon(food),
        "type": "bad"
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Text("Rekomendasi Nutrisi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Text(userGoal.replaceAll("_", " "), style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        
        const SizedBox(height: 15),
        
        SizedBox(
          height: 185, 
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false), // ✅ Fix 1: Hapus overscroll
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allFoods.length,
              physics: const ClampingScrollPhysics(), // ✅ Fix 2: Scroll berhenti saat mentok
              itemBuilder: (context, index) {
                final item = allFoods[index];
                bool isGood = item['type'] == "good";

                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: isGood ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item['icon'], color: isGood ? Colors.greenAccent : Colors.redAccent, size: 26),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      Icons.star, 
                                      size: 14, 
                                      color: starIndex < item['rating'] ? Colors.orangeAccent : Colors.grey[800]
                                    );
                                  }),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        item['desc'], 
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isGood ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                            isGood ? "Sangat Dianjurkan" : "Hindari / Batasi",
                            style: TextStyle(
                              color: isGood ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 11, fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("DASHBOARD PAGE - STANDALONE FILE", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_rounded, color: Colors.orange, size: 60),
            const SizedBox(height: 20),
            const Text(
              "FILE STANDALONE",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Ini file tidak terhubung ke page manapun\nGunakan untuk referensi atau testing isolasi",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Content Include:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildContentItem("✅ Full DashboardPage Class"),
                  _buildContentItem("✅ Weather API Integration"),
                  _buildContentItem("✅ Nutrition Database"),
                  _buildContentItem("✅ AQI & UV Index"),
                  _buildContentItem("✅ Smart Recommendations"),
                  _buildContentItem("✅ User Profile Fetching"),
                  _buildContentItem("✅ Helper Functions"),
                  _buildContentItem("✅ State Management"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12)),
    );
  }

  Widget _buildWeatherCard() {
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
                      Row(children: [const Icon(Icons.location_on, color: Colors.blueAccent, size: 16), const SizedBox(width: 5), Text(currentCity.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 5),
                      Text("$apiTemp° Celsius", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      Text(weatherCondition.toUpperCase(), style: const TextStyle(color: Color(0xFF008BFF), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 50),
              ],
            ),
            const Divider(color: Colors.white10, height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                recommendationList.isNotEmpty 
                  ? recommendationList[currentRecIndex] 
                  : "Memuat saran...",
                key: ValueKey<String>(recommendationList.isNotEmpty ? recommendationList[currentRecIndex] : ""),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            if (recommendationList.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(recommendationList.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentRecIndex == index ? const Color(0xFF008BFF) : Colors.white24,
                    ),
                  );
                }),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FITUR BARU: TOMBOL KE HALAMAN STATISTIK
  Widget _buildTipsCard(String tips) {
    return GlassCard(
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF008BFF), child: Icon(Icons.lightbulb_outline, color: Colors.white)),
            title: const Text("Saran Kesehatan", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(tips, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          const Divider(color: Colors.white12, height: 1),
          InkWell(
            onTap: () {
               // Pindah ke halaman Statistik
               Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsPage()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Lihat Progress Bulanan", style: TextStyle(color: Color(0xFF008BFF), fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward, color: Color(0xFF008BFF), size: 14)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8), 
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(_createRoute()), 
                  child: CircleAvatar(
                    radius: 22, 
                    backgroundColor: const Color(0xFF1C1C1E),
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null, 
                    child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white38) : null
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text("LORA HEALTH MANAGEMENT", style: TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold)), 
                      Text("Halo, $userName", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
                    ]
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(), transitionsBuilder: (context, animation, secondaryAnimation, child) { return SlideTransition(position: animation.drive(Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutQuart))), child: child); });
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))), child: child);
  }
}