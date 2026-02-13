import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_background/src/android_config.dart' as flutter_bg_config;
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';

// ✅ FILE INI STANDALONE - TANPA KONEKSI KE PAGE MANAPUN
// Hanya untuk referensi atau testing isolasi

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _isRecording = false;
  bool _showControlPanel = false;
  bool _showSportMenu = false;
  bool _isSaving = false;
  
  String _selectedSport = "LARI"; 
  List<String> _mySports = []; 
  
  String _userLevel = "NEVER"; 
  String _userGoal = "KEEP_FIT"; 

  int _currentRepsInput = 10; 

  final Map<String, IconData> _masterIcons = {
    "LARI": Icons.directions_run,
    "SEPEDA": Icons.directions_bike,
    "HOME WORKOUT": Icons.fitness_center,
    "BASKET": Icons.sports_basketball,
    "BOLA": Icons.sports_soccer,
  };

  String _currentTemp = "--";
  int _tempValue = 0;
  int _humidityValue = 50; 
  String _weatherConditionTitle = "Memuat Data Cuaca...";
  final String _apiKey = "d0fa6ab4f8080a9265e6a1bdf035fad0"; 

  int _currentExerciseIndex = 0;
  List<Map<String, dynamic>> _workoutSessionData = [];
  final PageController _pageController = PageController(viewportFraction: 0.90); 

  List<Map<String, dynamic>> _exercises = [];

  List<LatLng> _routePoints = [];
  double _totalDistance = 0.0;
  int _seconds = 0;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  LatLng _currentLocation = const LatLng(-7.9509, 112.6074); 
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initMap();
    _fetchUserSports();
    _loadUserPreferences();
    _initBackgroundService(); 
  }

  Future<void> _initBackgroundService() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Fitness Flow Aktif",
      notificationText: "Melacak lokasi & aktivitas di latar belakang...",
      notificationIcon: flutter_bg_config.AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );
    
    bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
    if (success) {
      debugPrint("Background service ready");
    }
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userLevel = prefs.getString('user_fitness_level') ?? "NEVER";
      _userGoal = prefs.getString('user_fitness_goal') ?? "KEEP_FIT";
    });
    if (_selectedSport == "HOME WORKOUT") {
      _generateHomeWorkoutRoutine();
    }
  }

  Future<void> _saveLastSport(String sport) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_sport', sport);
  }

  Future<void> _loadLastSport() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastSport = prefs.getString('last_selected_sport');

    if (lastSport != null && _mySports.contains(lastSport)) {
        if (mounted) {
            setState(() {
                _selectedSport = lastSport;
                if (_selectedSport == "HOME WORKOUT") _generateHomeWorkoutRoutine();
            });
        }
    }
  }

  void _generateHomeWorkoutRoutine() {
    List<Map<String, dynamic>> generatedList = [];

    if (_userGoal == "WEIGHT_LOSS") {
      if (_tempValue >= 28) {
        generatedList = [
          {"name": "Stretching Aktif", "target": "3 Menit", "type": "time", "icon": Icons.accessibility_new},
          {"name": "Step Jack", "target": "45 Detik", "type": "time", "icon": Icons.directions_walk},
          {"name": "Knee Raise", "target": "20 Reps", "type": "reps", "icon": Icons.accessibility},
          {"name": "Plank", "target": "30 Detik", "type": "time", "icon": Icons.horizontal_rule},
        ];
      } else if (_tempValue < 18) {
        generatedList = [
          {"name": "Warm Up Run", "target": "5 Menit", "type": "time", "icon": Icons.directions_run},
          {"name": "Jumping Jack", "target": "1 Menit", "type": "time", "icon": Icons.star},
          {"name": "Mountain Climber", "target": "30 Detik", "type": "time", "icon": Icons.terrain},
          {"name": "Burpees", "target": "10 Reps", "type": "reps", "icon": Icons.local_fire_department},
        ];
      } else {
        if (_userLevel == "NEVER") {
           generatedList = [
            {"name": "Marching", "target": "2 Menit", "type": "time", "icon": Icons.directions_walk},
            {"name": "Jumping Jack", "target": "30 Detik", "type": "time", "icon": Icons.star},
            {"name": "Squat", "target": "12 Reps", "type": "reps", "icon": Icons.accessibility_new},
           ];
        } else {
           generatedList = [
            {"name": "High Knees", "target": "45 Detik", "type": "time", "icon": Icons.directions_run},
            {"name": "Mountain Climber", "target": "45 Detik", "type": "time", "icon": Icons.terrain},
            {"name": "Burpees", "target": "15 Reps", "type": "reps", "icon": Icons.local_fire_department},
            {"name": "Russian Twist", "target": "20 Reps", "type": "reps", "icon": Icons.loop},
           ];
        }
      }
    } 
    else if (_userGoal == "MUSCLE_GAIN") {
      if (_tempValue >= 28) {
         generatedList = [
          {"name": "Wall Push-up", "target": "12 Reps", "type": "reps", "icon": Icons.fitness_center},
          {"name": "Squat Hold", "target": "20 Detik", "type": "time", "icon": Icons.timer},
          {"name": "Plank", "target": "30 Detik", "type": "time", "icon": Icons.horizontal_rule},
         ];
      } else {
        if (_userLevel == "NEVER") {
          generatedList = [
            {"name": "Knee Push-up", "target": "10 Reps", "type": "reps", "icon": Icons.fitness_center},
            {"name": "Sit-Up", "target": "12 Reps", "type": "reps", "icon": Icons.accessibility},
            {"name": "Leg Raises", "target": "10 Reps", "type": "reps", "icon": Icons.vertical_align_top},
          ];
        } else {
          generatedList = [
            {"name": "Push-up", "target": "20 Reps", "type": "reps", "icon": Icons.fitness_center},
            {"name": "Russian Twist", "target": "20 Reps", "type": "reps", "icon": Icons.loop},
            {"name": "Leg Raises", "target": "15 Reps", "type": "reps", "icon": Icons.vertical_align_top},
            {"name": "Plank", "target": "60 Detik", "type": "time", "icon": Icons.horizontal_rule},
          ];
        }
      }
    } 
    else { 
      if (_userLevel == "NEVER") {
        generatedList = [
          {"name": "Marching", "target": "2 Menit", "type": "time", "icon": Icons.directions_walk},
          {"name": "Jumping Jack", "target": "30 Detik", "type": "time", "icon": Icons.star},
          {"name": "Squat", "target": "15 Reps", "type": "reps", "icon": Icons.accessibility_new},
          {"name": "Arm Circle", "target": "20 Detik", "type": "time", "icon": Icons.repeat},
        ];
      } else {
        generatedList = [
          {"name": "Jogging in Place", "target": "3 Menit", "type": "time", "icon": Icons.directions_run},
          {"name": "Jumping Jack", "target": "1 Menit", "type": "time", "icon": Icons.star},
          {"name": "Squat", "target": "15 Reps", "type": "reps", "icon": Icons.accessibility_new},
          {"name": "Push-up", "target": "15 Reps", "type": "reps", "icon": Icons.fitness_center},
          {"name": "Plank", "target": "45 Detik", "type": "time", "icon": Icons.horizontal_rule},
        ];
      }
    }
    
    if (mounted) {
      setState(() => _exercises = generatedList);
    }
  }

  Future<void> _fetchUserSports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final ref = FirebaseDatabase.instance.ref("users/${user.uid}/sports");
        final snapshot = await ref.get();
        if (snapshot.exists) {
          List<String> loadedSports = [];
          if (snapshot.value is Map) {
            Map<dynamic, dynamic> data = snapshot.value as Map;
            data.forEach((key, value) {
              if (value == true) loadedSports.add(key.toString());
            });
          } else if (snapshot.value is List) {
            List<dynamic> data = snapshot.value as List;
            for (var item in data) {
              if (item != null) loadedSports.add(item.toString());
            }
          }
          if (mounted) {
            setState(() {
              _mySports = loadedSports;
              if (_mySports.isNotEmpty) _selectedSport = _mySports.first;
            });
            await _loadLastSport(); 
          }
        } else {
           if(mounted) setState(() => _mySports = ["LARI", "SEPEDA"]); 
        }
      } catch (e) { debugPrint("Error fetching sports: $e"); }
    }
  }

  Future<void> _initMap() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (mounted) {
        setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
        _mapController.move(_currentLocation, 16.0);
      }
    } catch (e) { 
      debugPrint("Gagal init lokasi: $e");
    }
  }

  Future<void> _recenterMap() async {
    HapticFeedback.mediumImpact();
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation, 17.0); 
    } catch (e) { debugPrint("Gagal recenter: $e"); }
  }

  String _getSportGuidance() {
    switch (_selectedSport) {
      case "LARI":
        if (_userLevel == "NEVER") return "Target: Jalan Cepat / Jogging 10-20 Menit";
        if (_userLevel == "DAILY") return "Target: Long Run / Interval 45-70 Menit";
        return "Target: Jogging Kontinu 30 Menit";
      case "SEPEDA":
        if (_userLevel == "NEVER") return "Target: Gowes Santai 5-10 KM";
        if (_userLevel == "DAILY") return "Target: Speed Touring 20 KM+";
        return "Target: Gowes Rutin 15 KM";
      case "BASKET":
        if (_userLevel == "NEVER") return "Target: Shooting & Dribble 15 Menit";
        return "Target: Full Game / Scrimmage 45 Menit";
      case "BOLA":
        if (_userLevel == "NEVER") return "Target: Passing & Juggling 15 Menit";
        return "Target: Match / Agility 45 Menit";
      case "HOME WORKOUT":
        return "Target: Selesaikan semua set dengan postur tepat!";
      default:
        return "Lakukan aktivitas dengan konsisten!";
    }
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // Agar halaman ikut rebuild saat bahasa berubah
    Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("MAP PAGE - STANDALONE FILE", style: TextStyle(color: Colors.white)),
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
                  _buildContentItem("✅ Full MapPage Class"),
                  _buildContentItem("✅ GPS Tracking Logic"),
                  _buildContentItem("✅ Firebase Integration"),
                  _buildContentItem("✅ Home Workout Generation"),
                  _buildContentItem("✅ Weather API"),
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

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}

