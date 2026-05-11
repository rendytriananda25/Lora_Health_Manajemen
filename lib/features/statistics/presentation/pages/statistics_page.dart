import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/features/statistics/presentation/providers/stats_provider.dart';

import '../widgets/charts.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      Provider.of<StatsProvider>(context, listen: false).initWithLanguage(lang.translate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Consumer<StatsProvider>(
      builder: (context, statsProvider, child) {
        Color adaptiveFeedbackColor = statsProvider.feedback?.color ?? Colors.transparent;
        if (!theme.isDarkMode && statsProvider.feedback?.icon == Icons.auto_graph) {
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
          body: statsProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF008BFF)),
                )
              : statsProvider.availableSports.isEmpty
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: statsProvider.availableSports.map((sport) {
                                bool isSelected = sport == statsProvider.selectedSport;
                                return GestureDetector(
                                  onTap: () => statsProvider.selectSport(sport, lang.translate),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF008BFF) : theme.boxColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF008BFF)
                                            : theme.textColor.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Text(
                                      statsProvider.translateSportName(sport, lang.translate),
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

                          if (statsProvider.selectedSport.contains('BMI'))
                            _buildBmiSection(theme, statsProvider, lang)
                          else ...[
                            if (statsProvider.feedback != null)
                              _buildPerformanceInsight(theme, adaptiveFeedbackColor, statsProvider),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    lang.translate('stats.totalSessions'),
                                    "${statsProvider.stats.totalSessions}",
                                    Icons.fitness_center,
                                    Colors.orange,
                                    theme,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildStatCard(
                                    lang.translate('stats.totalCalories'),
                                    "${statsProvider.stats.totalCalories}",
                                    Icons.local_fire_department,
                                    Colors.redAccent,
                                    theme,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            if (statsProvider.selectedSport == "LARI" ||
                                statsProvider.selectedSport == "SEPEDA" ||
                                statsProvider.selectedSport == "JALAN")
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      lang.translate('stats.totalDistance'),
                                      "${statsProvider.stats.totalDistance.toStringAsFixed(1)} km",
                                      Icons.map,
                                      Colors.greenAccent,
                                      theme,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: _buildStatCard(
                                      lang.translate('stats.totalTime'),
                                      "${statsProvider.stats.totalDurationMin} ${lang.translate('stats.min')}",
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
                                  "${statsProvider.stats.totalDurationMin} ${lang.translate('stats.min')}",
                                  Icons.timer,
                                  Colors.blueAccent,
                                  theme,
                                ),
                              ),

                            const SizedBox(height: 30),

                            Text(
                              lang.translate('stats.calorieChart').replaceAll(
                                  '{sport}',
                                  statsProvider.translateSportName(
                                      statsProvider.selectedSport, lang.translate)),
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildSimpleChart(theme, statsProvider),

                            const SizedBox(height: 30),

                            Text(
                              lang.translate('stats.bestRecord').replaceAll(
                                  '{sport}',
                                  statsProvider.translateSportName(
                                      statsProvider.selectedSport, lang.translate)),
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),

                            if (statsProvider.selectedSport == "HOME WORKOUT")
                              _buildHomeWorkoutRecords(theme, statsProvider, lang)
                            else
                              _buildCardioRecords(theme, statsProvider, lang),

                            const SizedBox(height: 50),
                          ],
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildPerformanceInsight(ThemeProvider theme, Color bgColor, StatsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
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
            child: Icon(provider.feedback!.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.feedback!.title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  provider.feedback!.message,
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

  Widget _buildSimpleChart(ThemeProvider theme, StatsProvider provider) {
    final chartData = provider.stats.chartData;
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

          Color barColor = val > 0 ? const Color(0xFF008BFF) : theme.textColor.withOpacity(0.1);

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

  Widget _buildHomeWorkoutRecords(ThemeProvider theme, StatsProvider provider, LanguageProvider lang) {
    final maxRepsRecord = provider.stats.maxRepsRecord;
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

  Widget _buildCardioRecords(ThemeProvider theme, StatsProvider provider, LanguageProvider lang) {
    final maxDistanceRecord = provider.stats.maxDistanceRecord;
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
            color: maxDistanceRecord > 0 ? Colors.amber : theme.textColor.withOpacity(0.24),
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
                maxDistanceRecord > 0 ? "${maxDistanceRecord.toStringAsFixed(2)} KM" : "-- KM",
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

  Widget _buildBmiSection(ThemeProvider theme, StatsProvider provider, LanguageProvider lang) {
    if (provider.stats.bmiWeightData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.boxColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.textColor.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(Icons.monitor_weight_outlined,
                size: 60, color: theme.textColor.withOpacity(0.2)),
            const SizedBox(height: 15),
            Text(
              "Belum ada data BMI",
              style: TextStyle(color: theme.textColor.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: provider.stats.bmiWeightData.reversed.take(5).map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.boxColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.textColor.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${e['weight_val']} KG",
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    e['status'],
                    style: TextStyle(
                      color: e['status'] == 'Normal' ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                "BMI: ${e['bmi_score']}",
                style: TextStyle(
                  color: const Color(0xFF008BFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
