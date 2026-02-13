import 'package:flutter/material.dart';
import 'package:lora_1/core/services/language_provider.dart';

class WorkoutData {
  static Map<String, dynamic> generateRoutine({
    required String sportType,
    required String goal,
    required String level,
    String gender = "UNKNOWN",
    String weather = "",
    required int temp,
    bool isIndoor = false,
    LanguageProvider? lang,
  }) {
    List<Map<String, dynamic>> list = [];
    String title = "";
    String weatherAdvice = "";
    String sport = sportType.toUpperCase();
    String userLevel = level.toUpperCase();
    String userGoal = goal.toUpperCase();
    String userGender = _normalizeGender(gender);
    String t(String key, [String fallback = '']) =>
        lang?.translate(key) ?? fallback;

    // ---------------------------------------------------------
    // 🏃 LOGIKA LARI (JARAK AMAN PER LEVEL)
    // ---------------------------------------------------------
    if (sport == "LARI") {
      title = "RUNNING MISSION";
      late Map<String, dynamic> data;
      if (userGender == "FEMALE") {
        data = FemaleSportEngine.getRunningData(
          userLevel,
          temp.toDouble(),
          weather,
        );
        weatherAdvice =
            "${_getRunningWeatherLogic(temp, lang)} ${data['hydration']}";
      } else {
        data = _getRunningData(userLevel, lang);
        weatherAdvice = _getRunningWeatherLogic(temp, lang);
      }

      list = [
        {
          "name": t('workout.warmup', "Pemanasan"),
          "target": "10 ${t('workout.minutes', 'Menit')}",
          "type": "time",
          "icon": Icons.accessibility_new,
          "image": "assets/gif/stretching.gif",
        },
        {
          "name": data['focus'],
          "target": userGender == "FEMALE"
              ? "${data['target_km']} KM"
              : data['target'],
          "type": "dist",
          "icon": Icons.directions_run,
          "image": "assets/gif/marching.gif",
        },
        {
          "name": t('workout.coolDown', "Cooling Down"),
          "target": "5 ${t('workout.minutes', 'Menit')}",
          "type": "time",
          "icon": Icons.ac_unit,
          "image": "assets/gif/stretching.gif",
        },
      ];

      if (userGender == "FEMALE") {
        list.add({
          "name": "Injury Prevention",
          "target": data['injury_prevention'] ??
              "Tambahkan glute activation untuk stabilitas ACL.",
          "type": "info",
          "icon": Icons.health_and_safety,
          "image": "assets/gif/stretching.gif",
        });
      }
    }
    // ---------------------------------------------------------
    // 🚴 LOGIKA SEPEDA (JARAK AMAN PER LEVEL)
    // ---------------------------------------------------------
    else if (sport == "SEPEDA") {
      title = "CYCLING ENDURANCE";
      late Map<String, dynamic> data;
      if (userGender == "FEMALE") {
        data = FemaleSportEngine.getCyclingData(
          userLevel,
          temp.toDouble(),
          weather,
        );
        weatherAdvice =
            "${_getSepedaWeatherLogic(temp, lang)} ${data['hydration']}";
      } else {
        data = _getSepedaData(userLevel, lang);
        weatherAdvice = _getSepedaWeatherLogic(temp, lang);
      }

      list = [
        {
          "name": t('workout.preparation', "Preparation"),
          "target": "5 ${t('workout.minutes', 'Menit')}",
          "type": "time",
          "icon": Icons.settings_input_component,
          "image": "assets/gif/stretching.gif",
        },
        {
          "name": data['focus'],
          "target": userGender == "FEMALE"
              ? "${data['target_km']} KM"
              : data['target'],
          "type": "dist",
          "icon": Icons.directions_bike,
          "image": "assets/gif/marching.gif",
        },
      ];

      if (userGender == "FEMALE") {
        list.add({
          "name": "Sport Note",
          "target": data['note'] ??
              "Perhatikan kekuatan core & pinggul untuk efisiensi kayuhan.",
          "type": "info",
          "icon": Icons.health_and_safety,
          "image": "assets/gif/stretching.gif",
        });
      }
    } else if (sport == "BASKET" || sport == "BASKETBALL") {
      title = "BASKETBALL SESSION";
      if (userGender == "FEMALE") {
        final data = FemaleSportEngine.getBasketData(
          userLevel,
          isIndoor,
          temp.toDouble(),
          weather,
        );
        weatherAdvice = data['hydration'] ?? "";
        list = [
          {
            "name": t('workout.preparation', "Preparation"),
            "target": "8 ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.accessibility_new,
            "image": "assets/gif/stretching.gif",
          },
          {
            "name": data['focus'],
            "target":
                "${data['duration_minutes']} ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.sports_basketball,
            "image": "assets/gif/marching.gif",
          },
          {
            "name": "Injury Prevention",
            "target": data['injury_prevention'],
            "type": "info",
            "icon": Icons.health_and_safety,
            "image": "assets/gif/stretching.gif",
          },
        ];
      } else {
        weatherAdvice = _getHomeWeatherLogic(temp, lang);
        list = [
          {
            "name": t('workout.preparation', "Preparation"),
            "target": "8 ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.accessibility_new,
            "image": "assets/gif/stretching.gif",
          },
          {
            "name": "Shooting + Dribble Drill",
            "target": "35 ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.sports_basketball,
            "image": "assets/gif/marching.gif",
          },
        ];
      }
    } else if (sport == "BOLA" || sport == "FOOTBALL") {
      title = "FOOTBALL SESSION";
      if (userGender == "FEMALE") {
        final data = FemaleSportEngine.getFootballData(
          userLevel,
          temp.toDouble(),
          weather,
        );
        weatherAdvice = data['hydration'] ?? "";
        list = [
          {
            "name": t('workout.warmup', "Pemanasan"),
            "target": "10 ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.accessibility_new,
            "image": "assets/gif/stretching.gif",
          },
          {
            "name": data['focus'],
            "target":
                "${data['duration_minutes']} ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.sports_soccer,
            "image": "assets/gif/marching.gif",
          },
          {
            "name": "Injury Prevention",
            "target": data['injury_prevention'],
            "type": "info",
            "icon": Icons.health_and_safety,
            "image": "assets/gif/stretching.gif",
          },
        ];
      } else {
        weatherAdvice = _getRunningWeatherLogic(temp, lang);
        list = [
          {
            "name": t('workout.warmup', "Pemanasan"),
            "target": "10 ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.accessibility_new,
            "image": "assets/gif/stretching.gif",
          },
          {
            "name": "Passing + Sprint Drill",
            "target": "40 ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.sports_soccer,
            "image": "assets/gif/marching.gif",
          },
        ];
      }
    }
    // ---------------------------------------------------------
    // 🏠 LOGIKA HOME WORKOUT (GOAL + LEVEL + CUACA)
    // ---------------------------------------------------------
    else {
      title = "HOME WORKOUT";
      weatherAdvice = _getHomeWeatherLogic(temp, lang);

      if (userGoal == "LOSE_WEIGHT" ||
          userGoal == "WEIGHT_LOSS" ||
          userGoal == "MENURUNKAN BERAT BADAN") {
        list = [
          {
            "name": "Jumping Jacks",
            "target": "30 Reps",
            "type": "reps",
            "icon": Icons.accessibility_new,
            "image": "assets/gif/jumping_jacks.gif",
          },
          {
            "name": "High Knees",
            "target": "20 Reps",
            "type": "reps",
            "icon": Icons.directions_run,
            "image": "assets/gif/high_knees.gif",
          },
          {
            "name": "Burpees",
            "target": "10 Reps",
            "type": "reps",
            "icon": Icons.fitness_center,
            "image": "assets/gif/boxing.gif",
          },
          {
            "name": "Mountain Climber",
            "target": "20 Reps",
            "type": "reps",
            "icon": Icons.landscape,
            "image": "assets/gif/high_knees.gif",
          },
          {
            "name": "Squat Jump",
            "target": "15 Reps",
            "type": "reps",
            "icon": Icons.arrow_upward,
            "image": "assets/gif/marching.gif",
          },
        ];
      } else if (userGoal == "BUILD_MUSCLE" ||
          userGoal == "MUSCLE_GAIN" ||
          userGoal == "MEMBENTUK OTOT") {
        list = [
          {
            "name": "Push Up",
            "target": "15 Reps",
            "type": "reps",
            "icon": Icons.fitness_center,
            "image": "assets/gif/boxing.gif",
          },
          {
            "name": "Squat",
            "target": "20 Reps",
            "type": "reps",
            "icon": Icons.accessibility_new,
            "image": "assets/gif/marching.gif",
          },
          {
            "name": "Plank",
            "target": "30 ${t('workout.seconds', 'Detik')}",
            "type": "time",
            "icon": Icons.timer,
            "image": "assets/gif/stretching.gif",
          },
          {
            "name": "Lunges",
            "target": "12 ${t('workout.repsPerLeg', 'Reps/Kaki')}",
            "type": "reps",
            "icon": Icons.directions_walk,
            "image": "assets/gif/marching.gif",
          },
          {
            "name": "Tricep Dips",
            "target": "12 Reps",
            "type": "reps",
            "icon": Icons.fitness_center,
            "image": "assets/gif/boxing.gif",
          },
        ];
      } else {
        // KEEP_FIT / default
        list = [
          {
            "name": t('workout.dynamicWarmup', "Pemanasan Dinamis"),
            "target": "5 ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.accessibility_new,
            "image": "assets/gif/stretching.gif",
          },
          {
            "name": "Push Up",
            "target": "10 Reps",
            "type": "reps",
            "icon": Icons.fitness_center,
            "image": "assets/gif/boxing.gif",
          },
          {
            "name": "Squat",
            "target": "15 Reps",
            "type": "reps",
            "icon": Icons.accessibility_new,
            "image": "assets/gif/marching.gif",
          },
          {
            "name": "Plank",
            "target": "20 ${t('workout.seconds', 'Detik')}",
            "type": "time",
            "icon": Icons.timer,
            "image": "assets/gif/stretching.gif",
          },
          {
            "name": t('workout.coolDown', "Cooling Down"),
            "target": "5 ${t('workout.minutes', 'Menit')}",
            "type": "time",
            "icon": Icons.ac_unit,
            "image": "assets/gif/stretching.gif",
          },
        ];
      }

      // Adjust reps berdasarkan level
      if (userLevel == "OFTEN" ||
          userLevel == "SERING" ||
          userLevel == "EVERY_DAY" ||
          userLevel == "DAILY") {
        for (var ex in list) {
          if (ex['type'] == 'reps') {
            String target = ex['target'].toString();
            final match = RegExp(r'(\d+)').firstMatch(target);
            if (match != null) {
              int val = int.parse(match.group(1)!);
              ex['target'] = target.replaceFirst(
                match.group(1)!,
                '${(val * 1.5).toInt()}',
              );
            }
          }
        }
      } else if (userLevel == "NEVER" ||
          userLevel == "TIDAK PERNAH BEROLAHRAGA") {
        for (var ex in list) {
          if (ex['type'] == 'reps') {
            String target = ex['target'].toString();
            final match = RegExp(r'(\d+)').firstMatch(target);
            if (match != null) {
              int val = int.parse(match.group(1)!);
              ex['target'] = target.replaceFirst(
                match.group(1)!,
                '${(val * 0.6).toInt()}',
              );
            }
          }
        }
      }
    }

    _applyGenderTuning(
      list: list,
      sport: sport,
      goal: userGoal,
      userGender: userGender,
    );

    // Saran Lora di awal semua olahraga
    list.insert(0, {
      "name": t('workout.loraAdvice', "Saran Lora"),
      "target": weatherAdvice,
      "type": "info",
      "icon": Icons.lightbulb,
      "image": "assets/gif/stretching.gif",
      "isSelected": true,
    });

    return {
      "exercises": list,
      "title": "$title ($userLevel)",
      "weather_advice": weatherAdvice,
    };
  }

