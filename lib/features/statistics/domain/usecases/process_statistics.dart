import 'package:flutter/material.dart';
import 'package:lora_1/features/statistics/domain/entities/stats_entity.dart';

/// UseCase: Proses data history mentah → StatsSummaryEntity.
///
/// Semua logika filtering, kalkulasi total, chart data, dan record
/// dipindahkan dari _filterDataBySport() di statistic.dart.
class ProcessStatistics {
  /// Filter dan hitung statistik berdasarkan olahraga yang dipilih.
  StatsSummaryEntity call({
    required List<Map<String, dynamic>> allHistory,
    required String sport,
  }) {
    // Filter data berdasarkan sport
    List<Map<String, dynamic>> filtered = allHistory.where((e) {
      String act = e['activity']?.toString().toUpperCase() ?? '';
      String searchSport = sport.toUpperCase();
      if (searchSport.contains('BMI') && act.contains('BMI')) return true;
      return act == searchSport;
    }).toList();

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

      if (sport == 'HOME WORKOUT' && entry['details'] != null) {
        _parseMaxReps(entry['details'].toString(), tempMaxReps);
      }

      tempChart.add({
        'label': "${(entry['date_obj'] as DateTime).day}/${(entry['date_obj'] as DateTime).month}",
        'value': (entry['calories'] as num? ?? 0).toDouble(),
      });
    }

    // Pad chart data ke 7 hari
    tempChart = _padChartTo7Days(tempChart);

    // BMI weight data
    List<Map<String, dynamic>> bmiData = [];
    if (sport.contains('BMI')) {
      bmiData = filtered
          .where((e) => (e['weight'] as num?) != null)
          .map((e) => {
                'date_obj': e['date_obj'],
                'weight_val': (e['weight'] as num).toDouble(),
                'bmi_score': e['bmi_score']?.toString() ?? '--',
                'status': e['status']?.toString() ?? 'Normal',
              })
          .toList();
      bmiData.sort((a, b) =>
          (a['date_obj'] as DateTime).compareTo(b['date_obj'] as DateTime));
    }

    return StatsSummaryEntity(
      totalSessions: tSessions,
      totalCalories: tCal,
      totalDistance: tDist,
      totalDurationMin: tSec ~/ 60,
      maxDistanceRecord: tempMaxDist,
      maxRepsRecord: tempMaxReps,
      chartData: tempChart,
      bmiWeightData: bmiData,
    );
  }

  List<Map<String, dynamic>> _padChartTo7Days(List<Map<String, dynamic>> raw) {
    if (raw.length >= 7) return raw.sublist(raw.length - 7);

    DateTime now = DateTime.now();
    List<Map<String, dynamic>> result = [];
    for (int i = 6; i >= 0; i--) {
      DateTime d = now.subtract(Duration(days: i));
      String label = "${d.day}/${d.month}";
      var existing = raw.firstWhere(
        (e) => e['label'] == label,
        orElse: () => {'label': label, 'value': 0.0},
      );
      result.add(existing);
    }
    return result;
  }

  void _parseMaxReps(String details, Map<String, int> records) {
    try {
      List<String> items = details.split(', ');
      for (var item in items) {
        if (item.contains(':')) {
          var parts = item.split(':');
          String name = parts[0].trim();
          String valStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
          int val = int.tryParse(valStr) ?? 0;
          if (!records.containsKey(name) || val > records[name]!) {
            records[name] = val;
          }
        }
      }
    } catch (_) {}
  }
}

/// UseCase: Analisa performa (bandingkan sesi terakhir vs sebelumnya).
///
/// Logika ini dipindahkan dari _generatePerformanceFeedback() di statistic.dart.
class AnalyzePerformance {
  PerformanceFeedback call({
    required List<Map<String, dynamic>> filteredData,
    required String Function(String) translate,
  }) {
    if (filteredData.length < 2) {
      return PerformanceFeedback(
        title: translate('stats.welcomeTitle'),
        message: translate('stats.welcomeMsg'),
        color: const Color(0xFF1C1C1E),
        icon: Icons.auto_graph,
      );
    }

    var lastSession = filteredData.last;
    var prevSession = filteredData[filteredData.length - 2];

    int lastCal = (lastSession['calories'] as num? ?? 0).toInt();
    int prevCal = (prevSession['calories'] as num? ?? 0).toInt();

    if (lastCal > prevCal) {
      int diff = lastCal - prevCal;
      return PerformanceFeedback(
        title: translate('stats.perfUp'),
        message: translate('stats.perfUpMsg').replaceAll('{diff}', '$diff'),
        color: Colors.green.withOpacity(0.2),
        icon: Icons.trending_up,
      );
    } else if (lastCal < prevCal) {
      return PerformanceFeedback(
        title: translate('stats.perfDown'),
        message: translate('stats.perfDownMsg'),
        color: Colors.orange.withOpacity(0.2),
        icon: Icons.trending_down,
      );
    } else {
      return PerformanceFeedback(
        title: translate('stats.perfStable'),
        message: translate('stats.perfStableMsg'),
        color: Colors.blue.withOpacity(0.2),
        icon: Icons.remove,
      );
    }
  }
}

/// UseCase: Translate sport name.
class TranslateStatsSport {
  String call(String sport, String Function(String) translate) {
    String s = sport.toUpperCase();
    if (s.contains('LARI') || s.contains('RUN')) return translate('sports.running');
    if (s.contains('SEPEDA') || s.contains('CYCL')) return translate('sports.cycling');
    if (s.contains('BASKET')) return translate('sports.basketball');
    if (s.contains('BOLA') || s.contains('FOOT') || s.contains('SOCCER')) return translate('sports.football');
    if (s.contains('JALAN') || s.contains('WALK')) return translate('sports.walking');
    if (s.contains('RENANG') || s.contains('SWIM')) return translate('sports.swimming');
    if (s.contains('BMI')) return 'CEK BMI';
    if (s.contains('HOME')) {
      String trans = translate('notification.reminder.sport.homeWorkout');
      return trans.contains('.sport.homeWorkout') ? 'Home Workout' : trans;
    }
    return sport;
  }
}
