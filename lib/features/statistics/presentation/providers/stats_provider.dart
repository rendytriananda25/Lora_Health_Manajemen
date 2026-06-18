import 'package:flutter/foundation.dart';
import 'package:lora_1/features/statistics/domain/entities/stats_entity.dart';
import 'package:lora_1/features/statistics/domain/repositories/stats_repository.dart';
import 'package:lora_1/features/statistics/domain/usecases/process_statistics.dart';

class StatsProvider extends ChangeNotifier {
  final StatsRepository _repository;
  final ProcessStatistics _processStatistics;
  final AnalyzePerformance _analyzePerformance;
  final TranslateStatsSport _translateSport;

  StatsProvider({required StatsRepository repository})
      : _repository = repository,
        _processStatistics = ProcessStatistics(),
        _analyzePerformance = AnalyzePerformance(),
        _translateSport = TranslateStatsSport();

  bool isLoading = true;
  List<Map<String, dynamic>> allHistory = [];
  List<String> availableSports = [];
  String selectedSport = 'LARI';

  StatsSummaryEntity stats = StatsSummaryEntity.empty();
  PerformanceFeedback? feedback;

  String translateSportName(String sport, String Function(String) translate) =>
      _translateSport(sport, translate);

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    List<String> defaultSports = ['LARI', 'HOME WORKOUT', 'SEPEDA'];

    final sportsResult = await _repository.getUserSports();
    List<String> userSports = sportsResult.fold(
      (_) => [],
      (data) => data,
    );

    final historyResult = await _repository.getWorkoutHistory();
    historyResult.fold(
      (failure) {
        debugPrint('History Error: ${failure.message}');
        availableSports = defaultSports;
        selectedSport = defaultSports.first;
      },
      (data) {
        allHistory = data;

        Set<String> historySports = {};
        for (var entry in allHistory) {
          if (entry['activity'] != null) {
            historySports.add(entry['activity'].toString().toUpperCase());
          }
        }

        Set<String> combined = {...userSports, ...historySports};
        availableSports = combined.isNotEmpty ? combined.toList() : defaultSports;
        selectedSport = availableSports.first;
      },
    );

    _filterAndProcess(selectedSport);

    isLoading = false;
    notifyListeners();
  }

  void selectSport(String sport, String Function(String) translate) {
    _filterAndProcess(sport);
    _generateFeedback(translate);
    notifyListeners();
  }

  void _filterAndProcess(String sport) {
    selectedSport = sport;

    stats = _processStatistics(
      allHistory: allHistory,
      sport: sport,
    );
  }

  void _generateFeedback(String Function(String) translate) {
    List<Map<String, dynamic>> filtered = allHistory.where((e) {
      String act = e['activity']?.toString().toUpperCase() ?? '';
      String searchSport = selectedSport.toUpperCase();
      if (searchSport.contains('BMI') && act.contains('BMI')) return true;
      return act == searchSport;
    }).toList();

    feedback = _analyzePerformance(
      filteredData: filtered,
      translate: translate,
    );
  }

  Future<void> initWithLanguage(String Function(String) translate) async {
    await init();
    _generateFeedback(translate);
    notifyListeners();
  }
}
