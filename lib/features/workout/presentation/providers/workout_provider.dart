import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lora_1/features/workout/domain/repositories/workout_repository.dart';
import 'package:lora_1/features/workout/domain/usecases/calculate_calories.dart';
import 'package:lora_1/features/workout/domain/usecases/workout_utils.dart';
import 'package:lora_1/features/workout/domain/entities/workout_session_entity.dart';
import 'package:lora_1/features/map/data/workout_data.dart';
import 'package:lora_1/features/map/services/location_service.dart';
import 'package:lora_1/features/map/services/session_completion_service.dart';
import 'package:lora_1/features/notification/workout_reminder_service.dart';
import 'package:lora_1/features/gamification/badge_service.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ═══════════════════════════════════════════════════════════════
/// WorkoutProvider — State Management untuk halaman Map/Workout.
///
/// Semua logika bisnis (kalkulasi kalori, target by level, dll)
/// sudah dipindah ke UseCase. Provider ini hanya mengorkestrasi.
/// ═══════════════════════════════════════════════════════════════
class WorkoutProvider extends ChangeNotifier with WidgetsBindingObserver {
  final WorkoutRepository _repository;
  final CalculateCalories _calculateCalories;
  final GetTargetByLevel _getTargetByLevel;
  final CheckSportType _checkSportType;
  final NormalizeGender _normalizeGender;
  final TranslateSport _translateSport;
  final LocationService _locationService;

  WorkoutProvider({
    required WorkoutRepository repository,
  })  : _repository = repository,
        _calculateCalories = CalculateCalories(),
        _getTargetByLevel = GetTargetByLevel(),
        _checkSportType = CheckSportType(),
        _normalizeGender = NormalizeGender(),
        _translateSport = TranslateSport(),
        _locationService = LocationService() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ─── STATE ─────────────────────────────────────────────────
  final ValueNotifier<int> secondsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> distanceNotifier = ValueNotifier<double>(0.0);

  bool isRecording = false;
  bool showControlPanel = true;
  bool showSportMenu = false;
  bool isSaving = false;
  bool showTips = false;
  bool sessionCompleted = false;

  String selectedSport = 'Lari';
  List<String> mySports = [];
  String userLevel = 'NEVER';
  String userGoal = 'KEEP_FIT';
  String userGender = 'UNKNOWN';
  String userName = 'User';
  double userWeight = 60.0;
  int totalSessions = 0;
  int userFrequency = 1;

  String currentTemp = '--';
  String weatherCondition = '';
  int tempValue = 0;

  LatLng currentLocation = const LatLng(-7.9509, 112.6074);
  final List<LatLng> routePoints = [];
  List<Map<String, dynamic>> exercises = [];
  final List<Map<String, dynamic>> workoutSessionData = [];

  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  // 🔄 DAILY ROLLING: Track hari terakhir routine di-generate
  int _lastGeneratedDayOfYear = -1;

  // ─── PUBLIC GETTERS ────────────────────────────────────────
  bool get isGpsSport => _checkSportType.isGpsSport(selectedSport);

  String getTarget() => _getTargetByLevel(selectedSport, userLevel);

  String translateSportName(String sport, String langCode) =>
      _translateSport(sport, langCode);

