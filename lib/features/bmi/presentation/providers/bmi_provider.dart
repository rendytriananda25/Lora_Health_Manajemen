import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lora_1/features/bmi/domain/usecases/calculate_bmi.dart';
import 'package:lora_1/features/bmi/domain/usecases/save_bmi_history.dart';

class BmiProvider extends ChangeNotifier {
  final CalculateBmi _calculateBmiUseCase;
  final SaveBmiHistory _saveBmiHistoryUseCase;

  BmiProvider({
    required CalculateBmi calculateBmi,
    required SaveBmiHistory saveBmiHistory,
  })  : _calculateBmiUseCase = calculateBmi,
        _saveBmiHistoryUseCase = saveBmiHistory {
    _initAudio();
  }

  final PageController pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime _lastPlayTime = DateTime.now();

  int currentPage = 0;
  int height = 170;
  int weight = 60;
  int age = 24;

  double bmiResult = 0;
  String bmiStatus = "";
  Color statusColor = Colors.green;

  void _initAudio() async {
    await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  void playPremiumTick() async {
    final now = DateTime.now();
    if (now.difference(_lastPlayTime).inMilliseconds < 50) return;
    _lastPlayTime = now;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/click.wav'));
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  void setHeight(int val) {
    height = val;
    notifyListeners();
  }

  void setWeight(int val) {
    weight = val;
    notifyListeners();
  }

  void calculateBMI() {
    final result = _calculateBmiUseCase(weightKg: weight, heightCm: height);
    bmiResult = result.score;
    bmiStatus = result.status;
    statusColor = Color(result.colorHex);
    notifyListeners();

    _saveBmiHistoryUseCase(
      score: bmiResult,
      status: bmiStatus,
      weight: weight,
      height: height,
    );
  }

  void nextPage() {
    if (currentPage >= 2) return;

    HapticFeedback.mediumImpact();
    _audioPlayer.stop();

    try {
      _audioPlayer.play(AssetSource('sounds/click.wav'));
    } catch (e) {
      debugPrint("Audio play error: $e");
    }

    pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
    );

    if (currentPage == 1) calculateBMI();
    currentPage++;
    notifyListeners();
  }

  void prevPage() {
    if (currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
      currentPage--;
      notifyListeners();
    }
  }

  void reset() {
    pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
    currentPage = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