  static String _normalizeGender(String raw) {
    final value = raw.trim().toUpperCase();
    if (value == "FEMALE" || value == "PEREMPUAN") return "FEMALE";
    if (value == "MALE" || value == "LAKI-LAKI" || value == "LAKILAKI") {
      return "MALE";
    }
    return "UNKNOWN";
  }

  static void _applyGenderTuning({
    required List<Map<String, dynamic>> list,
    required String sport,
    required String goal,
    required String userGender,
  }) {
    if (userGender != "FEMALE") return;

    // Step awal supaya profil perempuan lebih nyaman dan sustainable.
    final isHomeWorkout = sport == "HOME WORKOUT" || sport == "HOME_WORKOUT";
    if (!isHomeWorkout) return;

    final isWeightLossGoal =
        goal == "LOSE_WEIGHT" || goal == "WEIGHT_LOSS" || goal == "MENURUNKAN BERAT BADAN";

    for (final ex in list) {
      if (ex['type'] != 'reps') continue;

      final target = ex['target'].toString();
      final match = RegExp(r'(\d+)').firstMatch(target);
      if (match == null) continue;

      final reps = int.parse(match.group(1)!);
      final tuned = isWeightLossGoal ? (reps * 0.9).round() : reps;
      ex['target'] = target.replaceFirst(match.group(1)!, '$tuned');
    }
  }

