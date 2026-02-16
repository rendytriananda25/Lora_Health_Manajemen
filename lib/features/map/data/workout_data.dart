import 'package:flutter/material.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class WorkoutData {
  // 🔄 VARIABLE RUNTIME (Diisi dari Firebase)
  static Map<String, dynamic>? _onlineWorkoutData;

  // 💾 DATA LOKAL (SOURCE CODE) - Editable oleh Admin di sini
  static final Map<String, dynamic> _defaultWorkoutLibrary = {
    "running": {
      "title": "RUNNING MISSION",
      "weather_advice": {
        "danger":
            "Bahaya! Suhu {temp}°C bisa bikin pingsan. Pindah ke treadmill indoor sekarang!",
        "hot":
            "Cuaca panas ({temp}°C). Kurangi target jarak 20% dan minum air tiap 10 menit!",
        "ideal":
            "Cuaca mantap! Kondisi paling ideal buat kejar target jarak hari ini.",
        "cold":
            "Suhu sejuk ({temp}°C). Pemanasan wajib 15 menit agar otot tidak cedera kaku!",
      },
      "levels": {
        "NEVER": {
          "male_target": "1.5 - 2.0 KM",
          "female_base_km": 1.5,
          "focus": "Jogging ringan + jalan cepat",
        },
        "SOMETIMES": {
          "male_target": "3.0 - 4.0 KM",
          "female_base_km": 3.0,
          "focus": "Jogging stabil kontrol napas",
        },
        "OFTEN": {
          "male_target": "5.0 - 7.5 KM",
          "female_base_km": 5.5,
          "focus": "Tempo run (Lari ritme cepat)",
        },
        "DAILY": {
          "male_target": "10.0 - 15.0 KM",
          "female_base_km": 10.0,
          "focus": "Long endurance run (Lari jarak jauh)",
        },
      },
      "template": [
        {
          "name": "Pemanasan",
          "target": "10 Menit",
          "type": "time",
          "icon_code": 58788,
        }, // Icons.accessibility_new
        {
          "name": "{focus}",
          "target": "{target}",
          "type": "dist",
          "icon_code": 59382,
        }, // Icons.directions_run
        {
          "name": "Cooling Down",
          "target": "5 Menit",
          "type": "time",
          "icon_code": 60235,
        }, // Icons.ac_unit
      ],
      "female_extra": {
        "name": "Injury Prevention",
        "target": "Tambahkan glute activation untuk stabilitas ACL.",
        "type": "info",
        "icon_code": 61279, // Icons.health_and_safety,
      },
    },

    "cycling": {
      "title": "CYCLING ENDURANCE",
      "weather_advice": {
        "danger": "Panas ekstrem! Gunakan sepeda statis di dalam ruangan saja.",
        "cold":
            "Terlalu dingin/berangin. Mending latihan di dalam ruangan demi keamanan.",
        "ideal": "Cuaca mendukung untuk gowes outdoor.",
      },
      "levels": {
        "NEVER": {
          "male_target": "3.0 - 5.0 KM",
          "female_base_km": 3.5,
          "focus": "Kayuhan santai tempo ringan",
        },
        "SOMETIMES": {
          "male_target": "7.5 - 12.0 KM",
          "female_base_km": 8.0,
          "focus": "Endurance sedang",
        },
        "OFTEN": {
          "male_target": "15.0 - 25.0 KM",
          "female_base_km": 18.0,
          "focus": "Interval + tanjakan",
        },
        "DAILY": {
          "male_target": "30.0 - 50.0 KM",
          "female_base_km": 35.0,
          "focus": "Endurance jarak jauh",
        },
      },
      "template": [
        {
          "name": "Preparation",
          "target": "5 Menit",
          "type": "time",
          "icon_code": 59846,
        }, // Icons.settings_input_component
        {
          "name": "{focus}",
          "target": "{target}",
          "type": "dist",
          "icon_code": 59361,
        }, // Icons.directions_bike
      ],
      "female_extra": {
        "name": "Sport Note",
        "target": "Perhatikan kekuatan core & pinggul untuk efisiensi kayuhan.",
        "type": "info",
        "icon_code": 61279, // Icons.health_and_safety,
      },
    },

    "basketball": {
      "title": "BASKETBALL ELITE SYSTEM",
      "levels": {
        "NEVER": {"duration": 30}, // Beginner Session
        "SOMETIMES": {"duration": 45}, // Intermediate Session
        "OFTEN": {"duration": 75}, // Pro-Lite Session
        "DAILY": {"duration": 90}, // Pro Athlete Session
      },
      "male_template": [
        // 1. Warm Up (Beginner Data)
        {
          "name": "Dynamic Stretching",
          "target": "10 Menit",
          "type": "time",
          "icon_code": 58788,

          "video_url":
              "https://youtube.com/shorts/nPCPhqEJ3r4?si=MFQEnVj9dQDnhtTH",
          "start_at": 6, // Mulai detik ke-6
        },
        {
          "name": "Ball Slaps & Handling",
          "target": "50 Reps",
          "type": "reps",
          "icon_code": 60230,

          "video_url": "",
        },

        // 2. Main Drill (Intermediate Data: Mikan Drill + Shooting) - Scalable Duration
        {
          "name": "Mikan Drill + Form Shooting",
          "target": "{duration} Menit",
          "type": "time",
          "icon_code": 60230,

          "video_url": "",
        },

        // 3. Defense (Intermediate Data)
        {
          "name": "Zig-Zag Defensive Slides",
          "target": "4 Full Court",
          "type": "reps",
          "icon_code": 59382,

          "video_url": "",
        },

        // 4. Physical (Intermediate Data)
        {
          "name": "Physical: Push Ups",
          "target": "3 Sets x 15",
          "type": "reps",
          "icon_code": 59405,

          "video_url": "",
        },
      ],
      "female_template": [
        // 1. Warm Up (Beginner Data)
        {
          "name": "Dynamic Mobility",
          "target": "10 Menit",
          "type": "time",
          "icon_code": 58788,

          "video_url": "",
        },
        {
          "name": "Finger Tip Taps",
          "target": "2 Menit",
          "type": "time",
          "icon_code": 60230,

          "video_url": "",
        },

        // 2. Skill (Beginner Data)
        {
          "name": "Pocket Dribble Focus",
          "target": "2 Menit/Tangan",
          "type": "time",
          "icon_code": 60230,

          "video_url": "",
        },

        // 3. Main Drill (Intermediate Data: Catch & Shoot) - Scalable Duration
        {
          "name": "Catch & Shoot Midrange",
          "target": "{duration} Menit",
          "type": "time",
          "icon_code": 60230,

          "video_url": "",
        },

        // 4. Pressure Shooting (Intermediate Data)
        {
          "name": "Free Throw Pressure",
          "target": "10 Reps (Miss=Sprint)",
          "type": "reps",
          "icon_code": 60230,

          "video_url": "",
        },

        // 5. Injury Prevention (Wajib untuk Wanita - ACL Support)
        {
          "name": "Injury Prevention",
          "target": "Latihan Glute & Hamstring (3x12 Squat)",
          "type": "info",
          "icon_code": 61279,

          "video_url": "",
        },
      ],
    },

    "football": {
      "title": "PRO FOOTBALL TRAINING",
      "levels": {
        "NEVER": {"duration": 30}, // Beginner: Ball Mastery
        "SOMETIMES": {"duration": 45}, // Intermediate: Tactical Power
        "OFTEN": {"duration": 70}, // Advanced: High Intensity
        "DAILY": {"duration": 90}, // Pro: Explosive Power
      },
      "male_template": [
        // 1. Warm Up & Ball Mastery (Beginner)
        {
          "name": "Toe Taps (Ball Feel)",
          "target": "100 Reps",
          "type": "reps",
          "icon_code": 60231,

          "video_url": "",
        },
        {
          "name": "Inside-Outside Dribbling",
          "target": "20 Meters x 5",
          "type": "dist",
          "icon_code": 60231,

          "video_url": "",
        },

        // 2. Technique (Beginner/Intermediate)
        {
          "name": "Wall Pass (First Touch)",
          "target": "50 Reps/Kaki",
          "type": "reps",
          "icon_code": 60231,

          "video_url": "",
        },

        // 3. Main Drill (Intermediate/Pro: Rondo & High Press)
        {
          "name": "Rondo Simulation / High Press",
          "target": "{duration} Menit",
          "type": "time",
          "icon_code": 60231,

          "video_url": "",
        },

        // 4. Physical (Intermediate: Power)
        {
          "name": "Long Ball Accuracy",
          "target": "20 Reps (30m)",
          "type": "reps",
          "icon_code": 60231,

          "video_url": "",
        },

        // 5. Finishing (Pro: High Intensity)
        {
          "name": "Agility Ladder Runs",
          "target": "5 Sets",
          "type": "reps",
          "icon_code": 59382,

          "video_url": "",
        },
      ],
      "female_template": [
        // 1. Warm Up & Technique (Beginner)
        {
          "name": "Slalom Dribble",
          "target": "10 Cones (1m gap)",
          "type": "reps",
          "icon_code": 60231,

          "video_url": "",
        },
        {
          "name": "Passing Triangle",
          "target": "10 Menit",
          "type": "time",
          "icon_code": 60231,

          "video_url": "",
        },

        // 2. Main Drill (Intermediate: Possession)
        {
          "name": "Possession Control / 5v5 Sim",
          "target": "{duration} Menit",
          "type": "time",
          "icon_code": 60231,

          "video_url": "",
        },

        // 3. Power (Intermediate)
        {
          "name": "Shooting from Distance",
          "target": "20 Shots",
          "type": "reps",
          "icon_code": 60231,

          "video_url": "",
        },

        // 4. Pro Drill (Atltet Pro)
        {
          "name": "Counter Attack Sprint",
          "target": "60m Sprint to Finish",
          "type": "dist",
          "icon_code": 59382,

          "video_url": "",
        },

        // 5. Injury Prevention (FIFA 11+ for Female Athletes)
        {
          "name": "FIFA 11+ Prevention",
          "target": "Ligament Strength (ACL Focus)",
          "type": "info",
          "icon_code": 61279,

          "video_url": "",
        },
      ],
    },

    "home": {
      "title": "HOME WORKOUT",
      "weather_advice": {
        "danger":
            "Panas banget ({temp}°C)! Pastikan AC/kipas menyala & minum banyak air sebelum mulai.",
        "warm":
            "Agak panas ({temp}°C). Buka jendela, siapkan air minum & handuk.",
        "ideal": "Suhu ideal ({temp}°C) untuk workout di rumah. Gas!",
        "cold":
            "Udara dingin ({temp}°C). Pemanasan lebih lama 10-15 menit sebelum mulai.",
      },
      "goals": {
        "WEIGHT_LOSS": [
          {
            "name": "Jumping Jacks",
            "target": "50 Reps",
            "type": "reps",
            "icon_code": 58788,

            "video_url": "https://youtu.be/uLVt6u15L98?si=uC5vLHkj2D3_kJv0",
            // "start_at": 10, // Opsional: Mulai dari detik ke-10
          },
          {
            "name": "High Knees",
            "target": "40 Reps",
            "type": "reps",
            "icon_code": 59382,

            "video_url": "https://youtu.be/DfjpR6dzLVg?si=-v45UmeEg8XQEkR9",
          },
          {
            "name": "Burpees",
            "target": "15 Reps",
            "type": "reps",
            "icon_code": 59405,

            "video_url": "https://youtu.be/TU8QYVW0gDU?si=ITmFLNROw4lppAUf",
          },
          {
            "name": "Mountain Climber",
            "target": "30 Reps",
            "type": "reps",
            "icon_code": 59375,

            "video_url": "https://youtu.be/hq_0YlyfqGM?si=3mBtIbVOFduKekyb",
          },
          {
            "name": "Squat Jump",
            "target": "20 Reps",
            "type": "reps",
            "icon_code": 59132,

            "video_url": "https://youtu.be/YGGq0AE5Uyc?si=1qJPDMWhFRkPYlNs",
          },
          {
            "name": "Plank Jacks",
            "target": "30 Detik",
            "type": "time",
            "icon_code": 61460,

            "video_url": "https://youtu.be/VasEy9dNzZM?si=ivIuI1ST_3bvoJHv",
          },
          {
            "name": "Skaters",
            "target": "20 Reps",
            "type": "reps",
            "icon_code": 59387,

            "video_url": "https://youtu.be/JkacHtlPYds?si=L_mf21x2A4aVReSR",
          },
          {
            "name": "Tuck Jumps",
            "target": "10 Reps",
            "type": "reps",
            "icon_code": 59375,

            "video_url": "https://youtu.be/Yl7tEmpzknY?si=vM68iQu1FCysddO2",
          },
        ],
        "MUSCLE_GAIN": [
          {
            "name": "Push Up",
            "target": "20 Reps",
            "type": "reps",
            "icon_code": 59405,

            "video_url": "https://youtu.be/WDIpL0pjun0?si=zDuCBirrmOOE_VbB",
          },
          {
            "name": "Diamond Push Up",
            "target": "12 Reps",
            "type": "reps",
            "icon_code": 59405,

            "video_url": "https://youtu.be/XtU2VQVuLYs?si=6Nypxn60TdpwpeM1",
          },
          {
            "name": "Pike Push Up",
            "target": "10 Reps",
            "type": "reps",
            "icon_code": 59405,

            "video_url": "https://youtu.be/XckEEwa1BPI?si=HeLqwG3Zrw03qoN_",
          },
          {
            "name": "Squat",
            "target": "25 Reps",
            "type": "reps",
            "icon_code": 58788,

            "video_url": "https://youtu.be/l83R5PblSMA?si=QK87lhXiavi22BQO",
          },
          {
            "name": "Bulgarian Split Squat",
            "target": "12 Reps/Kaki",
            "type": "reps",
            "icon_code": 59387,

            "video_url": "https://youtu.be/Fmjj7wFJWRE?si=KPE2vbZhj_Pxy-Jy",
          },
          {
            "name": "Plank",
            "target": "60 Detik",
            "type": "time",
            "icon_code": 61460,

            "video_url": "https://youtu.be/pvIjsG5Svck?si=DzxiyLessznNw-Bw",
          },
          {
            "name": "Lunges",
            "target": "15 Reps/Kaki",
            "type": "reps",
            "icon_code": 59387,

            "video_url": "https://youtu.be/tQNktxPkSeE?si=MAMAAu2MHfjHkP7Q",
          },
          {
            "name": "Tricep Dips",
            "target": "15 Reps",
            "type": "reps",
            "icon_code": 59405,

            "video_url": "https://youtu.be/HCf97NPYeGY?si=X23VkYQuYKAoXt_r",
          },
          {
            "name": "Handstand Push-Up (Wall)",
            "target": "5 Reps",
            "type": "reps",
            "icon_code": 59405,

            "video_url": "https://youtu.be/WxgJS48wf1M?si=Y_HZ_TeanzPWAODh",
          },
        ],
        "KEEP_FIT": [
          {
            "name": "Pemanasan Dinamis",
            "target": "5 Menit",
            "type": "time",
            "icon_code": 58788,

            "video_url": "https://youtu.be/3qyWpJ34dWw?si=QSAYITuJMp3E5zYB",
          },
          {
            "name": "Bird Dog",
            "target": "12 Reps",
            "type": "reps",
            "icon_code": 58788,

            "video_url": "https://youtu.be/k2azbhhuKuM?si=jKZCpYDMGyNaJ_pn",
          },
          {
            "name": "Superman",
            "target": "15 Reps",
            "type": "reps",
            "icon_code": 60235,

            "video_url": "https://youtu.be/tYMHYWVvFjs?si=Ja47xW1te-hEigqA",
          },
          {
            "name": "Cat-Cow Stretch",
            "target": "2 Menit",
            "type": "time",
            "icon_code": 60235,

            "video_url": "https://youtu.be/LIVJZZyZ2qM?si=T5CjHWfI5YRjBvQt",
          },
          {
            "name": "Push Up",
            "target": "10 Reps",
            "type": "reps",
            "icon_code": 59405,

            "video_url": "https://youtu.be/WDIpL0pjun0?si=zDuCBirrmOOE_VbB",
          },
          {
            "name": "Squat",
            "target": "15 Reps",
            "type": "reps",
            "icon_code": 58788,

            "video_url": "https://youtu.be/l83R5PblSMA?si=QK87lhXiavi22BQO",
          },
          {
            "name": "Plank",
            "target": "30 Detik",
            "type": "time",
            "icon_code": 61460,

            "video_url": "https://youtu.be/pvIjsG5Svck?si=DzxiyLessznNw-Bw",
          },
          {
            "name": "Cooling Down",
            "target": "5 Menit",
            "type": "time",
            "icon_code": 60235,
            "video_url": "https://youtu.be/ciqL41ffHTI?si=OEwGELIw1eja-ewJ",
            "start_at": "41",
          },
        ],
      },
    },
  };

  // 🔥 UTAMA: Generate Routine berdasarkan Data (Online / Local)
  static Map<String, dynamic> generateRoutine({
    required String sportType,
    required String goal,
    required String level,
    String gender = "UNKNOWN",
    String weather = "",
    required int temp,
    bool isIndoor = false,
    int frequency = 1, // New Parameter
    LanguageProvider? lang,
  }) {
    // 1. Pilih Sumber Data
    // 🔥 FIX: Paksa pakai data lokal karena user baru saja edit link YouTube di sini.
    // Kalau pakai _onlineWorkoutData, dia bakal ambil data lama dari Firebase yang belum ada link-nya.
    Map<String, dynamic> library = _defaultWorkoutLibrary;
    // Map<String, dynamic> library = _onlineWorkoutData ?? _defaultWorkoutLibrary;

    String sportKey = _mapSportKey(sportType);
    String userLevel = level.toUpperCase();
    if (userLevel == "TIDAK PERNAH BEROLAHRAGA") userLevel = "NEVER";
    if (userLevel == "LUMAYAN SERING") userLevel = "SOMETIMES";
    if (userLevel == "SERING" || userLevel == "EVERY_DAY") userLevel = "OFTEN";

    String userGender = _normalizeGender(gender);
    String userGoal = goal.toUpperCase();

    // Default return jika data tidak ditemukan
    if (!library.containsKey(sportKey)) {
      sportKey = "home"; // Fallback ke home workout
    }

    final sportData = library[sportKey];
    String title = sportData['title'] ?? sportType;
    String weatherAdvice = "";
    List<Map<String, dynamic>> exercises = [];

    // --- LOGIKA PER CABANG OLAHRAGA ---

    // A. LARI & SEPEDA
    if (sportKey == "running" || sportKey == "cycling") {
      weatherAdvice = _getWeatherText(sportData['weather_advice'], temp);
      if (userGender == "FEMALE" &&
          sportData['weather_advice']['hydration_female'] != null) {
        // Add hydration logic if needed, simplifikasi info weather
      }

      final levelData =
          sportData['levels'][userLevel] ?? sportData['levels']['SOMETIMES'];

      // Logika Gender & Weather Adjustment
      String targetDisplay = levelData['male_target'] ?? "30 min";
      String focus = levelData['focus'] ?? "General Workout";

      if (userGender == "FEMALE") {
        double baseKm = (levelData['female_base_km'] as num).toDouble();
        double adjustedKm = _applyFemaleWeatherAdjustment(
          baseKm,
          temp,
          weather,
        );
        targetDisplay = "${adjustedKm.toStringAsFixed(1)} KM";
      }

      var template = List<Map<String, dynamic>>.from(
        sportData['template'].map((x) => Map<String, dynamic>.from(x)),
      );

      // Isi Template
      for (var ex in template) {
        ex['name'] = ex['name'].replaceAll("{focus}", focus);
        ex['target'] = ex['target'].replaceAll("{target}", targetDisplay);
      }
      exercises = template;

      // Extra info buat cewek
      if (userGender == "FEMALE" && sportData['female_extra'] != null) {
        exercises.add(Map<String, dynamic>.from(sportData['female_extra']));
      }
    }
    // B. BASKET & BOLA (Team Sports)
    else if (sportKey == "basketball" || sportKey == "football") {
      final levelData = sportData['levels'][userLevel] ?? {"duration": 45};
      double duration = (levelData['duration'] as num).toDouble();

      if (userGender == "FEMALE" && !isIndoor) {
        duration = _applyFemaleWeatherAdjustment(duration, temp, weather);
        weatherAdvice = _getWeatherText(
          library['home']['weather_advice'],
          temp,
        ); // Pinjam weather logic home
      } else {
        // Male default logic
        weatherAdvice = _getWeatherText(
          library["running"]['weather_advice'],
          temp,
        );
      }

      String templateKey = userGender == "FEMALE"
          ? "female_template"
          : "male_template";
      var template = List<Map<String, dynamic>>.from(
        sportData[templateKey].map((x) => Map<String, dynamic>.from(x)),
      );

      for (var ex in template) {
        ex['target'] = ex['target'].replaceAll(
          "{duration}",
          duration.round().toString(),
        );
      }
      exercises = template;
    }
    // C. HOME WORKOUT
    else {
      weatherAdvice = _getWeatherText(sportData['weather_advice'], temp);
      String goalKey = "KEEP_FIT";
      if (userGoal.contains("WEIGHT") ||
          userGoal.contains("KURUS") ||
          userGoal.contains("LOSE"))
        goalKey = "WEIGHT_LOSS";
      if (userGoal.contains("MUSCLE") ||
          userGoal.contains("OTOT") ||
          userGoal.contains("GAIN"))
        goalKey = "MUSCLE_GAIN";

      var rawList =
          sportData['goals'][goalKey] ?? sportData['goals']['KEEP_FIT'];
      exercises = List<Map<String, dynamic>>.from(
        rawList.map((x) => Map<String, dynamic>.from(x)),
      );

      // Female Adjustments for Reps
      if (userGender == "FEMALE" && userGoal.contains("WEIGHT")) {
        for (var ex in exercises) {
          if (ex['type'] == 'reps') {
            String t = ex['target'];
            final match = RegExp(r'(\d+)').firstMatch(t);
            if (match != null) {
              int val = int.parse(match.group(1)!);
              int newVal = (val * 0.9).round();
              ex['target'] = t.replaceFirst(match.group(1)!, newVal.toString());
            }
          }
        }
      }
    }

    // 🔥 FREQUENCY LOGIC (1x or 2x)
    String sessionLabel = "";
    if (frequency == 2) {
      // 🕒 Cek Jam: < 15.00 = Pagi, > 15.00 = Sore
      int hour = DateTime.now().hour;
      sessionLabel = hour < 15 ? " (Sesi Pagi)" : " (Sesi Sore)";
    }

    // Process Icons (Convert Code to IconData)
    for (var ex in exercises) {
      if (ex['icon_code'] != null) {
        ex['icon'] = IconData(ex['icon_code'], fontFamily: 'MaterialIcons');
      } else {
        ex['icon'] = Icons.fitness_center;
      }
    }

    // Add Lora Advice
    exercises.insert(0, {
      "name": "Saran Lora$sessionLabel",
      "target": weatherAdvice,
      "type": "info",
      "icon": Icons.lightbulb,

      "isSelected": true,
    });

    return {
      "exercises": exercises,
      "title": "$title ($userLevel)",
      "weather_advice": weatherAdvice,
    };
  }

  // --- HELPER FUNCTIONS ---

  static String _mapSportKey(String raw) {
    String s = raw.toUpperCase();
    if (s.contains("LARI") || s.contains("RUN")) return "running";
    if (s.contains("SEPEDA") || s.contains("CYCLE")) return "cycling";
    if (s.contains("BASKET")) return "basketball";
    if (s.contains("BOLA") || s.contains("SOCCER") || s.contains("FOOTBALL"))
      return "football";
    return "home";
  }

  static String _normalizeGender(String raw) {
    final value = raw.trim().toUpperCase();
    if (value == "FEMALE" || value == "PEREMPUAN") return "FEMALE";
    if (value == "MALE" || value == "LAKI-LAKI") return "MALE";
    return "UNKNOWN";
  }

  static String _getWeatherText(dynamic adviceData, int temp) {
    if (adviceData == null) return "Cuaca OK.";
    final advice = Map<String, dynamic>.from(adviceData as Map);
    String tp = '$temp';
    String msg = "";
    if (temp >= 33)
      msg = advice['danger'] ?? "";
    else if (temp >= 28)
      msg = advice['hot'] ?? advice['warm'] ?? "";
    else if (temp >= 18)
      msg = advice['ideal'] ?? "";
    else
      msg = advice['cold'] ?? "";

    return msg.replaceAll("{temp}", tp);
  }

  static double _applyFemaleWeatherAdjustment(
    double val,
    int temp,
    String weather,
  ) {
    double res = val;
    if (temp >= 33)
      res *= 0.85;
    else if (temp <= 18)
      res *= 0.92;
    if (weather.toLowerCase().contains("rain")) res *= 0.90;
    return res;
  }

  // 🔥 FUNGSI ADMIN: Upload ke Firebase
  static Future<void> seedToFirebase() async {
    try {
      // ✅ Gunakan URL spesifik (Asia-Southeast1) agar konsisten dengan SettingsPage
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            "https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app",
      );
      final ref = db.ref("data/workout_data");
      await ref.set(_defaultWorkoutLibrary);
      print("✅ Workout Data Seeded Successfully!");
    } catch (e) {
      print("⚠️ Upload Failed: $e");
      rethrow;
    }
  }

  // 🔥 FUNGSI CLIENT: Ambil dari Firebase
  static Future<void> fetchFromFirebase() async {
    try {
      final ref = FirebaseDatabase.instance.ref("data/workout_data");
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is Map) {
        _onlineWorkoutData = Map<String, dynamic>.from(snapshot.value as Map);
        // Convert nested maps recursively if needed, but Dart handles dynamic decently
        // We might need to handle List conversion manually from Firebase's Object format if indexes are used
        // But for simple use case, this usually works.
        print("✅ Online Workout Data Loaded!");
      }
    } catch (e) {
      print("Gagal ambil workout data: $e");
    }
  }
}