  // ─── APP LIFECYCLE (Daily Rolling & Notif) ───────────────
  bool _isAppInBackground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInBackground = false;
      if (!isRecording) {
        _checkDayChanged();
      } else {
        // App kembali ke layar, hapus notifikasi background
        _cancelTrackingNotification();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppInBackground = true;
      if (isRecording) {
        // App di-minimize, munculkan notifikasi live
        _updateTrackingNotification();
      }
    }
  }

  void _checkDayChanged() {
    final now = DateTime.now();
    final todayDayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    if (_lastGeneratedDayOfYear != -1 &&
        _lastGeneratedDayOfYear != todayDayOfYear) {
      _lastGeneratedDayOfYear = todayDayOfYear;
      sessionCompleted = false;
      // generateRoutine will be called by the page when it detects the change
      notifyListeners();
    }
  }

  /// Flag: true jika hari sudah berganti sejak generate terakhir
  bool get isDayChanged {
    final now = DateTime.now();
    final todayDayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _lastGeneratedDayOfYear != todayDayOfYear;
  }

  // ─── INIT ──────────────────────────────────────────────────
  Future<void> init() async {
    final now = DateTime.now();
    _lastGeneratedDayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    await fetchUserSports();
    await loadUserPreferences();
    await fetchUserName();
    await initUserLocation();
  }

  Future<void> fetchUserSports() async {
    final result = await _repository.getUserSports();
    result.fold(
      (failure) => debugPrint('Sports Error: ${failure.message}'),
      (data) {
        mySports = data;
        if (mySports.isNotEmpty) selectedSport = mySports.first;
      },
    );
    notifyListeners();
  }

  Future<void> loadUserPreferences() async {
    final result = await _repository.getUserPreferences();
    result.fold(
      (failure) => debugPrint('Prefs Error: ${failure.message}'),
      (data) {
        userLevel = data['level'] ?? 'NEVER';
        userGoal = data['goal'] ?? 'KEEP_FIT';
        userGender = _normalizeGender(data['gender'] ?? 'UNKNOWN');
        userFrequency = data['frequency'] ?? 1;
        userWeight = data['weight'] ?? 60.0;
        totalSessions = data['totalSessions'] ?? 0;
      },
    );
    notifyListeners();
  }

  Future<void> fetchUserName() async {
    final result = await _repository.getUserName();
    result.fold(
      (_) {},
      (name) => userName = name,
    );
    notifyListeners();
  }

  Future<void> initUserLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      currentLocation = location;
      notifyListeners();
      await fetchInitialWeather(location);
    }
  }

  Future<void> fetchInitialWeather(LatLng loc) async {
    final result = await _repository.getWeather(loc.latitude, loc.longitude);
    result.fold(
      (failure) => debugPrint('Weather Error: ${failure.message}'),
      (data) {
        tempValue = (data['main']['temp'] as num).toInt();
        currentTemp = tempValue.toString();
        weatherCondition =
            (data['weather']?[0]?['main']?.toString() ?? '').toLowerCase();
      },
    );
    notifyListeners();
  }

  // ─── GENERATE ROUTINE (delegasi ke WorkoutData) ────────────
  Future<void> generateRoutine(LanguageProvider lang) async {
    debugPrint('🔄 generateRoutine: sport=$selectedSport, goal=$userGoal, level=$userLevel');

    final isCompleted =
        await SessionCompletionService.isCurrentSessionCompleted(
      sport: selectedSport,
    );

    debugPrint('🔄 generateRoutine: isCompleted=$isCompleted');

    if (isCompleted) {
      sessionCompleted = true;
      exercises = [];
      notifyListeners();
      return;
    }

    final result = WorkoutData.generateRoutine(
      sportType: selectedSport,
      goal: userGoal,
      level: userLevel,
      gender: userGender,
      weather: weatherCondition,
      temp: tempValue,
      frequency: userFrequency,
      totalSessions: totalSessions,
      lang: lang,
    );

    sessionCompleted = false;
    exercises = List<Map<String, dynamic>>.from(result['exercises'] ?? []);
    final now = DateTime.now();
    _lastGeneratedDayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    debugPrint('🔄 generateRoutine: ${exercises.length} exercises generated');
    notifyListeners();
  }

  // ─── LIVE NOTIFICATION 🔴 ─────────────────────────────────
  static const int _trackingNotifId = 888;
  final FlutterLocalNotificationsPlugin _notifPlugin = FlutterLocalNotificationsPlugin();
  bool _notifToggle = false; // Toggle untuk efek kedip 🔴/⚫

  /// Format detik ke MM:SS
  String _formatTime(int totalSec) {
    int min = totalSec ~/ 60;
    int sec = totalSec % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  /// Update notifikasi live tracking setiap detik (Hanya jika di background)
  Future<void> _updateTrackingNotification() async {
    if (!_isAppInBackground) return; // 🔥 HANYA MUNCUL DI BACKGROUND

    _notifToggle = !_notifToggle;
    final String recDot = _notifToggle ? '🔴' : '⚫';
    final String timeStr = _formatTime(secondsNotifier.value);
    final String distStr = distanceNotifier.value.toStringAsFixed(2);

    final androidDetails = AndroidNotificationDetails(
      'lora_tracking',
      'Tracking Olahraga',
      channelDescription: 'Notifikasi saat tracking olahraga aktif',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,        // Tidak bisa di-swipe
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      // Style: Big text agar info lengkap
      styleInformation: BigTextStyleInformation(
        isGpsSport
            ? '$recDot  $timeStr   •   $distStr km'
            : '$recDot  $timeStr',
        contentTitle: '$recDot REC — $selectedSport',
      ),
    );

    await _notifPlugin.show(
      _trackingNotifId,
      '$recDot REC — $selectedSport',
      isGpsSport
          ? '⏱ $timeStr   •   📍 $distStr km'
          : '⏱ $timeStr',
      NotificationDetails(android: androidDetails),
    );
  }

  /// Hapus notifikasi tracking
  Future<void> _cancelTrackingNotification() async {
    await _notifPlugin.cancel(_trackingNotifId);
  }

  // ─── TRACKING ──────────────────────────────────────────────
  void startTracking() {
    HapticFeedback.mediumImpact();
    isRecording = true;
    secondsNotifier.value = 0;
    distanceNotifier.value = 0.0;
    routePoints.clear();
    showTips = false;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsNotifier.value++;
      // 🔴 Update live notification setiap detik
      _updateTrackingNotification();
    });

    if (isGpsSport) {
      _positionStream = _locationService.getPositionStream().listen((pos) {
        // 🔥 FIX: Filter titik GPS noise sebelum ditambahkan ke rute
        LatLng? lastPoint = routePoints.isNotEmpty ? routePoints.last : null;
        if (!_locationService.isValidPoint(pos, lastPoint)) {
          return; // Buang titik GPS yang tidak valid
        }

        LatLng newPoint = LatLng(pos.latitude, pos.longitude);
        if (routePoints.isNotEmpty) {
          distanceNotifier.value += _locationService.calculateDistance(
            routePoints.last,
            newPoint,
          );
        }
        routePoints.add(newPoint);
        currentLocation = newPoint;
        notifyListeners();
      });
    }
  }

  /// Eksekusi stop dan simpan sesi. Return GamificationResult jika ada.
  Future<GamificationResult?> executeStop() async {
    isSaving = true;
    notifyListeners();

    _timer?.cancel();
    _positionStream?.cancel();
    await _cancelTrackingNotification(); // 🔴 Hapus notifikasi REC

    // ✅ Kalkulasi kalori menggunakan UseCase
    int caloriesBurned = _calculateCalories(
      sport: selectedSport,
      weightKg: userWeight,
      durationSec: secondsNotifier.value,
      workoutDetails: workoutSessionData,
      isGpsSport: isGpsSport,
    );

    final session = WorkoutSessionEntity(
      activity: selectedSport,
      durationSec: secondsNotifier.value,
      distanceKm: distanceNotifier.value,
      calories: caloriesBurned,
      time: DateTime.now(),
      workoutDetails: !isGpsSport ? workoutSessionData : null,
      details: !isGpsSport && workoutSessionData.isNotEmpty
          ? workoutSessionData
              .map((e) => "${e['name']}: ${e['result']}")
              .join(', ')
          : null,
      // 🔥 FIX: Simpan rute GPS agar polyline bisa ditampilkan di history
      path: isGpsSport
          ? routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList()
          : null,
      // 🔥 FIX: Simpan type agar history_card bisa menampilkan ikon yang benar
      type: isGpsSport ? 'TRACKING' : selectedSport.toUpperCase().replaceAll(' ', '_'),
    );

    await _repository.saveWorkoutSession(session);

    // Gamification
    final sessionData = {
      'workout_details': !isGpsSport ? workoutSessionData : null,
      'calories': caloriesBurned,
      'distance_km': distanceNotifier.value,
    };

    GamificationResult? gameResult;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        gameResult = await BadgeService.processSession(uid, sessionData);
      }
    } catch (_) {}

    await SessionCompletionService.markSessionCompleted(sport: selectedSport);

    isSaving = false;
    isRecording = false;
    workoutSessionData.clear();
    notifyListeners();

    return gameResult;
  }

  void selectSport(String sport, LanguageProvider lang) {
    selectedSport = sport;
    showSportMenu = false;
    notifyListeners();
    generateRoutine(lang);
  }

  void toggleSportMenu() {
    showSportMenu = !showSportMenu;
    notifyListeners();
  }

  void toggleControlPanel() {
    showControlPanel = !showControlPanel;
    notifyListeners();
  }

  void toggleTips() {
    showTips = !showTips;
    notifyListeners();
  }

  void addWorkoutResult(String name, String result) {
    workoutSessionData.add({'name': name, 'result': result});
  }

  void syncWeatherReminder() {
    if (weatherCondition.isEmpty) return;

    final reminderGoal = userGoal == 'WEIGHT_LOSS'
        ? 'FAT_LOSS'
        : userGoal == 'MUSCLE_GAIN'
            ? 'PERFORMANCE'
            : 'CASUAL';
    final isIndoorSport = selectedSport.toUpperCase() == 'HOME WORKOUT' ||
        selectedSport.toUpperCase() == 'HOME_WORKOUT';

    WorkoutReminderService.instance.maybeNotifyWeatherImproved(
      currentWeather: weatherCondition,
      currentTemp: tempValue.toDouble(),
      sport: selectedSport,
      level: userLevel,
      goal: reminderGoal,
      isIndoor: isIndoorSport,
    );

    WorkoutReminderService.instance.scheduleDailyWellnessProgram(
      goal: userGoal,
      prioritySports: mySports,
      currentTemp: tempValue.toDouble(),
      currentWeather: weatherCondition,
    );
  }

  /// Helper: Dapatkan greeting cuaca berdasarkan suhu & bahasa.
  String getWeatherGreeting(LanguageProvider lang) {
    String firstName = userName.split(' ')[0];
    if (tempValue >= 18 && tempValue <= 27) {
      return lang
          .translate('map.weatherNice')
          .replaceAll('{name}', firstName);
    } else if (tempValue > 27) {
      return lang
          .translate('map.weatherHot')
          .replaceAll('{name}', firstName);
    } else {
      return lang
          .translate('map.weatherCool')
          .replaceAll('{name}', firstName);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _positionStream?.cancel();
    secondsNotifier.dispose();
    distanceNotifier.dispose();
    super.dispose();
  }
}