  // --- HELPER DATA LARI (LOGIKA JARAK AMAN) ---
  static Map<String, dynamic> _getRunningData(
    String level,
    LanguageProvider? lang,
  ) {
    String t(String key, String fallback) => lang?.translate(key) ?? fallback;

    if (level == "NEVER" || level == "TIDAK PERNAH BEROLAHRAGA") {
      return {
        "target": "1.5 - 2.0 KM",
        "focus": t(
          'workout.focusLightJog',
          "Jogging sangat santai + jalan cepat",
        ),
      };
    } else if (level == "SOMETIMES" || level == "LUMAYAN SERING") {
      return {
        "target": "3.0 - 4.0 KM",
        "focus": t(
          'workout.focusSteadyJog',
          "Jogging stabil dengan napas teratur",
        ),
      };
    } else if (level == "OFTEN" || level == "SERING") {
      return {
        "target": "5.0 - 7.5 KM",
        "focus": t('workout.focusTempoRun', "Tempo run (Lari ritme cepat)"),
      };
    } else {
      return {
        "target": "10.0 - 15.0 KM",
        "focus": t(
          'workout.focusIntervalLong',
          "Long endurance run (Lari jarak jauh)",
        ),
      };
    }
  }

  // --- HELPER DATA SEPEDA (LOGIKA JARAK AMAN) ---
  static Map<String, dynamic> _getSepedaData(
    String level,
    LanguageProvider? lang,
  ) {
    String t(String key, String fallback) => lang?.translate(key) ?? fallback;

    if (level == "NEVER") {
      return {
        "target": "3.0 - 5.0 KM",
        "focus": t(
          'workout.focusCasualPedal',
          "Kayuhan santai keliling komplek",
        ),
      };
    } else if (level == "SOMETIMES") {
      return {
        "target": "7.5 - 12.0 KM",
        "focus": t('workout.focusLightEndurance', "Gowes durasi sedang"),
      };
    } else if (level == "OFTEN") {
      return {
        "target": "15.0 - 25.0 KM",
        "focus": t(
          'workout.focusSpeedClimb',
          "Gowes intensitas tinggi & tanjakan",
        ),
      };
    } else {
      return {
        "target": "30.0 - 50.0 KM",
        "focus": t(
          'workout.focusPeriodEndurance',
          "Gowes jarak jauh (Endurance)",
        ),
      };
    }
  }

