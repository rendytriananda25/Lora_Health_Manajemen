import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class WorkoutData {
  // 🔄 VARIABLE RUNTIME (Diisi dari Firebase)
  static Map<String, dynamic>? _onlineWorkoutData;

  // ============================================================
  // 📚 REFERENSI ILMIAH PROGRESIVITAS:
  // - ACSM (2021). Guidelines for Exercise Testing and Prescription, 11th Ed.
  //   → Progressive overload 5-10%/minggu, deload setiap 4 minggu (W4 = 70% volume)
  // - NSCA (2016). Essentials of Strength Training and Conditioning, 4th Ed.
  //   → "2-for-2 Rule", rep range hipertrofi 8-12 RM
  // - Schoenfeld, B.J. (2010). Journal of Strength and Conditioning Research, 24(10).
  //   → Validasi rep range 8-12 untuk muscle gain
  // - Garber, C.E., et al. (2011). Medicine & Science in Sports & Exercise, 43(7).
  //   → Weight loss: 150-300 menit/minggu moderate intensity
  // ============================================================

  // 🔥 DATA PROGRESIVITAS — Per goal × per gerakan × per level × per minggu
  // W4 = DELOAD WEEK (volume -30% untuk recovery & pencegahan cedera)
  // Loop 4 minggu tanpa batas, base naik otomatis tiap siklus via startDate
  static final Map<String, dynamic> _progressionData = {
    // ══════════════════════════════════════════════════════
    // 🔥 WEIGHT LOSS — Fokus: Kardio + HIIT, rep tinggi
    // Referensi: ACSM 150-300 mnt/minggu moderate intensity
    // ══════════════════════════════════════════════════════
    "WEIGHT_LOSS": {
      "Jumping Jacks": {
        "NEVER": {
          "W1": "30 Reps",
          "W2": "35 Reps",
          "W3": "40 Reps",
          "W4": "25 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "45 Reps",
          "W2": "50 Reps",
          "W3": "55 Reps",
          "W4": "35 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "55 Reps",
          "W2": "62 Reps",
          "W3": "70 Reps",
          "W4": "45 Reps (Deload)",
        },
        "DAILY": {
          "W1": "70 Reps",
          "W2": "80 Reps",
          "W3": "90 Reps",
          "W4": "60 Reps (Deload)",
        },
      },
      "High Knees": {
        "NEVER": {
          "W1": "20 Reps",
          "W2": "25 Reps",
          "W3": "30 Reps",
          "W4": "15 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "35 Reps",
          "W2": "40 Reps",
          "W3": "45 Reps",
          "W4": "25 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "45 Reps",
          "W2": "52 Reps",
          "W3": "60 Reps",
          "W4": "35 Reps (Deload)",
        },
        "DAILY": {
          "W1": "60 Reps",
          "W2": "70 Reps",
          "W3": "80 Reps",
          "W4": "50 Reps (Deload)",
        },
      },
      "Burpees": {
        // Gerakan kompleks: kenaikan konservatif 5-7% (risiko overuse injury)
        "NEVER": {
          "W1": "5 Reps",
          "W2": "6 Reps",
          "W3": "7 Reps",
          "W4": "4 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "10 Reps",
          "W2": "12 Reps",
          "W3": "13 Reps",
          "W4": "8 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "15 Reps",
          "W2": "17 Reps",
          "W3": "19 Reps",
          "W4": "12 Reps (Deload)",
        },
        "DAILY": {
          "W1": "20 Reps",
          "W2": "22 Reps",
          "W3": "25 Reps",
          "W4": "15 Reps (Deload)",
        },
      },
      "Mountain Climber": {
        "NEVER": {
          "W1": "16 Reps",
          "W2": "20 Reps",
          "W3": "24 Reps",
          "W4": "12 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "24 Reps",
          "W2": "28 Reps",
          "W3": "32 Reps",
          "W4": "18 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "32 Reps",
          "W2": "36 Reps",
          "W3": "40 Reps",
          "W4": "24 Reps (Deload)",
        },
        "DAILY": {
          "W1": "40 Reps",
          "W2": "46 Reps",
          "W3": "52 Reps",
          "W4": "32 Reps (Deload)",
        },
      },
      "Squat Jump": {
        // Plyometric: kenaikan konservatif, risiko lutut jika terlalu cepat
        "NEVER": {
          "W1": "8 Reps",
          "W2": "10 Reps",
          "W3": "12 Reps",
          "W4": "6 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "15 Reps",
          "W2": "17 Reps",
          "W3": "20 Reps",
          "W4": "10 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "20 Reps",
          "W2": "23 Reps",
          "W3": "26 Reps",
          "W4": "15 Reps (Deload)",
        },
        "DAILY": {
          "W1": "25 Reps",
          "W2": "28 Reps",
          "W3": "32 Reps",
          "W4": "20 Reps (Deload)",
        },
      },
      "Plank Jacks": {
        "NEVER": {
          "W1": "20 Detik",
          "W2": "25 Detik",
          "W3": "30 Detik",
          "W4": "15 Detik (Deload)",
        },
        "SOMETIMES": {
          "W1": "30 Detik",
          "W2": "35 Detik",
          "W3": "40 Detik",
          "W4": "25 Detik (Deload)",
        },
        "OFTEN": {
          "W1": "40 Detik",
          "W2": "47 Detik",
          "W3": "55 Detik",
          "W4": "30 Detik (Deload)",
        },
        "DAILY": {
          "W1": "55 Detik",
          "W2": "65 Detik",
          "W3": "75 Detik",
          "W4": "45 Detik (Deload)",
        },
      },
      "Skaters": {
        "NEVER": {
          "W1": "10 Reps",
          "W2": "12 Reps",
          "W3": "14 Reps",
          "W4": "8 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "16 Reps",
          "W2": "18 Reps",
          "W3": "20 Reps",
          "W4": "12 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "20 Reps",
          "W2": "23 Reps",
          "W3": "26 Reps",
          "W4": "16 Reps (Deload)",
        },
        "DAILY": {
          "W1": "26 Reps",
          "W2": "30 Reps",
          "W3": "34 Reps",
          "W4": "22 Reps (Deload)",
        },
      },
      "Tuck Jumps": {
        // High impact plyometric: kenaikan paling konservatif
        "NEVER": {
          "W1": "5 Reps",
          "W2": "6 Reps",
          "W3": "7 Reps",
          "W4": "4 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "8 Reps",
          "W2": "9 Reps",
          "W3": "11 Reps",
          "W4": "6 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "12 Reps",
          "W2": "14 Reps",
          "W3": "16 Reps",
          "W4": "9 Reps (Deload)",
        },
        "DAILY": {
          "W1": "16 Reps",
          "W2": "18 Reps",
          "W3": "20 Reps",
          "W4": "12 Reps (Deload)",
        },
      },
    },

    // ══════════════════════════════════════════════════════
    // 💪 MUSCLE GAIN — Fokus: Strength, sets × reps, hipertrofi
    // Referensi: NSCA 8-12 RM untuk hipertrofi, istirahat 60-90 detik
    // ══════════════════════════════════════════════════════
    "MUSCLE_GAIN": {
      "Push Up": {
        "NEVER": {
          "W1": "3x8 Reps",
          "W2": "3x10 Reps",
          "W3": "3x12 Reps",
          "W4": "2x8 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "3x12 Reps",
          "W2": "3x15 Reps",
          "W3": "4x12 Reps",
          "W4": "3x8 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "4x12 Reps",
          "W2": "4x15 Reps",
          "W3": "4x17 Reps",
          "W4": "3x10 Reps (Deload)",
        },
        "DAILY": {
          "W1": "4x15 Reps",
          "W2": "4x18 Reps",
          "W3": "5x15 Reps",
          "W4": "3x12 Reps (Deload)",
        },
      },
      "Diamond Push Up": {
        // Isolasi trisep: hindari overload sendi siku, mulai konservatif
        "NEVER": {
          "W1": "3x5 Reps",
          "W2": "3x6 Reps",
          "W3": "3x8 Reps",
          "W4": "2x5 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "3x8 Reps",
          "W2": "3x10 Reps",
          "W3": "3x12 Reps",
          "W4": "2x6 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "3x10 Reps",
          "W2": "3x12 Reps",
          "W3": "4x10 Reps",
          "W4": "3x7 Reps (Deload)",
        },
        "DAILY": {
          "W1": "4x10 Reps",
          "W2": "4x12 Reps",
          "W3": "4x14 Reps",
          "W4": "3x8 Reps (Deload)",
        },
      },
      "Pike Push Up": {
        "NEVER": {
          "W1": "3x5 Reps",
          "W2": "3x6 Reps",
          "W3": "3x8 Reps",
          "W4": "2x4 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "3x8 Reps",
          "W2": "3x10 Reps",
          "W3": "3x12 Reps",
          "W4": "2x6 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "3x10 Reps",
          "W2": "3x12 Reps",
          "W3": "4x10 Reps",
          "W4": "3x7 Reps (Deload)",
        },
        "DAILY": {
          "W1": "4x10 Reps",
          "W2": "4x12 Reps",
          "W3": "4x14 Reps",
          "W4": "3x8 Reps (Deload)",
        },
      },
      "Squat": {
        "NEVER": {
          "W1": "3x12 Reps",
          "W2": "3x15 Reps",
          "W3": "3x18 Reps",
          "W4": "2x10 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "3x15 Reps",
          "W2": "3x18 Reps",
          "W3": "4x15 Reps",
          "W4": "3x10 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "4x15 Reps",
          "W2": "4x18 Reps",
          "W3": "4x20 Reps",
          "W4": "3x12 Reps (Deload)",
        },
        "DAILY": {
          "W1": "4x20 Reps",
          "W2": "4x23 Reps",
          "W3": "5x20 Reps",
          "W4": "3x15 Reps (Deload)",
        },
      },
      "Bulgarian Split Squat": {
        // Unilateral: beban lebih berat per kaki, awali konservatif
        "NEVER": {
          "W1": "3x6/Kaki",
          "W2": "3x8/Kaki",
          "W3": "3x10/Kaki",
          "W4": "2x5/Kaki (Deload)",
        },
        "SOMETIMES": {
          "W1": "3x8/Kaki",
          "W2": "3x10/Kaki",
          "W3": "3x12/Kaki",
          "W4": "2x6/Kaki (Deload)",
        },
        "OFTEN": {
          "W1": "3x10/Kaki",
          "W2": "3x12/Kaki",
          "W3": "4x10/Kaki",
          "W4": "3x7/Kaki (Deload)",
        },
        "DAILY": {
          "W1": "4x10/Kaki",
          "W2": "4x12/Kaki",
          "W3": "4x14/Kaki",
          "W4": "3x8/Kaki (Deload)",
        },
      },
      "Plank": {
        "NEVER": {
          "W1": "3x20 Detik",
          "W2": "3x25 Detik",
          "W3": "3x30 Detik",
          "W4": "2x15 Detik (Deload)",
        },
        "SOMETIMES": {
          "W1": "3x30 Detik",
          "W2": "3x40 Detik",
          "W3": "3x50 Detik",
          "W4": "2x25 Detik (Deload)",
        },
        "OFTEN": {
          "W1": "3x45 Detik",
          "W2": "3x55 Detik",
          "W3": "3x65 Detik",
          "W4": "3x30 Detik (Deload)",
        },
        "DAILY": {
          "W1": "3x60 Detik",
          "W2": "3x75 Detik",
          "W3": "3x90 Detik",
          "W4": "3x45 Detik (Deload)",
        },
      },
      "Lunges": {
        "NEVER": {
          "W1": "3x8/Kaki",
          "W2": "3x10/Kaki",
          "W3": "3x12/Kaki",
          "W4": "2x6/Kaki (Deload)",
        },
        "SOMETIMES": {
          "W1": "3x10/Kaki",
          "W2": "3x12/Kaki",
          "W3": "3x14/Kaki",
          "W4": "2x8/Kaki (Deload)",
        },
        "OFTEN": {
          "W1": "3x12/Kaki",
          "W2": "3x15/Kaki",
          "W3": "4x12/Kaki",
          "W4": "3x8/Kaki (Deload)",
        },
        "DAILY": {
          "W1": "4x12/Kaki",
          "W2": "4x14/Kaki",
          "W3": "4x16/Kaki",
          "W4": "3x10/Kaki (Deload)",
        },
      },
      "Tricep Dips": {
        "NEVER": {
          "W1": "3x8 Reps",
          "W2": "3x10 Reps",
          "W3": "3x12 Reps",
          "W4": "2x6 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "3x10 Reps",
          "W2": "3x12 Reps",
          "W3": "3x15 Reps",
          "W4": "2x8 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "3x12 Reps",
          "W2": "3x15 Reps",
          "W3": "4x12 Reps",
          "W4": "3x8 Reps (Deload)",
        },
        "DAILY": {
          "W1": "4x12 Reps",
          "W2": "4x15 Reps",
          "W3": "4x18 Reps",
          "W4": "3x10 Reps (Deload)",
        },
      },
      "Handstand Push-Up (Wall)": {
        // Gerakan advanced: pemula wajib kuasai Pike Push Up dulu
        "NEVER": {
          "W1": "SKIP - Kuasai Pike Push Up dulu",
          "W2": "SKIP",
          "W3": "SKIP",
          "W4": "SKIP",
        },
        "SOMETIMES": {
          "W1": "2x3 Reps",
          "W2": "2x4 Reps",
          "W3": "2x5 Reps",
          "W4": "2x3 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "3x5 Reps",
          "W2": "3x6 Reps",
          "W3": "3x7 Reps",
          "W4": "2x4 Reps (Deload)",
        },
        "DAILY": {
          "W1": "3x6 Reps",
          "W2": "3x8 Reps",
          "W3": "4x6 Reps",
          "W4": "2x5 Reps (Deload)",
        },
      },
    },

    // ══════════════════════════════════════════════════════
    // 🌿 KEEP FIT — Fokus: Mobilitas + Maintenance
    // Referensi: ACSM maintenance = 60-70% dari training load
    // Kenaikan lebih lambat, fokus durasi & kualitas gerak
    // ══════════════════════════════════════════════════════
    "KEEP_FIT": {
      "Pemanasan Dinamis": {
        // Durasi pemanasan tetap (tidak perlu progresivitas)
        "NEVER": {
          "W1": "5 Menit",
          "W2": "5 Menit",
          "W3": "5 Menit",
          "W4": "5 Menit",
        },
        "SOMETIMES": {
          "W1": "5 Menit",
          "W2": "5 Menit",
          "W3": "5 Menit",
          "W4": "5 Menit",
        },
        "OFTEN": {
          "W1": "5 Menit",
          "W2": "5 Menit",
          "W3": "5 Menit",
          "W4": "5 Menit",
        },
        "DAILY": {
          "W1": "5 Menit",
          "W2": "5 Menit",
          "W3": "5 Menit",
          "W4": "5 Menit",
        },
      },
      "Bird Dog": {
        "NEVER": {
          "W1": "2x8 Reps",
          "W2": "2x10 Reps",
          "W3": "2x12 Reps",
          "W4": "2x6 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "3x10 Reps",
          "W2": "3x12 Reps",
          "W3": "3x14 Reps",
          "W4": "2x8 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "3x12 Reps",
          "W2": "3x14 Reps",
          "W3": "3x16 Reps",
          "W4": "2x10 Reps (Deload)",
        },
        "DAILY": {
          "W1": "3x14 Reps",
          "W2": "3x16 Reps",
          "W3": "4x14 Reps",
          "W4": "3x10 Reps (Deload)",
        },
      },
      "Superman": {
        "NEVER": {
          "W1": "2x8 Reps",
          "W2": "2x10 Reps",
          "W3": "2x12 Reps",
          "W4": "2x6 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "2x12 Reps",
          "W2": "2x14 Reps",
          "W3": "3x12 Reps",
          "W4": "2x8 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "3x12 Reps",
          "W2": "3x14 Reps",
          "W3": "3x16 Reps",
          "W4": "2x10 Reps (Deload)",
        },
        "DAILY": {
          "W1": "3x15 Reps",
          "W2": "3x17 Reps",
          "W3": "4x15 Reps",
          "W4": "3x10 Reps (Deload)",
        },
      },
      "Cat-Cow Stretch": {
        // Mobility: durasi tidak perlu naik signifikan
        "NEVER": {
          "W1": "1 Menit",
          "W2": "1.5 Menit",
          "W3": "2 Menit",
          "W4": "1 Menit (Deload)",
        },
        "SOMETIMES": {
          "W1": "2 Menit",
          "W2": "2 Menit",
          "W3": "2 Menit",
          "W4": "1.5 Menit (Deload)",
        },
        "OFTEN": {
          "W1": "2 Menit",
          "W2": "2 Menit",
          "W3": "2 Menit",
          "W4": "2 Menit",
        },
        "DAILY": {
          "W1": "2 Menit",
          "W2": "2 Menit",
          "W3": "2 Menit",
          "W4": "2 Menit",
        },
      },
      "Push Up": {
        "NEVER": {
          "W1": "2x6 Reps",
          "W2": "2x8 Reps",
          "W3": "2x10 Reps",
          "W4": "2x5 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "2x10 Reps",
          "W2": "2x12 Reps",
          "W3": "3x10 Reps",
          "W4": "2x7 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "3x10 Reps",
          "W2": "3x12 Reps",
          "W3": "3x14 Reps",
          "W4": "2x8 Reps (Deload)",
        },
        "DAILY": {
          "W1": "3x12 Reps",
          "W2": "3x15 Reps",
          "W3": "4x12 Reps",
          "W4": "3x8 Reps (Deload)",
        },
      },
      "Squat": {
        "NEVER": {
          "W1": "2x10 Reps",
          "W2": "2x12 Reps",
          "W3": "2x15 Reps",
          "W4": "2x8 Reps (Deload)",
        },
        "SOMETIMES": {
          "W1": "2x15 Reps",
          "W2": "3x12 Reps",
          "W3": "3x14 Reps",
          "W4": "2x10 Reps (Deload)",
        },
        "OFTEN": {
          "W1": "3x14 Reps",
          "W2": "3x16 Reps",
          "W3": "3x18 Reps",
          "W4": "2x12 Reps (Deload)",
        },
        "DAILY": {
          "W1": "3x18 Reps",
          "W2": "3x20 Reps",
          "W3": "4x18 Reps",
          "W4": "3x12 Reps (Deload)",
        },
      },
      "Plank": {
        "NEVER": {
          "W1": "2x15 Detik",
          "W2": "2x20 Detik",
          "W3": "2x25 Detik",
          "W4": "2x12 Detik (Deload)",
        },
        "SOMETIMES": {
          "W1": "2x25 Detik",
          "W2": "2x30 Detik",
          "W3": "3x25 Detik",
          "W4": "2x18 Detik (Deload)",
        },
        "OFTEN": {
          "W1": "3x30 Detik",
          "W2": "3x35 Detik",
          "W3": "3x40 Detik",
          "W4": "2x25 Detik (Deload)",
        },
        "DAILY": {
          "W1": "3x40 Detik",
          "W2": "3x50 Detik",
          "W3": "3x60 Detik",
          "W4": "3x30 Detik (Deload)",
        },
      },
      "Cooling Down": {
        // Pendinginan: tetap (tidak perlu progresivitas)
        "NEVER": {
          "W1": "5 Menit",
          "W2": "5 Menit",
          "W3": "5 Menit",
          "W4": "5 Menit",
        },
        "SOMETIMES": {
          "W1": "5 Menit",
          "W2": "5 Menit",
          "W3": "5 Menit",
          "W4": "5 Menit",
        },
        "OFTEN": {
          "W1": "5 Menit",
          "W2": "5 Menit",
          "W3": "5 Menit",
          "W4": "5 Menit",
        },
        "DAILY": {
          "W1": "5 Menit",
          "W2": "5 Menit",
          "W3": "5 Menit",
          "W4": "5 Menit",
        },
      },
    },
  };

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
        },
        {
          "name": "{focus}",
          "target": "{target}",
          "type": "dist",
          "icon_code": 59382,
        },
        {
          "name": "Cooling Down",
          "target": "5 Menit",
          "type": "time",
          "icon_code": 60235,
        },
      ],
      "female_extra": {
        "name": "Injury Prevention",
        "target": "Tambahkan glute activation untuk stabilitas ACL.",
        "type": "info",
        "icon_code": 61279,
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
        },
        {
          "name": "{focus}",
          "target": "{target}",
          "type": "dist",
          "icon_code": 59361,
        },
      ],
      "female_extra": {
        "name": "Sport Note",
        "target": "Perhatikan kekuatan core & pinggul untuk efisiensi kayuhan.",
        "type": "info",
        "icon_code": 61279,
      },
    },

    "basketball": {
      "title": "BASKETBALL ELITE SYSTEM",
      "levels": {
        "NEVER": {"duration": 30},
        "SOMETIMES": {"duration": 45},
        "OFTEN": {"duration": 75},
        "DAILY": {"duration": 90},
      },
      "male_template": [
        {
          "name": "Dynamic Stretching",
          "target": "10 Menit",
          "type": "time",
          "icon_code": 58788,
          "video_url":
              "https://youtube.com/shorts/nPCPhqEJ3r4?si=MFQEnVj9dQDnhtTH",
          "start_at": 6,
        },
        {
          "name": "Ball Slaps & Handling",
          "target": "50 Reps",
          "type": "reps",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Mikan Drill + Form Shooting",
          "target": "{duration} Menit",
          "type": "time",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Zig-Zag Defensive Slides",
          "target": "4 Full Court",
          "type": "reps",
          "icon_code": 59382,
          "video_url": "",
        },
        {
          "name": "Physical: Push Ups",
          "target": "3 Sets x 15",
          "type": "reps",
          "icon_code": 59405,
          "video_url": "",
        },
        {
          "name": "Crossover Dribble Drill",
          "target": "3 Menit",
          "type": "time",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Pull-Up Jumper (Mid-Range)",
          "target": "20 Reps",
          "type": "reps",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Suicide Sprints",
          "target": "5 Sets",
          "type": "reps",
          "icon_code": 59382,
          "video_url": "",
        },
        {
          "name": "Box Out & Rebound Drill",
          "target": "15 Reps",
          "type": "reps",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Free Throw Routine",
          "target": "20 Reps",
          "type": "reps",
          "icon_code": 60230,
          "video_url": "",
        },
      ],
      "female_template": [
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
        {
          "name": "Pocket Dribble Focus",
          "target": "2 Menit/Tangan",
          "type": "time",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Catch & Shoot Midrange",
          "target": "{duration} Menit",
          "type": "time",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Free Throw Pressure",
          "target": "10 Reps (Miss=Sprint)",
          "type": "reps",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Injury Prevention",
          "target": "Latihan Glute & Hamstring (3x12 Squat)",
          "type": "info",
          "icon_code": 61279,
          "video_url": "",
        },
        {
          "name": "Behind-the-Back Dribble",
          "target": "2 Menit/Tangan",
          "type": "time",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Layup Drill (Both Hands)",
          "target": "10 Reps/Tangan",
          "type": "reps",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Defensive Shuffle & Sprint",
          "target": "5 Full Court",
          "type": "reps",
          "icon_code": 59382,
          "video_url": "",
        },
        {
          "name": "V-Cut & Catch Shoot",
          "target": "15 Reps",
          "type": "reps",
          "icon_code": 60230,
          "video_url": "",
        },
        {
          "name": "Passing Accuracy Drill",
          "target": "3 Menit",
          "type": "time",
          "icon_code": 60230,
          "video_url": "",
        },
      ],
    },

    "football": {
      "title": "PRO FOOTBALL TRAINING",
      "levels": {
        "NEVER": {"duration": 30},
        "SOMETIMES": {"duration": 45},
        "OFTEN": {"duration": 70},
        "DAILY": {"duration": 90},
      },
      "male_template": [
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
        {
          "name": "Wall Pass (First Touch)",
          "target": "50 Reps/Kaki",
          "type": "reps",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Rondo Simulation / High Press",
          "target": "{duration} Menit",
          "type": "time",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Long Ball Accuracy",
          "target": "20 Reps (30m)",
          "type": "reps",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Agility Ladder Runs",
          "target": "5 Sets",
          "type": "reps",
          "icon_code": 59382,
          "video_url": "",
        },
        {
          "name": "Cone Weave Dribbling",
          "target": "10 Cones x 4",
          "type": "reps",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Heading Accuracy",
          "target": "15 Reps",
          "type": "reps",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "1v1 Attacking Moves",
          "target": "10 Menit",
          "type": "time",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Crossing & Finishing",
          "target": "15 Reps/Sisi",
          "type": "reps",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Short Passing Combinations",
          "target": "5 Menit",
          "type": "time",
          "icon_code": 60231,
          "video_url": "",
        },
      ],
      "female_template": [
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
        {
          "name": "Possession Control / 5v5 Sim",
          "target": "{duration} Menit",
          "type": "time",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Shooting from Distance",
          "target": "20 Shots",
          "type": "reps",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Counter Attack Sprint",
          "target": "60m Sprint to Finish",
          "type": "dist",
          "icon_code": 59382,
          "video_url": "",
        },
        {
          "name": "FIFA 11+ Prevention",
          "target": "Ligament Strength (ACL Focus)",
          "type": "info",
          "icon_code": 61279,
          "video_url": "",
        },
        {
          "name": "Juggling (Ball Control)",
          "target": "3 Menit",
          "type": "time",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Through Ball Drill",
          "target": "10 Reps",
          "type": "reps",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Quick Turn & Shoot",
          "target": "12 Reps",
          "type": "reps",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Defensive Positioning Drill",
          "target": "5 Menit",
          "type": "time",
          "icon_code": 60231,
          "video_url": "",
        },
        {
          "name": "Set Piece Practice",
          "target": "10 Free Kicks",
          "type": "reps",
          "icon_code": 60231,
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
          {
            "name": "Flutter Kicks",
            "target": "30 Reps",
            "type": "reps",
            "icon_code": 59375,
            "video_url": "",
          },
          {
            "name": "Bicycle Crunches",
            "target": "24 Reps",
            "type": "reps",
            "icon_code": 59375,
            "video_url": "",
          },
          {
            "name": "Lateral Lunges",
            "target": "16 Reps",
            "type": "reps",
            "icon_code": 59387,
            "video_url": "",
          },
          {
            "name": "Star Jumps",
            "target": "15 Reps",
            "type": "reps",
            "icon_code": 58788,
            "video_url": "",
          },
          {
            "name": "Bear Crawl",
            "target": "30 Detik",
            "type": "time",
            "icon_code": 59405,
            "video_url": "",
          },
          {
            "name": "Inchworm",
            "target": "8 Reps",
            "type": "reps",
            "icon_code": 59405,
            "video_url": "",
          },
          {
            "name": "Shadow Boxing",
            "target": "2 Menit",
            "type": "time",
            "icon_code": 59405,
            "video_url": "",
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
          {
            "name": "Close Grip Push Up",
            "target": "12 Reps",
            "type": "reps",
            "icon_code": 59405,
            "video_url": "",
          },
          {
            "name": "Archer Push Up",
            "target": "8 Reps/Sisi",
            "type": "reps",
            "icon_code": 59405,
            "video_url": "",
          },
          {
            "name": "Glute Bridge",
            "target": "20 Reps",
            "type": "reps",
            "icon_code": 59387,
            "video_url": "",
          },
          {
            "name": "Side Plank",
            "target": "30 Detik/Sisi",
            "type": "time",
            "icon_code": 61460,
            "video_url": "",
          },
          {
            "name": "Calf Raises",
            "target": "25 Reps",
            "type": "reps",
            "icon_code": 59387,
            "video_url": "",
          },
          {
            "name": "Superman Pull",
            "target": "12 Reps",
            "type": "reps",
            "icon_code": 60235,
            "video_url": "",
          },
          {
            "name": "Decline Push Up",
            "target": "10 Reps",
            "type": "reps",
            "icon_code": 59405,
            "video_url": "",
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
          {
            "name": "Glute Bridge",
            "target": "15 Reps",
            "type": "reps",
            "icon_code": 59387,
            "video_url": "",
          },
          {
            "name": "Dead Bug",
            "target": "12 Reps",
            "type": "reps",
            "icon_code": 59375,
            "video_url": "",
          },
          {
            "name": "Wall Sit",
            "target": "30 Detik",
            "type": "time",
            "icon_code": 59132,
            "video_url": "",
          },
          {
            "name": "Standing Calf Raises",
            "target": "20 Reps",
            "type": "reps",
            "icon_code": 59387,
            "video_url": "",
          },
          {
            "name": "Shoulder Tap Plank",
            "target": "16 Reps",
            "type": "reps",
            "icon_code": 61460,
            "video_url": "",
          },
          {
            "name": "Hip Circles",
            "target": "1 Menit",
            "type": "time",
            "icon_code": 58788,
            "video_url": "",
          },
          {
            "name": "World's Greatest Stretch",
            "target": "8 Reps/Sisi",
            "type": "reps",
            "icon_code": 60235,
            "video_url": "",
          },
        ],
      },
    },
  };

  // -------------------------------------------------------
  // 🔧 HELPER: Hitung minggu ke berapa berdasarkan TOTAL SESI AKTIF
  // Bukan dari tanggal kalender, tapi dari berapa kali user benar-benar workout
  // Setiap 7 sesi = naik 1 minggu, loop setiap 4 minggu (28 sesi)
  // -------------------------------------------------------
  static String getCurrentWeekKey(int totalSessions) {
    // 0-6 sesi = W1, 7-13 = W2, 14-20 = W3, 21-27 = W4 (Deload)
    // 28+ = loop kembali (siklus baru)
    final weekNumber = (totalSessions ~/ 7) % 4;
    return "W${weekNumber + 1}";
  }

  // -------------------------------------------------------
  // 🔧 HELPER: Ambil target reps yang sudah diprogresifkan
  // Return "—" jika data tidak tersedia (fallback ke target default)
  // -------------------------------------------------------
  static String getProgressiveTarget({
    required String exerciseName,
    required String goal,
    required String level,
    required String weekKey,
  }) {
    try {
      final goalData = _progressionData[goal];
      if (goalData == null) return "—";
      final exerciseData = goalData[exerciseName];
      if (exerciseData == null) return "—";
      final levelData = exerciseData[level];
      if (levelData == null) return "—";
      return levelData[weekKey] ?? "—";
    } catch (e) {
      return "—";
    }
  }

  // 🔥 UTAMA: Generate Routine berdasarkan Data (Online / Local)
  static Map<String, dynamic> generateRoutine({
    required String sportType,
    required String goal,
    required String level,
    String gender = "UNKNOWN",
    String weather = "",
    required int temp,
    bool isIndoor = false,
    int frequency = 1,
    int totalSessions = 0, // 🔥 Total sesi dari gamification (bukan tanggal)
    LanguageProvider? lang,
  }) {
    // 1. Pilih Sumber Data
    Map<String, dynamic> library = _defaultWorkoutLibrary;

    String sportKey = _mapSportKey(sportType);
    String userLevel = level.toUpperCase();
    if (userLevel == "TIDAK PERNAH BEROLAHRAGA") userLevel = "NEVER";
    if (userLevel == "LUMAYAN SERING") userLevel = "SOMETIMES";
    if (userLevel == "SERING" || userLevel == "EVERY_DAY") userLevel = "OFTEN";

    String userGender = _normalizeGender(gender);
    String userGoal = goal.toUpperCase();

    if (!library.containsKey(sportKey)) {
      sportKey = "home";
    }

    final sportData = library[sportKey];
    String title = sportData['title'] ?? sportType;
    String weatherAdvice = "";
    List<Map<String, dynamic>> exercises = [];

    // --- LOGIKA PER CABANG OLAHRAGA ---

    // A. LARI & SEPEDA
    if (sportKey == "running" || sportKey == "cycling") {
      weatherAdvice = _getWeatherText(
        sportKey,
        sportData['weather_advice'],
        temp,
        lang,
      );

      final levelData =
          sportData['levels'][userLevel] ?? sportData['levels']['SOMETIMES'];

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

      for (var ex in template) {
        ex['name'] = ex['name'].replaceAll("{focus}", focus);
        ex['target'] = ex['target'].replaceAll("{target}", targetDisplay);
      }
      exercises = template;

      if (userGender == "FEMALE" && sportData['female_extra'] != null) {
        exercises.add(Map<String, dynamic>.from(sportData['female_extra']));
      }
    }
    // B. BASKET & BOLA
    else if (sportKey == "basketball" || sportKey == "football") {
      final levelData = sportData['levels'][userLevel] ?? {"duration": 45};
      double duration = (levelData['duration'] as num).toDouble();

      if (userGender == "FEMALE" && !isIndoor) {
        duration = _applyFemaleWeatherAdjustment(duration, temp, weather);
        weatherAdvice = _getWeatherText(
          "home",
          library['home']['weather_advice'],
          temp,
          lang,
        );
      } else {
        weatherAdvice = _getWeatherText(
          "running",
          library["running"]['weather_advice'],
          temp,
          lang,
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

      // 🔄 DAILY ROLLING: Rotasi gerakan basket/bola setiap hari
      String warmupName = template.isNotEmpty ? template.first['name'] : '';
      exercises = _selectDailyExercises(template, 5,
        alwaysIncludeNames: [warmupName],
      );
    }
    // C. HOME WORKOUT — 🔥 DENGAN PROGRESIVITAS
    else {
      weatherAdvice = _getWeatherText(
        "home",
        sportData['weather_advice'],
        temp,
        lang,
      );

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
      var fullPool = List<Map<String, dynamic>>.from(
        rawList.map((x) => Map<String, dynamic>.from(x)),
      );

      // 🔄 DAILY ROLLING: Rotasi gerakan home workout setiap hari
      List<String> fixedNames = [];
      if (goalKey == "KEEP_FIT") {
        fixedNames = ['Pemanasan Dinamis', 'Cooling Down'];
      }
      exercises = _selectDailyExercises(fullPool, 6, alwaysIncludeNames: fixedNames);

      // 🔥 TERAPKAN PROGRESIVITAS berdasarkan total sesi aktif
      String weekKey = getCurrentWeekKey(totalSessions);

      for (var ex in exercises) {
        String progressiveTarget = getProgressiveTarget(
          exerciseName: ex['name'],
          goal: goalKey,
          level: userLevel,
          weekKey: weekKey,
        );
        // Update target hanya jika data progresivitas tersedia dan bukan SKIP
        if (progressiveTarget != "—" && !progressiveTarget.startsWith("SKIP")) {
          ex['target'] = progressiveTarget;
        }
      }

      // Female Adjustments for Reps (tetap berlaku)
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

    // 🔥 UPDATE LOGIC JAM 12 & 18
    String sessionLabel = "";
    bool isRestTime = false;

    if (frequency == 2) {
      int hour = DateTime.now().hour;
      if (hour >= 18) {
        isRestTime = true;
      } else if (hour >= 12) {
        sessionLabel = " (Sesi Sore ☀️)";
      } else {
        sessionLabel = " (Sesi Pagi 🌅)";
      }
    }

    // Process Icons
    for (var ex in exercises) {
      if (ex['icon_code'] != null) {
        ex['icon'] = IconData(ex['icon_code'], fontFamily: 'MaterialIcons');
      } else {
        ex['icon'] = Icons.fitness_center;
      }
    }

    // Add Lora Advice / Rest Card
    if (isRestTime) {
      exercises.clear();
      exercises.add({
        "name": "Waktunya Istirahat 🌙",
        "target": "Tubuh butuh recovery untuk performa maksimal besok.",
        "type": "info",
        "icon": Icons.nights_stay,
        "isSelected": true,
      });
      weatherAdvice = "Selamat beristirahat.";
      title = "REST MODE";
    } else {
      String loraTitle = lang != null
          ? (lang.translate('workout.loraAdvice') != 'workout.loraAdvice'
                ? lang.translate('workout.loraAdvice')
                : 'Saran Lora')
          : 'Saran Lora';
      exercises.insert(0, {
        "name": "$loraTitle$sessionLabel",
        "target": weatherAdvice,
        "type": "info",
        "icon": Icons.lightbulb,
        "isSelected": true,
      });
    }

    return {
      "exercises": exercises,
      "title": "$title ($userLevel)",
      "weather_advice": weatherAdvice,
    };
  }

  // --- HELPER FUNCTIONS ---

  // 🔄 DAILY ROLLING: Pilih subset gerakan berbeda setiap hari
  // Menggunakan seed dari tanggal agar konsisten sepanjang hari
  // tapi berubah keesokan harinya
  static List<Map<String, dynamic>> _selectDailyExercises(
    List<Map<String, dynamic>> pool,
    int exercisesPerDay, {
    List<String> alwaysIncludeNames = const [],
  }) {
    if (pool.length <= exercisesPerDay) return pool;

    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final daySeed = now.year * 1000 + dayOfYear;
    final random = Random(daySeed);

    List<Map<String, dynamic>> fixed = [];
    List<Map<String, dynamic>> rotatable = [];

    for (var ex in pool) {
      if (alwaysIncludeNames.contains(ex['name'])) {
        fixed.add(ex);
      } else {
        rotatable.add(ex);
      }
    }

    int pickCount = (exercisesPerDay - fixed.length).clamp(0, rotatable.length);
    rotatable.shuffle(random);

    // Gabungkan: fixed exercises di posisi asli, rotatable di antara
    List<Map<String, dynamic>> result = [];
    int rotatableIdx = 0;
    for (var ex in pool) {
      if (alwaysIncludeNames.contains(ex['name'])) {
        result.add(ex);
      } else if (rotatable.take(pickCount).contains(ex)) {
        result.add(ex);
      }
    }
    return result;
  }

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

  static String _getWeatherText(
    String sportKey,
    dynamic adviceData,
    int temp,
    LanguageProvider? lang,
  ) {
    if (adviceData == null) return "Cuaca OK.";
    final advice = Map<String, dynamic>.from(adviceData as Map);
    String tp = '$temp';
    String msg = "";

    String getTranslationText(String levelType, String fallback) {
      if (lang != null) {
        String prefix = sportKey;
        if (sportKey == "running") prefix = "run";
        if (sportKey == "cycling") prefix = "cycle";
        String key = "workout.${prefix}${levelType}";
        String translated = lang.translate(key);
        if (translated != key) return translated;
      }
      return fallback;
    }

    if (temp >= 33)
      msg = getTranslationText("Danger", advice['danger'] ?? "");
    else if (temp >= 28)
      msg = getTranslationText(
        "Hot",
        advice['hot'] ?? getTranslationText("Warm", advice['warm'] ?? ""),
      );
    else if (temp >= 18)
      msg = getTranslationText("Ideal", advice['ideal'] ?? "");
    else
      msg = getTranslationText("Cold", advice['cold'] ?? "");

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
        print("✅ Online Workout Data Loaded!");
      }
    } catch (e) {
      print("Gagal ambil workout data: $e");
    }
  }
}
