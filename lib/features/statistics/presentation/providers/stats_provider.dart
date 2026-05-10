import 'package:flutter/foundation.dart';
import 'package:lora_1/features/statistics/domain/entities/stats_entity.dart';
import 'package:lora_1/features/statistics/domain/repositories/stats_repository.dart';
import 'package:lora_1/features/statistics/domain/usecases/process_statistics.dart';

/// ═══════════════════════════════════════════════════════════════
/// StatsProvider — State Management untuk halaman Statistics.
///
/// Widget hanya membaca state, TIDAK boleh melakukan:
/// - Akses Firebase
/// - Kalkulasi statistik
/// - Logika perbandingan performa
/// ═══════════════════════════════════════════════════════════════
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

  // ─── STATE ─────────────────────────────────────────────────
  bool isLoading = true;
  List<Map<String, dynamic>> allHistory = [];
  List<String> availableSports = [];
  String selectedSport = 'LARI';

  StatsSummaryEntity stats = StatsSummaryEntity.empty();
  PerformanceFeedback? feedback;

  // ─── PUBLIC ────────────────────────────────────────────────
  String translateSportName(String sport, String Function(String) translate) =>
      _translateSport(sport, translate);

  // ─── INIT ──────────────────────────────────────────────────
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    List<String> defaultSports = ['LARI', 'HOME WORKOUT', 'SEPEDA'];

    // 1. Ambil olahraga user
    final sportsResult = await _repository.getUserSports();
    List<String> userSports = sportsResult.fold(
      (_) => [],
      (data) => data,
    );

    // 2. Ambil history
    final historyResult = await _repository.getWorkoutHistory();
    historyResult.fold(
      (failure) {
        debugPrint('History Error: ${failure.message}');
        availableSports = defaultSports;
        selectedSport = defaultSports.first;
      },
      (data) {
        allHistory = data;

        // Gabungkan sports dari user + history
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

    // 3. Filter data awal
    _filterAndProcess(selectedSport);

    isLoading = false;
    notifyListeners();
  }

  /// Ganti olahraga yang dipilih & reprocess.
  void selectSport(String sport, String Function(String) translate) {
    _filterAndProcess(sport);
    _generateFeedback(translate);
    notifyListeners();
  }

  /// Proses ulang data untuk sport tertentu.
  void _filterAndProcess(String sport) {
    selectedSport = sport;

    // ✅ Delegasi ke UseCase (bukan hitung di sini)
    stats = _processStatistics(
      allHistory: allHistory,
      sport: sport,
    );
  }

  /// Generate feedback performa.
  void _generateFeedback(String Function(String) translate) {
    List<Map<String, dynamic>> filtered = allHistory.where((e) {
      String act = e['activity']?.toString().toUpperCase() ?? '';
      String searchSport = selectedSport.toUpperCase();
      if (searchSport.contains('BMI') && act.contains('BMI')) return true;
      return act == searchSport;
    }).toList();

    // ✅ Delegasi ke UseCase
    feedback = _analyzePerformance(
      filteredData: filtered,
      translate: translate,
    );
  }

  /// Init dengan language translate function.
  Future<void> initWithLanguage(String Function(String) translate) async {
    await init();
    _generateFeedback(translate);
    notifyListeners();
  }
}