  // --- WEATHER LOGIC (SANGAT KETAT) ---
  static String _getRunningWeatherLogic(int temp, LanguageProvider? lang) {
    String t(String key, String fallback) => lang?.translate(key) ?? fallback;
    String tp = '$temp';

    if (temp >= 33)
      return t(
        'workout.runDanger',
        "Bahaya! Suhu {temp}°C bisa bikin pingsan. Pindah ke treadmill indoor sekarang!",
      ).replaceAll('{temp}', tp);
    if (temp >= 28)
      return t(
        'workout.runHot',
        "Cuaca panas ({temp}°C). Kurangi target jarak 20% dan minum air tiap 10 menit!",
      ).replaceAll('{temp}', tp);
    if (temp >= 18)
      return t(
        'workout.runIdeal',
        "Cuaca mantap! Kondisi paling ideal buat kejar target jarak hari ini.",
      );
    return t(
      'workout.runCold',
      "Suhu sejuk ({temp}°C). Pemanasan wajib 15 menit agar otot tidak cedera kaku!",
    ).replaceAll('{temp}', tp);
  }

  static String _getSepedaWeatherLogic(int temp, LanguageProvider? lang) {
    String t(String key, String fallback) => lang?.translate(key) ?? fallback;

    if (temp >= 33)
      return t(
        'workout.cycleDanger',
        "Panas ekstrem! Gunakan sepeda statis di dalam ruangan saja.",
      );
    if (temp < 15)
      return t(
        'workout.cycleCold',
        "Terlalu dingin/berangin. Mending latihan di dalam ruangan demi keamanan.",
      );
    return t('workout.cycleIdeal', "Cuaca mendukung untuk gowes outdoor.");
  }

