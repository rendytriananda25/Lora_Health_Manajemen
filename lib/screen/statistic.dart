import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // Data Mentah
  List<Map<String, dynamic>> allHistory = [];
  List<String> availableSports = [];
  String selectedSport = "LARI";

  // Data Statistik
  int totalSessions = 0;
  int totalCalories = 0;
  double totalDistance = 0.0;
  int totalDurationMin = 0;

  // Data Rekor
  Map<String, int> maxRepsRecord = {};
  double maxDistanceRecord = 0.0;

  // Data Grafik
  List<Map<String, dynamic>> chartData = [];

  // Data khusus CEK BMI
  List<Map<String, dynamic>> bmiWeightData = [];

  // 🔥 VARIABEL BARU: STATUS PERFORMA (NOTIFIKASI)
  String feedbackMessage = "";
  String feedbackTitle = "";
  Color feedbackColor = const Color(0xFF1C1C1E);
  IconData feedbackIcon = Icons.info;
  bool showFeedback = false;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    List<String> defaultSports = ["LARI", "HOME WORKOUT", "SEPEDA"];

    if (user == null) {
      _setDefaults(defaultSports);
      return;
    }

    try {
      final db = FirebaseDatabase.instance.ref();

      // 1. AMBIL OLAHRAGA PILIHAN USER
      final sportsSnapshot = await db.child("users/${user.uid}/sports").get();
      List<String> userSelectedSports = [];

      if (sportsSnapshot.exists) {
        if (sportsSnapshot.value is Map) {
          Map<dynamic, dynamic> data = sportsSnapshot.value as Map;
          data.forEach((key, value) {
            if (value == true) {
              String s = key.toString().toUpperCase();
              if (s.contains('BMI')) s = 'CEK BMI';
              if (s.contains('HOME')) s = 'HOME WORKOUT';
              userSelectedSports.add(s);
            }
          });
        } else if (sportsSnapshot.value is List) {
          List<dynamic> data = sportsSnapshot.value as List;
          for (var item in data) {
            if (item != null) {
              String s = item.toString().toUpperCase();
              if (s.contains('BMI')) s = 'CEK BMI';
              if (s.contains('HOME')) s = 'HOME WORKOUT';
              userSelectedSports.add(s);
            }
          }
        }
      }

      if (userSelectedSports.isEmpty) {
        userSelectedSports = ["LARI", "HOME WORKOUT"];
      }

      // 2. AMBIL HISTORY
      final historySnapshot = await db.child("users/${user.uid}/history").get();
      List<Map<String, dynamic>> loadedHistory = [];
      Set<String> historySports = {};

      if (historySnapshot.exists && historySnapshot.value != null) {
        final data = historySnapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            final entry = Map<String, dynamic>.from(value as Map);
            if (entry['time'] != null) {
              entry['date_obj'] = DateTime.parse(entry['time']);

              if (entry['activity'] != null) {
                // Standarisasi nama activity menjadi uppercase
                String actString = entry['activity'].toString().toUpperCase();
                // Jika mengandung HOME, standardise ke HOME WORKOUT
                if (actString.contains('HOME')) {
                  actString = 'HOME WORKOUT';
                }
                // Jika mengandung BMI (misal 'CEK BMI: 28.1'), normalkan ke 'CEK BMI'
                if (actString.contains('BMI')) {
                  actString = 'CEK BMI';
                }
                entry['activity'] = actString;
                historySports.add(actString);
              }

              loadedHistory.add(entry);
            }
          } catch (e) {
            debugPrint("Skip data rusak: $e");
          }
        });
        loadedHistory.sort((a, b) => a['date_obj'].compareTo(b['date_obj']));
      }

      if (mounted) {
        setState(() {
          allHistory = loadedHistory;
          Set<String> combinedSports = {
            ...userSelectedSports,
            ...historySports,
          };
          availableSports = combinedSports.toList();

          if (availableSports.isNotEmpty) {
            selectedSport = availableSports.first;
            _filterDataBySport(selectedSport);
          } else {
            _setDefaults(defaultSports);
          }
        });
      }
    } catch (e) {
      debugPrint("Error Fetching Data: $e");
      _setDefaults(defaultSports);
    }
  }

  void _setDefaults(List<String> defaults) {
    if (mounted) {
      setState(() {
        availableSports = defaults;
        selectedSport = defaults.first;
        _filterDataBySport(selectedSport);
        isLoading = false;
      });
    }
  }

  void _filterDataBySport(String sport) {
    List<Map<String, dynamic>> filtered = allHistory
        .where((e) {
          String act = e['activity']?.toString().toUpperCase() ?? '';
          String searchSport = sport.toUpperCase();
          if (searchSport.contains('BMI') && act.contains('BMI')) return true;
          return act == searchSport;
        })
        .toList();

    int tSessions = 0;
    int tCal = 0;
    int tSec = 0;
    double tDist = 0.0;

    Map<String, int> tempMaxReps = {};
    double tempMaxDist = 0.0;
    List<Map<String, dynamic>> tempChart = [];

    for (var entry in filtered) {
      tSessions++;
      tCal += (entry['calories'] as num? ?? 0).toInt();
      tSec += (entry['duration_sec'] as num? ?? 0).toInt();

      double dist = (entry['distance_km'] as num? ?? 0.0).toDouble();
      tDist += dist;
      if (dist > tempMaxDist) tempMaxDist = dist;

      if (sport == "HOME WORKOUT" && entry['details'] != null) {
        _parseMaxReps(entry['details'].toString(), tempMaxReps);
      }

      tempChart.add({
        "label":
            "${(entry['date_obj'] as DateTime).day}/${(entry['date_obj'] as DateTime).month}",
        "value": (entry['calories'] as num? ?? 0).toDouble(),
      });
    }

    // 🔥 LOGIC ANALISA PERFORMA (NOTIFIKASI) 🔥
    _generatePerformanceFeedback(filtered);

    // Logic Dummy Chart
    if (tempChart.length < 7) {
      DateTime now = DateTime.now();
      List<Map<String, dynamic>> finalChart = [];
      for (int i = 6; i >= 0; i--) {
        DateTime d = now.subtract(Duration(days: i));
        String label = "${d.day}/${d.month}";

        var existing = tempChart.firstWhere(
          (e) => e['label'] == label,
          orElse: () => {"label": label, "value": 0.0},
        );
        finalChart.add(existing);
      }
      tempChart = finalChart;
    } else {
      tempChart = tempChart.sublist(tempChart.length - 7);
    }

    setState(() {
      selectedSport = sport;
      totalSessions = tSessions;
      totalCalories = tCal;
      totalDurationMin = tSec ~/ 60;
      totalDistance = tDist;

      maxDistanceRecord = tempMaxDist;
      maxRepsRecord = tempMaxReps;
      chartData = tempChart;

      // Populate bmiWeightData untuk tampilan CEK BMI
      if (sport.contains('BMI')) {
        bmiWeightData = filtered
            .where((e) => (e['weight'] as num?) != null)
            .map((e) => {
                  'date_obj': e['date_obj'],
                  'weight_val': (e['weight'] as num).toDouble(),
                  'bmi_score': e['bmi_score']?.toString() ?? '--',
                  'status': e['status']?.toString() ?? 'Normal',
                })
            .toList();
        bmiWeightData.sort((a, b) =>
            (a['date_obj'] as DateTime).compareTo(b['date_obj'] as DateTime));
      } else {
        bmiWeightData = [];
      }

      isLoading = false;
    });
  }

  // ✅ LOGIC BARU: MEMBANDINGKAN SESI TERAKHIR VS SEBELUMNYA
  void _generatePerformanceFeedback(List<Map<String, dynamic>> filteredData) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (filteredData.length < 2) {
      feedbackTitle = lang.translate('stats.welcomeTitle');
      feedbackMessage = lang.translate('stats.welcomeMsg');
      feedbackColor = const Color(0xFF1C1C1E);
      feedbackIcon = Icons.auto_graph;
      showFeedback = true;
      return;
    }

    var lastSession = filteredData.last;
    var prevSession = filteredData[filteredData.length - 2];

    int lastCal = (lastSession['calories'] as num? ?? 0).toInt();
    int prevCal = (prevSession['calories'] as num? ?? 0).toInt();

    if (lastCal > prevCal) {
      feedbackTitle = lang.translate('stats.perfUp');
      int diff = lastCal - prevCal;
      feedbackMessage = lang
          .translate('stats.perfUpMsg')
          .replaceAll('{diff}', '$diff');
      feedbackColor = Colors.green.withOpacity(0.2);
      feedbackIcon = Icons.trending_up;
    } else if (lastCal < prevCal) {
      feedbackTitle = lang.translate('stats.perfDown');
      feedbackMessage = lang.translate('stats.perfDownMsg');
      feedbackColor = Colors.orange.withOpacity(0.2);
      feedbackIcon = Icons.trending_down;
    } else {
      feedbackTitle = lang.translate('stats.perfStable');
      feedbackMessage = lang.translate('stats.perfStableMsg');
      feedbackColor = Colors.blue.withOpacity(0.2);
      feedbackIcon = Icons.remove;
    }
    showFeedback = true;
  }

  // Helper fungsi terjemah olahraga
  String _translateSportName(String sport, LanguageProvider lang) {
    String s = sport.toUpperCase();
    if (s.contains("LARI") || s.contains("RUN")) return lang.translate('sports.running');
    if (s.contains("SEPEDA") || s.contains("CYCL")) return lang.translate('sports.cycling');
    if (s.contains("BASKET")) return lang.translate('sports.basketball');
    if (s.contains("BOLA") || s.contains("FOOT") || s.contains("SOCCER")) return lang.translate('sports.football');
    if (s.contains("JALAN") || s.contains("WALK")) return lang.translate('sports.walking');
    if (s.contains("RENANG") || s.contains("SWIM")) return lang.translate('sports.swimming');
    if (s.contains("BMI")) return "CEK BMI";
    if (s.contains("HOME")) {
      String trans = lang.translate('notification.reminder.sport.homeWorkout');
      return trans.contains('.sport.homeWorkout') ? "Home Workout" : trans;
    }
    return sport;
  }

  void _parseMaxReps(String details, Map<String, int> records) {
    try {
      List<String> items = details.split(", ");
      for (var item in items) {
        if (item.contains(":")) {
          var parts = item.split(":");
          String name = parts[0].trim();
          String valStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
          int val = int.tryParse(valStr) ?? 0;

          if (!records.containsKey(name) || val > records[name]!) {
            records[name] = val;
          }
        }
      }
    } catch (e) {
      debugPrint("Error parsing details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    // Dynamic Feedback Color base on Theme
    Color adaptiveFeedbackColor = feedbackColor;
    if (!theme.isDarkMode && feedbackIcon == Icons.auto_graph) {
      adaptiveFeedbackColor = theme.boxColor;
    }

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          lang.translate('stats.title'),
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        leading: BackButton(color: theme.textColor),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF008BFF)),
            )
          : availableSports.isEmpty
          ? Center(
              child: Text(
                lang.translate('stats.noData'),
                style: TextStyle(color: theme.textColor.withOpacity(0.54)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SELECTOR OLAHRAGA
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableSports.map((sport) {
                        bool isSelected = sport == selectedSport;
                        return GestureDetector(
                          onTap: () => _filterDataBySport(sport),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF008BFF)
                                  : theme.boxColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF008BFF)
                                    : theme.textColor.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              _translateSportName(sport, Provider.of<LanguageProvider>(context, listen: false)),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.textColor.withOpacity(0.54),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── CONDITIONAL: CEK BMI vs Olahraga biasa ──────────
                  if (selectedSport.contains('BMI'))
                    _buildBmiSection(theme)
                  else ...
                    [
                      // ✅ 2. KARTU NOTIFIKASI / INSIGHT
                      if (showFeedback)
                        _buildPerformanceInsight(theme, adaptiveFeedbackColor),

                      const SizedBox(height: 20),

                      // 3. GRID RINGKASAN
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              lang.translate('stats.totalSessions'),
                              "$totalSessions",
                              Icons.fitness_center,
                              Colors.orange,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildStatCard(
                              lang.translate('stats.totalCalories'),
                              "$totalCalories",
                              Icons.local_fire_department,
                              Colors.redAccent,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      if (selectedSport == "LARI" ||
                          selectedSport == "SEPEDA" ||
                          selectedSport == "JALAN")
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                lang.translate('stats.totalDistance'),
                                "${totalDistance.toStringAsFixed(1)} km",
                                Icons.map,
                                Colors.greenAccent,
                                theme,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                lang.translate('stats.totalTime'),
                                "$totalDurationMin ${lang.translate('stats.min')}",
                                Icons.timer,
                                Colors.blueAccent,
                                theme,
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard(
                            lang.translate('stats.totalTime'),
                            "$totalDurationMin ${lang.translate('stats.min')}",
                            Icons.timer,
                            Colors.blueAccent,
                            theme,
                          ),
                        ),

                      const SizedBox(height: 30),

                      Text(
                        lang
                            .translate('stats.calorieChart')
                            .replaceAll('{sport}', _translateSportName(selectedSport, Provider.of<LanguageProvider>(context, listen: false))),
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildSimpleChart(theme),

                      const SizedBox(height: 30),

                      Text(
                        lang
                            .translate('stats.bestRecord')
                            .replaceAll('{sport}', _translateSportName(selectedSport, Provider.of<LanguageProvider>(context, listen: false))),
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      if (selectedSport == "HOME WORKOUT")
                        _buildHomeWorkoutRecords(theme)
                      else
                        _buildCardioRecords(theme),

                      const SizedBox(height: 50),
                    ], // Closes the else ... [
                ], // Closes the children: [
              ),
            ),
    );
  }

  // ✅ WIDGET TAMPILAN NOTIFIKASI / INSIGHT
  Widget _buildPerformanceInsight(ThemeProvider theme, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor, // Warna berubah sesuai performa
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Icon(feedbackIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedbackTitle,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  feedbackMessage,
                  style: TextStyle(
                    color: theme.textColor.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String val,
    IconData icon,
    Color color,
    ThemeProvider theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.boxColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.textColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(
            val,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: theme.textColor.withOpacity(0.54),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(ThemeProvider theme) {
    double maxValue = 100;
    if (chartData.isNotEmpty) {
      double maxFound = 0;
      for (var item in chartData) {
        double v = (item['value'] as num).toDouble();
        if (v > maxFound) maxFound = v;
      }
      if (maxFound > 0) maxValue = maxFound;
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.boxColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.textColor.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: chartData.map((e) {
          double val = (e['value'] as num).toDouble();
          double height = (val / maxValue) * 90;

          Color barColor = val > 0
              ? const Color(0xFF008BFF)
              : theme.textColor.withOpacity(0.1);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                val > 0 ? val.toInt().toString() : "-",
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                width: 20,
                height: val > 0 ? height : 2,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e['label'],
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.38),
                  fontSize: 10,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHomeWorkoutRecords(ThemeProvider theme) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (maxRepsRecord.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.boxColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.textColor.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            lang.translate('stats.noMovementRecord'),
            style: TextStyle(color: theme.textColor.withOpacity(0.54)),
          ),
        ),
      );
    }

    return Column(
      children: maxRepsRecord.entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.boxColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.textColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.amber,
                radius: 18,
                child: Icon(Icons.emoji_events, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  e.key,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                "${e.value} Reps",
                style: const TextStyle(
                  color: Color(0xFF008BFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardioRecords(ThemeProvider theme) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.boxColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.textColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            color: maxDistanceRecord > 0
                ? Colors.amber
                : theme.textColor.withOpacity(0.24),
            size: 40,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.translate('stats.longestDistance'),
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.54),
                  fontSize: 12,
                ),
              ),
              Text(
                maxDistanceRecord > 0
                    ? "${maxDistanceRecord.toStringAsFixed(2)} KM"
                    : "-- KM",
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGET KHUSUS CEK BMI
  // ─────────────────────────────────────────────────────────────
  Widget _buildBmiSection(ThemeProvider theme) {
    if (bmiWeightData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Icon(
              Icons.monitor_weight_outlined,
              size: 64,
              color: theme.textColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat CEK BMI',
              style: TextStyle(
                color: theme.textColor.withOpacity(0.38),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cek BMI kamu dulu di menu BMI',
              style: TextStyle(
                color: theme.textColor.withOpacity(0.24),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeightChart(theme),
        const SizedBox(height: 28),
        Text(
          'Riwayat Pengecekan',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        _buildDateList(theme),
      ],
    );
  }

  Widget _buildWeightChart(ThemeProvider theme) {
    // 1. Buat data chart 7 slot (seperti _buildSimpleChart)
    List<Map<String, dynamic>> finalChart = [];
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime d = now.subtract(Duration(days: i));
      // Cari apakah ada data BMI di tanggal ini
      var existing = bmiWeightData.cast<Map<String, dynamic>?>().lastWhere(
        (e) {
          if (e == null) return false;
          DateTime eDate = e['date_obj'] as DateTime;
          return eDate.day == d.day && eDate.month == d.month && eDate.year == d.year;
        },
        orElse: () => null,
      );

      if (existing != null) {
        finalChart.add({
          "label": "${d.day}/${d.month}",
          "weight_val": (existing['weight_val'] as num).toDouble(),
        });
      } else {
        finalChart.add({
          "label": "${d.day}/${d.month}",
          "weight_val": 0.0,
        });
      }
    }

    double maxValue = 150; // default maximum
    double maxFound = 0;
    for (var item in finalChart) {
      double v = (item['weight_val'] as num).toDouble();
      if (v > maxFound) maxFound = v;
    }
    if (maxFound > 0) maxValue = maxFound + 10;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.boxColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.textColor.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: finalChart.map((e) {
          double val = (e['weight_val'] as num).toDouble();
          double height = (val / maxValue) * 90;
          String label = e['label'];

          Color barColor = val > 0
              ? const Color(0xFF008BFF)
              : theme.textColor.withOpacity(0.1);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                val > 0 ? val.toStringAsFixed(1) : "-",
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                width: 20,
                height: val > 0 ? height : 2,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.38),
                  fontSize: 10,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateList(ThemeProvider theme) {
    final reversed = bmiWeightData.reversed.toList();

    return Column(
      children: List.generate(reversed.length, (i) {
        final entry = reversed[i];
        final date = entry['date_obj'] as DateTime;
        final weight = (entry['weight_val'] as double).toStringAsFixed(1);
        final status = (entry['status'] ?? 'Normal').toString();
        final bmi = entry['bmi_score']?.toString() ?? '--';

        final dateStr = DateFormat('EEEE, dd MMM yyyy').format(date);
        final timeStr = DateFormat('HH:mm').format(date);
        final statusColor = _statusColor(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.boxColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.textColor.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              // Dot status
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),

              // Tanggal & jam
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: theme.textColor.withOpacity(0.38),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.38),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Berat & status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$weight kg',
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'BMI $bmi',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('UNDER') || s.contains('KURANG')) return Colors.blue;
    if (s.contains('NORMAL') || s.contains('IDEAL')) return Colors.green;
    if (s.contains('OBES')) return Colors.red;
    if (s.contains('OVER')) return Colors.orange;
    return Colors.green;
  }
}
