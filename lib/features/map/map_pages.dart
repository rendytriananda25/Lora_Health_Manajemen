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

// ✅ IMPORT PECAHAN
import 'services/location_service.dart';
import 'data/workout_data.dart';
import 'widgets/glass_control_panel.dart';
import 'widgets/sport_selection_menu.dart';
import 'widgets/timer_background.dart';
import 'widgets/tips_popup.dart';
import 'widgets/map_dialogs.dart';

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
          _weatherCondition =
              (data['weather']?[0]?['main']?.toString() ?? "").toLowerCase();
        });
        _generateRoutine();
      }
    } catch (e) {
      debugPrint("Weather Error: $e");
    }
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    var loadedGender = prefs.getString('user_gender') ?? "UNKNOWN";

    if (loadedGender == "UNKNOWN" || loadedGender == "--") {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseDatabase.instance
            .ref("users/${user.uid}/health_data/gender")
            .get();
        if (snapshot.exists && snapshot.value != null) {
          loadedGender = snapshot.value.toString();
        }
      }
    }

    if (mounted) {
      setState(() {
        _userLevel = prefs.getString('user_fitness_level') ?? "NEVER";
        _userGoal = prefs.getString('user_fitness_goal') ?? "KEEP_FIT";
        _userGender = _normalizeGender(loadedGender);
      });
      _generateRoutine();
    }
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

  void _generateRoutine() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final result = WorkoutData.generateRoutine(
      sportType: _selectedSport,
      goal: _userGoal,
      level: _userLevel,
      gender: _userGender,
      weather: _weatherCondition,
      temp: _tempValue,
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

    if (_selectedSport != "Home Workout") {
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
    showDialog(
      context: context,
      builder: (context) => ConfirmStopDialog(
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          Navigator.pop(context);
          if (mounted) setState(() => _isSaving = true);
          _timer?.cancel();
          _positionStream?.cancel();

          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final dbRef = FirebaseDatabase.instance.ref(
                "users/${user.uid}/history",
              );
              await dbRef.push().set({
                'activity': _selectedSport,
                'duration_sec': _secondsNotifier.value,
                'distance_km': _distanceNotifier.value,
                'calories': (_secondsNotifier.value * 0.15).toInt(),
                'time': DateTime.now().toIso8601String(),
                'workout_details': _selectedSport == "Home Workout"
                    ? _workoutSessionData
                    : null,
              });

              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => SyncedSuccessDialog(
                    message: lang.translate('map.sessionSaved'),
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    bool isMapSport = _selectedSport != "Home Workout";

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

    String flexibleAdvice =
        "$weatherGreeting ${lang.translate('map.letsGo').replaceAll('{sport}', _selectedSport).replaceAll('{target}', dailyTarget)}";

    return Scaffold(
      backgroundColor: Colors.black,
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
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b'],
                  retinaMode: false,
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
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            TimerBackground(
              selectedSport: _selectedSport,
              isRecording: _isRecording,
              secondsNotifier: _secondsNotifier,
              exercises: _exercises,
              onStop: _stopTrackingManual,
              onStart: _startTrackingManual,
              onCompleteExercise: (n, r) =>
                  _workoutSessionData.add({"name": n, "result": r}),
              onSkipExercise: (i) => setState(() => _exercises.removeAt(i)),
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
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
            ),

          // ✅ TIPS POPUP DENGAN SAPAAN FLEKSIBEL
          if (!_isRecording)
            TipsPopup(
              showTips: _showTips,
              selectedSport: _selectedSport,
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
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(
                  _showSportMenu ? Icons.close : Icons.menu,
                  color: Colors.white,
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
                selectedSport: _selectedSport,
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