  // --- WEATHER LOGIC HOME WORKOUT (INDOOR) ---
  static String _getHomeWeatherLogic(int temp, LanguageProvider? lang) {
    String t(String key, String fallback) => lang?.translate(key) ?? fallback;
    String tp = '$temp';

    if (temp >= 33)
      return t(
        'workout.homeDanger',
        "Panas banget ({temp}°C)! Pastikan AC/kipas menyala & minum banyak air sebelum mulai.",
      ).replaceAll('{temp}', tp);
    if (temp >= 28)
      return t(
        'workout.homeWarm',
        "Agak panas ({temp}°C). Buka jendela, siapkan air minum & handuk.",
      ).replaceAll('{temp}', tp);
    if (temp >= 18)
      return t(
        'workout.homeIdeal',
        "Suhu ideal ({temp}°C) untuk workout di rumah. Gas!",
      ).replaceAll('{temp}', tp);
    return t(
      'workout.homeCold',
      "Udara dingin ({temp}°C). Pemanasan lebih lama 10-15 menit sebelum mulai.",
    ).replaceAll('{temp}', tp);
  }
}

class FemaleSportEngine {
  static double _weatherAdjustment(
    double baseValue,
    double temperature,
    String weather,
  ) {
    var adjusted = baseValue;

    if (temperature >= 33) {
      adjusted *= 0.85;
    } else if (temperature <= 18) {
      adjusted *= 0.92;
    }

    if (weather.toLowerCase().contains("rain")) {
      adjusted *= 0.90;
    }

    return adjusted;
  }

  static String _hydrationAdvice(double temperature) {
    if (temperature >= 33) {
      return "Minum 600-800 ml per jam aktivitas.";
    } else if (temperature >= 28) {
      return "Minum 500-700 ml per jam aktivitas.";
    } else {
      return "Minum 400-600 ml per jam aktivitas.";
    }
  }

