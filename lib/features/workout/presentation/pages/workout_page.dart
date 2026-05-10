import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/features/workout/presentation/providers/workout_provider.dart';
import 'package:lora_1/features/map/widgets/glass_control_panel.dart';
import 'package:lora_1/features/map/widgets/sport_selection_menu.dart';
import 'package:lora_1/features/map/widgets/timer_background.dart';
import 'package:lora_1/features/map/widgets/tips_popup.dart';
import 'package:lora_1/features/map/widgets/map_dialogs.dart';
import 'package:lora_1/features/gamification/badges_page.dart';

/// ═══════════════════════════════════════════════════════════════
/// WorkoutPage — Halaman utama Map/Workout (Clean Architecture).
///
/// Menggantikan map_pages.dart yang lama.
/// Semua state dikelola oleh WorkoutProvider via Provider.
/// ═══════════════════════════════════════════════════════════════
class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  late final MapController _mapController;
  bool _disposed = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final workout = Provider.of<WorkoutProvider>(context, listen: false);
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      workout.init().then((_) {
        workout.generateRoutine(lang);
        workout.syncWeatherReminder();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _mapController.dispose();
    super.dispose();
  }

  void _onStartTracking() {
    final workout = Provider.of<WorkoutProvider>(context, listen: false);
    workout.startTracking();
  }

  Future<void> _onStopTracking() async {
    final workout = Provider.of<WorkoutProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // 🔥 Non-GPS: langsung stop tanpa konfirmasi
    if (!workout.isGpsSport) {
      await _executeStop(workout, lang);
    } else {
      showDialog(
        context: context,
        builder: (context) => ConfirmStopDialog(
          onCancel: () => Navigator.pop(context),
          onConfirm: () async {
            Navigator.pop(context);
            await _executeStop(workout, lang);
          },
        ),
      );
    }
  }

  Future<void> _executeStop(
      WorkoutProvider workout, LanguageProvider lang) async {
    final gameResult = await workout.executeStop();
    if (!mounted) return;

    final theme = Provider.of<ThemeProvider>(context, listen: false);

    // 1. Show Badge Unlock
    if (gameResult != null && gameResult.newBadges.isNotEmpty) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            BadgeUnlockDialog(badges: gameResult.newBadges),
      );
    }

    // 2. Show Rank Up
    if (gameResult != null && gameResult.isRankUp && mounted) {
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
              Image.asset(gameResult.newRank.assetPath, height: 100),
              const SizedBox(height: 10),
              Text(
                "Selamat! Kamu sekarang rank:",
                style: TextStyle(color: theme.textColor),
              ),
              Text(
                gameResult.newRank.name,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "+${gameResult.gainedExp} EXP",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("KEREN!"),
            ),
          ],
        ),
      );
    }

    // 3. Show Success & regenerate (agar sessionCompleted = true)
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => SyncedSuccessDialog(
          message: lang.translate('map.sessionSaved'),
          onClose: () => Navigator.pop(context),
        ),
      );
      // 🔄 Re-generate: sekarang SessionCompletionService menandai sesi selesai,
      // jadi generateRoutine akan set sessionCompleted = true → tampil "Sesi Selesai"
      workout.generateRoutine(lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final workout = Provider.of<WorkoutProvider>(context);

    final bool isMapSport = workout.isGpsSport;
    final String translatedSport =
        workout.translateSportName(workout.selectedSport, lang.currentLanguage);
    final String dailyTarget = workout.getTarget();
    final String weatherGreeting = workout.getWeatherGreeting(lang);
    final String flexibleAdvice =
        "$weatherGreeting ${lang.translate('map.letsGo').replaceAll('{sport}', translatedSport).replaceAll('{target}', dailyTarget)}";

    // 🔄 Cek daily rolling: jika hari berganti, regenerate
    if (workout.isDayChanged && !workout.isRecording) {
      Future.microtask(() {
        workout.generateRoutine(lang);
      });
    }

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Stack(
        children: [
          // ─── MAP / TIMER BACKGROUND ───────────────────
          if (isMapSport)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: workout.currentLocation,
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
                      points: workout.routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: workout.currentLocation,
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
              selectedSport: translatedSport,
              isRecording: workout.isRecording,
              secondsNotifier: workout.secondsNotifier,
              exercises: workout.exercises,
              sessionCompleted: workout.sessionCompleted,
              onStop: _onStopTracking,
              onStart: _onStartTracking,
              onCompleteExercise: (n, r) => workout.addWorkoutResult(n, r),
            ),

          // ─── MY LOCATION BUTTON (MAP ONLY) ─────────────
          if (isMapSport)
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  if (mounted && !_disposed) {
                    _mapController.move(workout.currentLocation, 17.0);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.boxColor.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: theme.textColor.withOpacity(0.1)),
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

          // ─── TIPS POPUP ────────────────────────────────
          if (!workout.isRecording)
            TipsPopup(
              showTips: workout.showTips,
              selectedSport: translatedSport,
              targetText: dailyTarget,
              weatherAdvice: flexibleAdvice,
              onToggle: () => workout.toggleTips(),
            ),

          // ─── SPORT MENU BUTTON ─────────────────────────
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => workout.toggleSportMenu(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.boxColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: theme.textColor.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  workout.showSportMenu ? Icons.close : Icons.menu,
                  color: theme.textColor,
                ),
              ),
            ),
          ),

          // ─── SPORT SELECTION MENU ──────────────────────
          if (workout.showSportMenu)
            SportSelectionMenu(
              mySports: workout.mySports,
              onSelect: (s) => workout.selectSport(s, lang),
            ),

          // ─── CONTROL PANEL (MAP ONLY) ──────────────────
          if (workout.showControlPanel && isMapSport)
            Positioned(
              bottom: 110,
              left: 20,
              right: 20,
              child: GlassControlPanel(
                selectedSport: translatedSport,
                currentTemp: workout.currentTemp,
                isRecording: workout.isRecording,
                onToggleRecord:
                    workout.isRecording ? _onStopTracking : _onStartTracking,
                secondsNotifier: workout.secondsNotifier,
                distanceNotifier: workout.distanceNotifier,
              ),
            ),

          // ─── SAVING INDICATOR ──────────────────────────
          if (workout.isSaving)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
