import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

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
            if (value == true) userSelectedSports.add(key.toString());
          });
        } else if (sportsSnapshot.value is List) {
          List<dynamic> data = sportsSnapshot.value as List;
          for (var item in data) {
            if (item != null) userSelectedSports.add(item.toString());
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
              loadedHistory.add(entry);
              if (entry['activity'] != null)
                historySports.add(entry['activity']);
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
        .where((e) => e['activity'] == sport)
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
                              sport,
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

                  // ✅ 2. WIDGET BARU: KARTU NOTIFIKASI / INSIGHT
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
                        .replaceAll('{sport}', selectedSport),
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
                        .replaceAll('{sport}', selectedSport),
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
                ],
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
      height: 180,
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
          double height = (val / maxValue) * 100;

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
}