  static Map<String, dynamic> getRunningData(
    String level,
    double temperature,
    String weather,
  ) {
    const baseDistance = {
      "NEVER": 1.5,
      "SOMETIMES": 3.0,
      "OFTEN": 5.5,
      "ATHLETE": 10.0,
      "DAILY": 10.0,
    };

    final base = baseDistance[level] ?? 3.0;
    final finalDistance = _weatherAdjustment(base, temperature, weather);

    return {
      "sport": "LARI",
      "target_km": finalDistance.toStringAsFixed(1),
      "focus": _runningFocus(level),
      "hydration": _hydrationAdvice(temperature),
      "injury_prevention":
          "Tambahkan glute activation untuk stabilitas ACL.",
    };
  }

  static String _runningFocus(String level) {
    switch (level) {
      case "NEVER":
        return "Jogging ringan + jalan cepat";
      case "SOMETIMES":
        return "Jogging stabil kontrol napas";
      case "OFTEN":
        return "Tempo run";
      default:
        return "Long endurance run";
    }
  }

  static Map<String, dynamic> getCyclingData(
    String level,
    double temperature,
    String weather,
  ) {
    const baseDistance = {
      "NEVER": 3.5,
      "SOMETIMES": 8.0,
      "OFTEN": 18.0,
      "ATHLETE": 35.0,
      "DAILY": 35.0,
    };

    final base = baseDistance[level] ?? 8.0;
    final finalDistance = _weatherAdjustment(base, temperature, weather);

    return {
      "sport": "SEPEDA",
      "target_km": finalDistance.toStringAsFixed(1),
      "focus": _cyclingFocus(level),
      "hydration": _hydrationAdvice(temperature),
      "note": "Perhatikan kekuatan core & pinggul untuk efisiensi kayuhan.",
    };
  }

  static String _cyclingFocus(String level) {
    switch (level) {
      case "NEVER":
        return "Kayuhan santai tempo ringan";
      case "SOMETIMES":
        return "Endurance sedang";
      case "OFTEN":
        return "Interval + tanjakan";
      default:
        return "Endurance jarak jauh";
    }
  }

  static Map<String, dynamic> getBasketData(
    String level,
    bool isIndoor,
    double temperature,
    String weather,
  ) {
    double baseDuration;

    switch (level) {
      case "NEVER":
        baseDuration = 20;
        break;
      case "SOMETIMES":
        baseDuration = 35;
        break;
      case "OFTEN":
        baseDuration = 60;
        break;
      default:
        baseDuration = 90;
    }

    if (!isIndoor) {
      baseDuration = _weatherAdjustment(baseDuration, temperature, weather);
    }

    return {
      "sport": isIndoor ? "BASKET INDOOR" : "BASKET OUTDOOR",
      "duration_minutes": baseDuration.round(),
      "focus": "Footwork + shooting drill + ACL prevention",
      "hydration": _hydrationAdvice(temperature),
      "injury_prevention":
          "Wanita memiliki risiko ACL lebih tinggi, wajib latihan glute & hamstring.",
    };
  }

  static Map<String, dynamic> getFootballData(
    String level,
    double temperature,
    String weather,
  ) {
    double baseDuration;

    switch (level) {
      case "NEVER":
        baseDuration = 30;
        break;
      case "SOMETIMES":
        baseDuration = 50;
        break;
      case "OFTEN":
        baseDuration = 75;
        break;
      default:
        baseDuration = 100;
    }

    baseDuration = _weatherAdjustment(baseDuration, temperature, weather);

    return {
      "sport": "SEPAK BOLA",
      "duration_minutes": baseDuration.round(),
      "focus": "Dribbling + passing + sprint interval",
      "hydration": _hydrationAdvice(temperature),
      "injury_prevention":
          "Latihan stabilitas lutut & core sangat dianjurkan.",
    };
  }
}
