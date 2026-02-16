import 'dart:convert';

import 'package:lora_1/core/services/translation_service.dart';
import 'package:lora_1/features/notification/notification_service.dart';
import 'package:lora_1/features/notification/workout_time_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutReminderService {
  WorkoutReminderService._();
  static final WorkoutReminderService instance = WorkoutReminderService._();
  final TranslationService _translation = TranslationService();

  // Notification IDs (jangan diubah-ubah biar update/cancel konsisten)
  static const int _morningNotifId = 4101;
  static const int _eveningNotifId = 4102;
  static const int _nightNotifId = 4103;
  static const int _weatherTriggerNotifId = 4199;
  static const int _breakfastNotifId = 4201;
  static const int _hydrationNotifId = 4210;
  static const int _lunchNotifId = 4212;
  static const int _workoutNotifId = 4215;
  static const int _nightHydrationNotifId = 4221;

  // SharedPreferences keys
  static const String _kReminderEnabled = 'reminder_enabled';
  static const String _kLastWeatherState = 'reminder_last_weather_state';
  static const String _kLastWeatherNotifTs = 'reminder_last_weather_notif_ts';

  /// Init default: reminder aktif kalau belum pernah diset user.
  Future<void> initDefault() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kReminderEnabled)) {
      await prefs.setBool(_kReminderEnabled, true);
    }
  }

  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kReminderEnabled) ?? true;
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReminderEnabled, enabled);

    if (!enabled) {
      await NotificationService.instance.cancel(_morningNotifId);
      await NotificationService.instance.cancel(_eveningNotifId);
      await NotificationService.instance.cancel(_nightNotifId);
      await NotificationService.instance.cancel(_weatherTriggerNotifId);
      await NotificationService.instance.cancel(_breakfastNotifId);
      await NotificationService.instance.cancel(_hydrationNotifId);
      await NotificationService.instance.cancel(_lunchNotifId);
      await NotificationService.instance.cancel(_workoutNotifId);
      await NotificationService.instance.cancel(_nightHydrationNotifId);
      return;
    }

    // Kalau diaktifkan lagi, jadwalkan ulang default sederhana.
    await scheduleDailyReminderSlots(
      sport: 'LARI',
      level: 'SOMETIMES',
      goal: 'CASUAL',
      temperature: 28.0,
      isIndoor: false,
    );
  }

  /// Jadwalkan notif harian berdasarkan rating slot dari WorkoutTimeEngine.
  /// Hanya slot rating >= 4 yang dijadwalkan.
  Future<void> scheduleDailyReminderSlots({
    required String sport,
    required String level,
    required String goal,
    required double temperature,
    required bool isIndoor,
    String weather = '',
  }) async {
    if (!await isReminderEnabled()) return;

    // Bersihkan dulu jadwal lama
    await NotificationService.instance.cancel(_morningNotifId);
    await NotificationService.instance.cancel(_eveningNotifId);
    await NotificationService.instance.cancel(_nightNotifId);

    final rec = WorkoutTimeEngine.getBestWorkoutTime(
      sport: sport,
      isIndoor: isIndoor,
      temperature: temperature,
      goal: goal,
    );

    final target = WorkoutTimeEngine.suggestedTarget(
      sport: sport,
      level: level,
      temperature: temperature,
      weather: weather,
    );

    // Mapping slot -> jam default
    // morning: 06:00, evening: 17:00, night: 20:00
    if (rec.recommendedSlots.isNotEmpty) {
      final morning = rec.recommendedSlots[0];
      if (morning.rating >= 4) {
        await NotificationService.instance.scheduleDaily(
          id: _morningNotifId,
          title: _tr(
            'notification.reminder.morningWorkoutTitle',
            'Waktu olahraga pagi',
          ),
          body: _tr(
            'notification.reminder.morningWorkoutBody',
            'Targetmu hari ini {target}. {reason}',
            params: {'target': target, 'reason': morning.reason},
          ),
          hour: 6,
          minute: 0,
        );
      }
    }

    if (rec.recommendedSlots.length > 1) {
      final evening = rec.recommendedSlots[1];
      if (evening.rating >= 4) {
        await NotificationService.instance.scheduleDaily(
          id: _eveningNotifId,
          title: _tr(
            'notification.reminder.eveningWorkoutTitle',
            'Waktu olahraga sore',
          ),
          body: _tr(
            'notification.reminder.eveningWorkoutBody',
            'Performa sedang bagus. Target {target}. {reason}',
            params: {'target': target, 'reason': evening.reason},
          ),
          hour: 17,
          minute: 0,
        );
      }
    }

    if (rec.recommendedSlots.length > 2) {
      final night = rec.recommendedSlots[2];
      if (night.rating >= 4) {
        await NotificationService.instance.scheduleDaily(
          id: _nightNotifId,
          title: _tr(
            'notification.reminder.nightWorkoutTitle',
            'Sesi malam ringan',
          ),
          body: _tr(
            'notification.reminder.nightWorkoutBody',
            'Kalau masih sempat, ambil sesi ringan. Target {target}.',
            params: {'target': target},
          ),
          hour: 20,
          minute: 0,
        );
      }
    }
  }

  Future<void> scheduleDailyWellnessProgram({
    required String goal,
    required List<String> prioritySports,
    double currentTemp = 28.0,
    String currentWeather = '',
  }) async {
    if (!await isReminderEnabled()) return;

    await NotificationService.instance.cancel(_breakfastNotifId);
    await NotificationService.instance.cancel(_hydrationNotifId);
    await NotificationService.instance.cancel(_lunchNotifId);
    await NotificationService.instance.cancel(_workoutNotifId);
    await NotificationService.instance.cancel(_nightHydrationNotifId);

    final normalizedGoal = goal.toUpperCase();
    final weatherState = _classifyWeather(currentWeather, currentTemp);
    final breakfastBody = _buildBreakfastMessage(
      goal: normalizedGoal,
      weatherState: weatherState,
      temp: currentTemp,
    );
    final hydrationBody = _buildHydrationMessage(
      temp: currentTemp,
      weatherState: weatherState,
      timeLabel: '10:00',
    );
    final lunchBody = _buildLunchMessage(
      goal: normalizedGoal,
      weatherState: weatherState,
      temp: currentTemp,
    );
    final workoutBody = _buildWorkoutMessage(
      sports: prioritySports,
      weatherState: weatherState,
      temp: currentTemp,
    );
    final nightHydrationBody = _buildHydrationMessage(
      temp: currentTemp,
      weatherState: weatherState,
      timeLabel: '21:00',
      nightMode: true,
    );

    await NotificationService.instance.scheduleDaily(
      id: _breakfastNotifId,
      title: _tr('notification.reminder.breakfastTitle', 'Sarapan Sehat'),
      body: breakfastBody,
      hour: 6,
      minute: 0,
    );

    await NotificationService.instance.scheduleDaily(
      id: _hydrationNotifId,
      title: _tr('notification.reminder.hydrationTitle', 'Reminder Minum Air'),
      body: hydrationBody,
      hour: 10,
      minute: 0,
    );

    await NotificationService.instance.scheduleDaily(
      id: _lunchNotifId,
      title: _tr('notification.reminder.lunchTitle', 'Makan Siang Bergizi'),
      body: lunchBody,
      hour: 12,
      minute: 0,
    );

    await NotificationService.instance.scheduleDaily(
      id: _workoutNotifId,
      title: _tr(
        'notification.reminder.afternoonWorkoutTitle',
        'Waktu Olahraga Sore',
      ),
      body: workoutBody,
      hour: 15,
      minute: 0,
    );

    await NotificationService.instance.scheduleDaily(
      id: _nightHydrationNotifId,
      title: _tr(
        'notification.reminder.nightHydrationTitle',
        'Hydration & Sleep Reminder',
      ),
      body: nightHydrationBody,
      hour: 21,
      minute: 0,
    );
  }

  String _buildBreakfastMessage({
    required String goal,
    required String weatherState,
    required double temp,
  }) {
    String base;
    switch (goal) {
      case 'WEIGHT_LOSS':
      case 'FAT_LOSS':
        base = _tr(
          'notification.reminder.breakfastWeightLossBase',
          'Sarapan tinggi protein: telur + buah + oatmeal porsi ringan.',
        );
        break;
      case 'MUSCLE_GAIN':
      case 'PERFORMANCE':
        base = _tr(
          'notification.reminder.breakfastPerformanceBase',
          'Sarapan performa: karbo kompleks + protein (nasi merah + telur/ayam).',
        );
        break;
      default:
        base = _tr(
          'notification.reminder.breakfastDefaultBase',
          'Sarapan seimbang: karbo, protein, serat agar energi stabil.',
        );
        break;
    }

    if (weatherState == 'hot') {
      return '$base ${_tr('notification.reminder.breakfastHotSuffix', 'Cuaca panas ({temp}°C), tambah air 1 gelas.', params: {'temp': temp.toStringAsFixed(0)})}';
    }
    if (weatherState == 'cold') {
      return '$base ${_tr('notification.reminder.breakfastColdSuffix', 'Cuaca dingin, tambahkan minuman hangat.')}';
    }
    if (weatherState == 'bad') {
      return '$base ${_tr('notification.reminder.breakfastBadSuffix', 'Cuaca kurang bagus, siapkan opsi latihan indoor.')}';
    }
    return base;
  }

  String _buildLunchMessage({
    required String goal,
    required String weatherState,
    required double temp,
  }) {
    String base;
    switch (goal) {
      case 'WEIGHT_LOSS':
      case 'FAT_LOSS':
        base = _tr(
          'notification.reminder.lunchWeightLossBase',
          'Menu siang: protein tanpa lemak + sayur banyak, kurangi gorengan.',
        );
        break;
      case 'MUSCLE_GAIN':
      case 'PERFORMANCE':
        base = _tr(
          'notification.reminder.lunchPerformanceBase',
          'Menu siang: protein tinggi + karbo kompleks untuk recovery otot.',
        );
        break;
      default:
        base = _tr(
          'notification.reminder.lunchDefaultBase',
          'Menu siang bergizi: 1/2 sayur, 1/4 protein, 1/4 karbo.',
        );
        break;
    }

    if (weatherState == 'hot') {
      return '$base ${_tr('notification.reminder.lunchHotSuffix', 'Karena panas ({temp}°C), tambah buah berair.', params: {'temp': temp.toStringAsFixed(0)})}';
    }
    if (weatherState == 'bad') {
      return '$base ${_tr('notification.reminder.lunchBadSuffix', 'Cuaca kurang baik, jaga hidrasi dan kurangi aktivitas luar.')}';
    }
    return base;
  }

  String _buildWorkoutMessage({
    required List<String> sports,
    required String weatherState,
    required double temp,
  }) {
    if (sports.isEmpty) {
      return _tr(
        'notification.reminder.workoutEmpty',
        'Jam olahraga sore. Ayo mulai sesi ringan 20-30 menit.',
      );
    }
    final normalized = sports.map((e) => e.trim().toLowerCase()).toList();
    final top = normalized.take(2).map(_toSportLabel).toList();
    final joined = top.join(
      _tr('notification.reminder.orSeparator', ' atau '),
    );

    if (weatherState == 'bad') {
      return _tr(
        'notification.reminder.workoutBad',
        'Cuaca kurang mendukung. Prioritas sore ini: Home Workout atau latihan indoor.',
      );
    }
    if (weatherState == 'hot') {
      return _tr(
        'notification.reminder.workoutHot',
        'Cuaca panas ({temp}°C). Prioritas: {sport} intensitas sedang + banyak minum.',
        params: {'temp': temp.toStringAsFixed(0), 'sport': joined},
      );
    }
    if (weatherState == 'cold') {
      return _tr(
        'notification.reminder.workoutCold',
        'Cuaca dingin. Prioritas sore ini: {sport}, pemanasan lebih lama ya.',
        params: {'sport': joined},
      );
    }
    return _tr(
      'notification.reminder.workoutGood',
      'Cuaca oke. Prioritas sore ini: {sport}. Yuk mulai latihan sekarang.',
      params: {'sport': joined},
    );
  }

  String _buildHydrationMessage({
    required double temp,
    required String weatherState,
    required String timeLabel,
    bool nightMode = false,
  }) {
    String glasses;
    if (temp >= 33 || weatherState == 'hot') {
      glasses = nightMode
          ? _tr('notification.reminder.glasses.two', '2 gelas')
          : _tr('notification.reminder.glasses.twoToThree', '2-3 gelas');
    } else if (temp >= 28) {
      glasses = nightMode
          ? _tr('notification.reminder.glasses.oneToTwo', '1-2 gelas')
          : _tr('notification.reminder.glasses.two', '2 gelas');
    } else {
      glasses = nightMode
          ? _tr('notification.reminder.glasses.one', '1 gelas')
          : _tr('notification.reminder.glasses.oneToTwo', '1-2 gelas');
    }

    if (nightMode) {
      return _tr(
        'notification.reminder.hydrationNightBody',
        'Jam {time}, minum {glasses} air putih lalu lanjut tidur.',
        params: {'time': timeLabel, 'glasses': glasses},
      );
    }
    return _tr(
      'notification.reminder.hydrationDayBody',
      'Jam {time}, minum {glasses} air putih agar tetap terhidrasi.',
      params: {'time': timeLabel, 'glasses': glasses},
    );
  }

  String _toSportLabel(String raw) {
    if (raw.contains('run') || raw == 'lari') {
      return _tr('notification.reminder.sport.jogging', 'Jogging');
    }
    if (raw.contains('cycl') || raw == 'sepeda') {
      return _tr('notification.reminder.sport.cycling', 'Sepeda');
    }
    if (raw.contains('basket')) {
      return _tr('notification.reminder.sport.basketball', 'Basket');
    }
    if (raw.contains('foot') || raw == 'bola' || raw.contains('sepak')) {
      return _tr('notification.reminder.sport.football', 'Sepak Bola');
    }
    if (raw.contains('home')) {
      return _tr('notification.reminder.sport.homeWorkout', 'Home Workout');
    }
    return raw.isEmpty
        ? _tr('notification.reminder.sport.generic', 'Olahraga')
        : raw;
  }

  /// Trigger notifikasi fleksibel berbasis perubahan cuaca.
  /// Contoh: dari "hot/rain" -> "clear" lalu kasih notif.
  /// Ada cooldown anti-spam 3 jam.
  Future<void> maybeNotifyWeatherImproved({
    required String currentWeather,
    required double currentTemp,
    required String sport,
    required String level,
    required String goal,
    required bool isIndoor,
  }) async {
    if (!await isReminderEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final lastState = prefs.getString(_kLastWeatherState);
    final lastNotifTs = prefs.getInt(_kLastWeatherNotifTs) ?? 0;

    final newState = _classifyWeather(currentWeather, currentTemp);

    // Update state terakhir setiap cek
    await prefs.setString(
      _kLastWeatherState,
      jsonEncode({
        'state': newState,
        'weather': currentWeather,
        'temp': currentTemp,
        'ts': nowMs,
      }),
    );

    // Butuh histori state lama untuk deteksi "membaik"
    if (lastState == null) return;

    final decoded = jsonDecode(lastState) as Map<String, dynamic>;
    final oldState = (decoded['state'] ?? '').toString();

    final improved = _isImprovedTransition(oldState, newState);
    if (!improved) return;

    // Cooldown 3 jam
    const cooldownMs = 3 * 60 * 60 * 1000;
    if (nowMs - lastNotifTs < cooldownMs) return;

    final target = WorkoutTimeEngine.suggestedTarget(
      sport: sport,
      level: level,
      temperature: currentTemp,
      weather: currentWeather,
    );

    final slot = WorkoutTimeEngine.bestSlot(
      WorkoutTimeEngine.getBestWorkoutTime(
        sport: sport,
        isIndoor: isIndoor,
        temperature: currentTemp,
        goal: goal,
      ),
    );

    final reason = slot?.reason ??
        _tr(
          'notification.reminder.weatherImprovedFallbackReason',
          'Cuaca saat ini lebih cocok untuk olahraga.',
        );

    await NotificationService.instance.showInstant(
      id: _weatherTriggerNotifId,
      title: _tr(
        'notification.reminder.weatherImprovedTitle',
        'Cuaca lagi bagus buat olahraga',
      ),
      body: _tr(
        'notification.reminder.weatherImprovedBody',
        '{reason} Targetmu: {target}',
        params: {'reason': reason, 'target': target},
      ),
    );

    await prefs.setInt(_kLastWeatherNotifTs, nowMs);
  }

  String _classifyWeather(String weather, double temp) {
    final w = weather.toLowerCase();

    if (w.contains('rain') || w.contains('storm') || w.contains('thunder')) {
      return 'bad';
    }
    if (temp >= 33) return 'hot';
    if (temp <= 16) return 'cold';
    if (w.contains('clear') || w.contains('sun')) return 'good';
    return 'normal';
  }

  bool _isImprovedTransition(String oldState, String newState) {
    // Perubahan yang dianggap membaik
    if ((oldState == 'bad' || oldState == 'hot' || oldState == 'cold') &&
        (newState == 'normal' || newState == 'good')) {
      return true;
    }
    if (oldState == 'normal' && newState == 'good') return true;
    return false;
  }

  String _tr(
    String key,
    String fallback, {
    Map<String, String>? params,
  }) {
    String value = _translation.translate(key);
    if (value == key) value = fallback;

    if (params != null) {
      params.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }
    return value;
  }
}
