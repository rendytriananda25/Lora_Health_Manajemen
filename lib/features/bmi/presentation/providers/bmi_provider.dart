import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
    _loadUserData();
  }

  final PageController pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime _lastPlayTime = DateTime.now();

  int currentPage = 0;
  int height = 170;
  int weight = 60;
  int age = 24;

  // Saved user registration values (used as defaults)
  int _savedHeight = 170;
  int _savedWeight = 60;
  bool isLoaded = false;
  int _resetCount = 0;
  int get resetCount => _resetCount;

  double bmiResult = 0;
  String bmiStatus = "";
  Color statusColor = Colors.green;

  void _initAudio() async {
    await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? savedHeight = prefs.getInt('user_height_cm');
      int? savedWeight = prefs.getInt('user_weight_kg');
      int? savedAge = prefs.getInt('user_age');

      // Fallback: jika data belum ada di SharedPreferences, ambil dari Firebase
      if (savedHeight == null || savedWeight == null) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final db = FirebaseDatabase.instanceFor(
              app: FirebaseAuth.instance.app,
              databaseURL:
                  "https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app",
            );
            final snapshot =
                await db.ref("users/${user.uid}/health_data").get();
            if (snapshot.exists) {
              final data = snapshot.value as Map;
              final fbHeight = data['height'];
              final fbWeight = data['weight'];
              final fbAge = data['age'];

              if (fbHeight != null && savedHeight == null) {
                savedHeight = (fbHeight is int)
                    ? fbHeight
                    : int.tryParse(fbHeight.toString());
                // Simpan ke SharedPreferences untuk akses cepat selanjutnya
                if (savedHeight != null) {
                  await prefs.setInt('user_height_cm', savedHeight);
                }
              }
              if (fbWeight != null && savedWeight == null) {
                savedWeight = (fbWeight is int)
                    ? fbWeight
                    : int.tryParse(fbWeight.toString());
                if (savedWeight != null) {
                  await prefs.setInt('user_weight_kg', savedWeight);
                }
              }
              if (fbAge != null && savedAge == null) {
                savedAge = (fbAge is int)
                    ? fbAge
                    : int.tryParse(fbAge.toString());
                if (savedAge != null) {
                  await prefs.setInt('user_age', savedAge);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Firebase fallback error: $e');
        }
      }

      if (savedHeight != null && savedHeight >= 100 && savedHeight <= 250) {
        height = savedHeight;
        _savedHeight = savedHeight;
      }
      if (savedWeight != null && savedWeight >= 30 && savedWeight <= 150) {
        weight = savedWeight;
        _savedWeight = savedWeight;
      }
      if (savedAge != null && savedAge > 0) {
        age = savedAge;
      }

      isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data for BMI: $e');
      isLoaded = true;
      notifyListeners();
    }
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
    height = _savedHeight;
    weight = _savedWeight;
    _resetCount++;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