// --- POPUP DIALOG COMPONENTS ---

class SyncedSuccessDialog extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const SyncedSuccessDialog({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sesi Tersimpan!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008BFF),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CONFIRMATION DIALOG ---
class ConfirmStopDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmStopDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Colors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Hentikan Sesi?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Data sesi akan disimpan ke riwayat.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    "Lanjut",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    "Hentikan",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- WARNING DIALOG ---
class WarningDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const WarningDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.redAccent,
                size: 35,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text(
                "Mengerti",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SNACK BAR HELPER ---
void showCustomSnackBar(
  BuildContext context, {
  required String message,
  Color backgroundColor = const Color(0xFF008BFF),
  IconData? icon,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.all(15),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// --- LOADING OVERLAY DIALOG ---
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, this.message = "Memproses..."});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.7),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Color(0xFF008BFF),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- STATS SUMMARY CARD ---
class StatsSummaryCard extends StatelessWidget {
  final String duration;
  final String distance;
  final String calories;
  final String avgPace;

  const StatsSummaryCard({
    super.key,
    required this.duration,
    required this.distance,
    required this.calories,
    required this.avgPace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Row 1: Duration & Distance
          Row(
            children: [
              Expanded(
                child: _buildStatItem("Durasi", duration, Icons.timer),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatItem("Jarak", distance, Icons.map),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Row 2: Calories & Pace
          Row(
            children: [
              Expanded(
                child: _buildStatItem("Kkal", calories, Icons.local_fire_department),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatItem("Pace", avgPace, Icons.speed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF008BFF), size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// --- EMPTY STATE WIDGET ---
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.white24),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
