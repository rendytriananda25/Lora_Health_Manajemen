import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

// ✅ IMPORT PECAHAN
import 'services/location_service.dart';
import 'data/workout_data.dart';
import 'widgets/glass_control_panel.dart';
import 'widgets/sport_selection_menu.dart';
import 'widgets/timer_background.dart';
import 'widgets/tips_popup.dart';
import 'widgets/map_dialogs.dart';
import 'package:lora_1/features/notification/workout_reminder_service.dart';
import 'package:lora_1/features/gamification/badges.dart';
import 'package:lora_1/features/gamification/badges_page.dart';
import 'package:lora_1/features/gamification/badge_service.dart';
import 'package:lora_1/features/gamification/rank_system.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LocationService _locationService = LocationService();
  final ValueNotifier<int> _secondsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> _distanceNotifier = ValueNotifier<double>(0.0);

  bool _isRecording = false;
  bool _showControlPanel = true;
  bool _showSportMenu = false;
  bool _isSaving = false;
  bool _showTips = false;

  String _selectedSport = "Lari";
  List<String> _mySports = [];
  String _userLevel = "NEVER";
  String _userGoal = "KEEP_FIT";
  String _userGender = "UNKNOWN";
  String _userName = "User"; // ✅ Untuk sapaan fleksibel
  double _userWeight = 60.0; // Default weight
  int _totalSessions = 0; // 🔥 Total sesi aktif dari gamification

  // ✅ Weather Logic
  String _currentTemp = "--";
  String _weatherCondition = "";
  int _tempValue = 0;
  final String _apiKey = "d0fa6ab4f8080a9265e6a1bdf035fad0";

  final List<LatLng> _routePoints = [];
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  LatLng _currentLocation = const LatLng(-7.9509, 112.6074);

  late final MapController _mapController;
  List<Map<String, dynamic>> _exercises = [];
  final List<Map<String, dynamic>> _workoutSessionData = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initUserLocation();
    _fetchUserSports();
    _loadUserPreferences();
    _fetchUserData(); // ✅ Ambil data nama user
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _positionStream?.cancel();
    _mapController.dispose();
    _secondsNotifier.dispose();
    _distanceNotifier.dispose();
    super.dispose();
  }

  // ✅ AMBIL NAMA USER DARI DATABASE
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref("users/${user.uid}/username")
          .get();
      if (snapshot.exists && mounted) {
        setState(() => _userName = snapshot.value.toString());
      }
    }
  }

  Future<void> _initUserLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentLocation = location);
      if (!_disposed) {
        try {
          _mapController.move(location, 16.0);
        } catch (e) {
          debugPrint("Map move error: $e");
        }
      }
      _fetchInitialWeather(location);
    }
  }

  Future<void> _fetchInitialWeather(LatLng loc) async {
    try {
      final url =
          "https://api.openweathermap.org/data/2.5/weather?lat=${loc.latitude}&lon=${loc.longitude}&appid=$_apiKey&units=metric";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _tempValue = (data['main']['temp'] as num).toInt();
          _currentTemp = _tempValue.toString();
          _weatherCondition = (data['weather']?[0]?['main']?.toString() ?? "")
              .toLowerCase();
        });
        _generateRoutine();
        _syncWeatherReminder();
      }
    } catch (e) {
      debugPrint("Weather Error: $e");
    }
  }

  // ✅ Helper: Tentukan nilai MET (Metabolic Equivalent) untuk kalori lebih akurat
  double _getMETValue(String sport) {
    String s = sport.toUpperCase();

    // Referensi: Compendium of Physical Activities
    if (s.contains("LARI") || s.contains("RUN"))
      return 9.0; // Running ~9-10 MET
    if (s.contains("SEPEDA") || s.contains("CYCL"))
      return 7.5; // Cycling ~7-8 MET
    if (s.contains("BASKET")) return 6.5; // Basketball ~6-7 MET
    if (s.contains("BOLA") || s.contains("SOCCER") || s.contains("FOOTBALL"))
      return 7.0; // Soccer
    if (s.contains("JALAN") || s.contains("WALK")) return 3.8; // Walking
    if (s.contains("HOME") || s.contains("WORKOUT"))
      return 5.0; // Moderate Calisthenics

    return 4.5; // Default moderate activity
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    var loadedGender = prefs.getString('user_gender') ?? "UNKNOWN";
    int loadedFrequency = prefs.getInt('user_frequency') ?? 1;
    double loadedWeight = 60.0;
    int loadedTotalSessions = 0;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref("users/${user.uid}/health_data")
          .get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        loadedGender = data['gender']?.toString() ?? "UNKNOWN";
        if (data['frequency'] != null) {
          loadedFrequency = int.tryParse(data['frequency'].toString()) ?? 1;
        }
        if (data['weight'] != null) {
          loadedWeight = double.tryParse(data['weight'].toString()) ?? 60.0;
        }
      }

      // 🔥 Ambil total_sessions dari gamification
      final gameSnap = await FirebaseDatabase.instance
          .ref("users/${user.uid}/gamification/total_sessions")
          .get();
      if (gameSnap.exists) {
        loadedTotalSessions = int.tryParse(gameSnap.value.toString()) ?? 0;
      }
    }

    if (mounted) {
      setState(() {
        _userLevel = prefs.getString('user_fitness_level') ?? "NEVER";
        _userGoal = prefs.getString('user_fitness_goal') ?? "KEEP_FIT";
        _userGender = _normalizeGender(loadedGender);
        _userFrequency = loadedFrequency;
        _userWeight = loadedWeight > 0 ? loadedWeight : 60.0;
        _totalSessions = loadedTotalSessions;
      });
      _generateRoutine();
      _syncWeatherReminder();
    }
  }

  void _syncWeatherReminder() {
    if (_weatherCondition.isEmpty) return;

    final reminderGoal = _userGoal == "WEIGHT_LOSS"
        ? "FAT_LOSS"
        : _userGoal == "MUSCLE_GAIN"
        ? "PERFORMANCE"
        : "CASUAL";
    final isIndoorSport =
        _selectedSport.toUpperCase() == "HOME WORKOUT" ||
        _selectedSport.toUpperCase() == "HOME_WORKOUT";

    WorkoutReminderService.instance.maybeNotifyWeatherImproved(
      currentWeather: _weatherCondition,
      currentTemp: _tempValue.toDouble(),
      sport: _selectedSport,
      level: _userLevel,
      goal: reminderGoal,
      isIndoor: isIndoorSport,
    );

    WorkoutReminderService.instance.scheduleDailyWellnessProgram(
      goal: _userGoal,
      prioritySports: _mySports,
      currentTemp: _tempValue.toDouble(),
      currentWeather: _weatherCondition,
    );
  }

  String _normalizeGender(String raw) {
    final value = raw.trim().toUpperCase();
    if (value == "FEMALE" || value == "PEREMPUAN") return "FEMALE";
    if (value == "MALE" || value == "LAKI-LAKI" || value == "LAKILAKI") {
      return "MALE";
    }
    return "UNKNOWN";
  }

  String _getTargetByLevel(String sport, String level) {
    final s = sport.toUpperCase();
    final l = level.toUpperCase();
    if (s == "LARI") {
      if (l == "NEVER") return "2.0 KM";
      if (l == "SOMETIMES") return "4.0 KM";
      if (l == "OFTEN") return "7.0 KM";
      return "10.0 KM";
    }

    if (s == "SEPEDA") {
      if (l == "NEVER") return "5.0 KM";
      if (l == "SOMETIMES") return "12.0 KM";
      if (l == "OFTEN") return "25.0 KM";
      return "40.0 KM";
    }

    if (s == "BASKET" || s == "BASKETBALL") {
      if (l == "NEVER") return "20 Menit";
      if (l == "SOMETIMES") return "35 Menit";
      if (l == "OFTEN") return "60 Menit";
      return "90 Menit";
    }

    if (s == "BOLA" || s == "SEPAK BOLA" || s == "FOOTBALL") {
      if (l == "NEVER") return "30 Menit";
      if (l == "SOMETIMES") return "50 Menit";
      if (l == "OFTEN") return "75 Menit";
      return "100 Menit";
    }

    if (s == "HOME WORKOUT" || s == "HOME_WORKOUT") {
      if (l == "NEVER") return "15 Menit";
      if (l == "SOMETIMES") return "25 Menit";
      if (l == "OFTEN") return "35 Menit";
      return "45 Menit";
    }

    return "20 Menit";
  }

  String _getTranslatedSport(String sport, LanguageProvider lang) {
    if (lang.currentLanguage == 'id') return sport;
    switch (sport) {
      case "Lari": return lang.currentLanguage == 'en' ? "Running" : lang.currentLanguage == 'es' ? "Correr" : "ランニング";
      case "Sepeda": return lang.currentLanguage == 'en' ? "Cycling" : lang.currentLanguage == 'es' ? "Ciclismo" : "サイクリング";
      case "Basket": return lang.currentLanguage == 'en' ? "Basketball" : lang.currentLanguage == 'es' ? "Baloncesto" : "バスケットボール";
      case "Sepak Bola": return lang.currentLanguage == 'en' ? "Football" : lang.currentLanguage == 'es' ? "Fútbol" : "サッカー";
      case "Bola": return lang.currentLanguage == 'en' ? "Football" : lang.currentLanguage == 'es' ? "Fútbol" : "サッカー";
      case "Home Workout": return lang.currentLanguage == 'ja' ? "ホームワークアウト" : sport;
      default: return sport;
    }
  }

  int _userFrequency = 1;

  void _generateRoutine() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final result = WorkoutData.generateRoutine(
      sportType: _selectedSport,
      goal: _userGoal,
      level: _userLevel,
      gender: _userGender,
      weather: _weatherCondition,
      temp: _tempValue,
      frequency: _userFrequency,
      totalSessions: _totalSessions, // 🔥 Progresivitas berdasarkan sesi aktif
      lang: lang,
    );
    if (mounted) {
      setState(() {
        _exercises = List<Map<String, dynamic>>.from(result['exercises'] ?? []);
      });
    }
  }

  // ✅ Normalize UPPERCASE dari Firebase ke Title Case
  String _toTitleCase(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> _fetchUserSports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ref = FirebaseDatabase.instance.ref("users/${user.uid}/sports");
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is Map && mounted) {
        List<String> loaded = [];
        (snapshot.value as Map).forEach((k, v) {
          if (v == true) loaded.add(_toTitleCase(k.toString()));
        });
        setState(() {
          _mySports = loaded;
          if (_mySports.isNotEmpty) _selectedSport = _mySports.first;
        });
        _generateRoutine();
      }
    }
  }

  // ✅ Helper untuk cek apakah olahraga butuh GPS (Map) atau List Latihan (Workout)
  bool get _isGpsSport {
    final s = _selectedSport.toUpperCase();
    return s == "LARI" || s == "SEPEDA" || s == "RUNNING" || s == "CYCLING";
  }

  void _startTrackingManual() async {
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() {
        _isRecording = true;
        _secondsNotifier.value = 0;
        _distanceNotifier.value = 0.0;
        _routePoints.clear();
        _showTips = false;
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _secondsNotifier.value++;
    });

    // Hanya aktifkan GPS stream jika olahraga tipe Lari/Sepeda
    if (_isGpsSport) {
      _positionStream = _locationService.getPositionStream().listen((pos) {
        if (!mounted) return;
        LatLng newPoint = LatLng(pos.latitude, pos.longitude);
        if (_routePoints.isNotEmpty) {
          _distanceNotifier.value += _locationService.calculateDistance(
            _routePoints.last,
            newPoint,
          );
        }
        setState(() {
          _routePoints.add(newPoint);
          _currentLocation = newPoint;
        });

        if (!_disposed) {
          try {
            _mapController.move(newPoint, 17);
          } catch (e) {
            debugPrint("Stream map move error: $e");
          }
        }
      });
    }
  }

  Future<void> _stopTrackingManual() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // 🔥 FIX: Kalau bukan GPS Sport (Workout/Timer), LANGSUNG STOP tanpa dialog konfirmasi
    if (!_isGpsSport) {
      await _executeStop(lang);
    } else {
      showDialog(
        context: context,
        builder: (context) => ConfirmStopDialog(
          onCancel: () => Navigator.pop(context),
          onConfirm: () async {
            Navigator.pop(context);
            await _executeStop(lang);
          },
        ),
      );
    }
  }

  Future<void> _executeStop(LanguageProvider lang) async {
    if (mounted) setState(() => _isSaving = true);
    _timer?.cancel();
    _positionStream?.cancel();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dbRef = FirebaseDatabase.instance.ref(
          "users/${user.uid}/history",
        );

        // ✅ HITUNG KALORI PAKAI MET (Lebih Akurat)
        // Rumus: Calories = MET * Weight(kg) * Time(hours)
        double met = _getMETValue(_selectedSport);
        double durationHours = _secondsNotifier.value / 3600.0;
        int caloriesBurned = (met * _userWeight * durationHours).toInt();

        // ✅ Tambahan Kalori Berdasarkan Volume Latihan (Repetisi)
        if (!_isGpsSport && _workoutSessionData.isNotEmpty) {
          double bonusCalories = 0.0;
          for (var item in _workoutSessionData) {
            String res = item['result']?.toString() ?? "";
            if (res.toLowerCase().contains("reps")) {
              int count = int.tryParse(res.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              bonusCalories += count * 0.4; // Estimasi 0.4 kcal per repetisi gerakan
            }
          }
          caloriesBurned += bonusCalories.toInt();
        }

        // Fallback minimal 1 kalori jika durasi > 10 detik atau punya data latihan
        if (caloriesBurned == 0 && (_secondsNotifier.value > 10 || _workoutSessionData.isNotEmpty)) {
          caloriesBurned = 1;
        }

        await dbRef.push().set({
          'activity': _selectedSport,
          'duration_sec': _secondsNotifier.value,
          'distance_km': _distanceNotifier.value,
          'calories': caloriesBurned, // ✅ Pakai hasil hitungan baru
          'time': DateTime.now().toIso8601String(),
          // ✅ FIX: Simpan format string juga biar History terbaca
          'details': !_isGpsSport && _workoutSessionData.isNotEmpty
              ? _workoutSessionData
                    .map((e) => "${e['name']}: ${e['result']}")
                    .join(", ")
              : null,
          'workout_details': !_isGpsSport ? _workoutSessionData : null,
        });

        // 🔥 DATA SESI UNTUK EXP
        final sessionData = {
          'workout_details': !_isGpsSport ? _workoutSessionData : null,
          'calories': caloriesBurned,
          'distance_km': _distanceNotifier.value,
        };

        // 🔥 GAMIFICATION & STATS
        GamificationResult? gameResult;
        if (user != null) {
          gameResult = await BadgeService.processSession(user.uid, sessionData);
        }

        if (mounted) {
          final theme = Provider.of<ThemeProvider>(context, listen: false);
          // 1. Show Badge Unlock
          if (gameResult != null && gameResult.newBadges.isNotEmpty) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  BadgeUnlockDialog(badges: gameResult!.newBadges),
            );
          }

          // 2. Show Rank Up / Exp Summary
          if (gameResult != null && gameResult.isRankUp) {
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: theme.boxColor,
                title: Text(
                  "NAIK PANGKAT! 🌟",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(gameResult!.newRank.assetPath, height: 100),
                    SizedBox(height: 10),
                    Text(
                      "Selamat! Kamu sekarang rank:",
                      style: TextStyle(color: theme.textColor),
                    ),
                    Text(
                      gameResult.newRank.name,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "+${gameResult.gainedExp} EXP",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("KEREN!"),
                  ),
                ],
              ),
            );
          }

          showDialog(
            context: context,
            builder: (context) => SyncedSuccessDialog(
              message: lang.translate(
                'map.sessionSaved',
              ), // Or show Exp gained here?
              onClose: () => Navigator.pop(context),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Save Error: $e");
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isSaving = false;
        _showControlPanel = true;
        _workoutSessionData.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    bool isMapSport = _isGpsSport;

    String firstName = _userName.split(' ')[0];
    String dailyTarget = _getTargetByLevel(_selectedSport, _userLevel);

    String weatherGreeting = "";
    if (_tempValue >= 18 && _tempValue <= 27) {
      weatherGreeting = lang
          .translate('map.weatherNice')
          .replaceAll('{name}', firstName);
    } else if (_tempValue > 27) {
      weatherGreeting = lang
          .translate('map.weatherHot')
          .replaceAll('{name}', firstName);
    } else {
      weatherGreeting = lang
          .translate('map.weatherCool')
          .replaceAll('{name}', firstName);
    }

    String translatedSport = _getTranslatedSport(_selectedSport, lang);

    String flexibleAdvice =
        "$weatherGreeting ${lang.translate('map.letsGo').replaceAll('{sport}', translatedSport).replaceAll('{target}', dailyTarget)}";

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Stack(
        children: [
          if (isMapSport)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: theme.isDarkMode
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                      : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b'],
                  retinaMode: true,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white, // Navigation arrow constant
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            TimerBackground(
              selectedSport: translatedSport,
              isRecording: _isRecording,
              secondsNotifier: _secondsNotifier,
              exercises: _exercises,
              onStop: _stopTrackingManual,
              onStart: _startTrackingManual,
              onCompleteExercise: (n, r) =>
                  _workoutSessionData.add({"name": n, "result": r}),
            ),

          if (isMapSport)
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  if (mounted && !_disposed)
                    _mapController.move(_currentLocation, 17.0);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.boxColor.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.textColor.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.my_location, color: theme.textColor),
                ),
              ),
            ),

          // ✅ TIPS POPUP DENGAN SAPAAN FLEKSIBEL
          if (!_isRecording)
            TipsPopup(
              showTips: _showTips,
              selectedSport: translatedSport,
              targetText: dailyTarget,
              weatherAdvice: flexibleAdvice,
              onToggle: () => setState(() => _showTips = !_showTips),
            ),

          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => setState(() => _showSportMenu = !_showSportMenu),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.boxColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.textColor.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _showSportMenu ? Icons.close : Icons.menu,
                  color: theme.textColor,
                ),
              ),
            ),
          ),

          if (_showSportMenu)
            SportSelectionMenu(
              mySports: _mySports,
              onSelect: (s) {
                if (mounted) {
                  setState(() {
                    _selectedSport = s;
                    _showSportMenu = false;
                    _showControlPanel = true;
                    _isRecording = false;
                    _generateRoutine();
                  });
                }
              },
            ),

          if (_showControlPanel && isMapSport)
            Positioned(
              bottom: 110,
              left: 20,
              right: 20,
              child: GlassControlPanel(
                selectedSport: translatedSport,
                currentTemp: _currentTemp,
                isRecording: _isRecording,
                onToggleRecord: _isRecording
                    ? _stopTrackingManual
                    : _startTrackingManual,
                secondsNotifier: _secondsNotifier,
                distanceNotifier: _distanceNotifier,
              ),
            ),

          if (_isSaving)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
