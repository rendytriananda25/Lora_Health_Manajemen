
class WorkoutTimeSlot {
  final String timeRange;
  final String intensity;
  final int rating;
  final String reason;
  final String benefit;

  const WorkoutTimeSlot({
    required this.timeRange,
    required this.intensity,
    required this.rating,
    required this.reason,
    required this.benefit,
  });

  Map<String, dynamic> toMap() {
    return {
      "time_range": timeRange,
      "intensity": intensity,
      "rating": rating,
      "reason": reason,
      "benefit": benefit,
    };
  }
}

class WorkoutTimeRecommendation {
  final String sport;
  final double temperature;
  final String goal;
  final List<WorkoutTimeSlot> recommendedSlots;
  final String note;

  const WorkoutTimeRecommendation({
    required this.sport,
    required this.temperature,
    required this.goal,
    required this.recommendedSlots,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      "sport": sport,
      "temperature": temperature,
      "goal": goal,
      "recommended_slots": recommendedSlots.map((e) => e.toMap()).toList(),
      "note": note,
    };
  }
}

class WorkoutTimeEngine {
  static WorkoutTimeRecommendation getBestWorkoutTime({
    required String sport,
    required bool isIndoor,
    required double temperature,
    required String goal,
  }) {
    final normalizedSport = sport.toUpperCase().trim();
    final normalizedGoal = goal.toUpperCase().trim();

    final slots = <WorkoutTimeSlot>[
      _morningRecommendation(
        normalizedSport,
        isIndoor,
        temperature,
        normalizedGoal,
      ),
      _eveningRecommendation(
        normalizedSport,
        isIndoor,
        temperature,
        normalizedGoal,
      ),
      _nightRecommendation(
        normalizedSport,
        isIndoor,
        temperature,
        normalizedGoal,
      ),
    ];

    return WorkoutTimeRecommendation(
      sport: normalizedSport,
      temperature: temperature,
      goal: normalizedGoal,
      recommendedSlots: slots,
      note:
          "Sore hari umumnya performa fisik lebih optimal karena suhu inti tubuh lebih tinggi.",
    );
  }

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

  static String hydrationAdvice(double temperature) {
    if (temperature >= 33) {
      return "Minum 600-800 ml per jam aktivitas.";
    } else if (temperature >= 28) {
      return "Minum 500-700 ml per jam aktivitas.";
    }
    return "Minum 400-600 ml per jam aktivitas.";
  }

  static WorkoutTimeSlot _morningRecommendation(
    String sport,
    bool isIndoor,
    double temperature,
    String goal,
  ) {
    var intensity = "RINGAN - SEDANG";
    var benefit = "Meningkatkan konsistensi & pembakaran lemak";

    if (goal == "FAT_LOSS") {
      benefit = "Optimal untuk fat burning (kondisi glikogen rendah).";
    } else if (goal == "PERFORMANCE") {
      benefit = "Bagus untuk sesi teknik, mobilitas, dan konsistensi latihan.";
    }

    if (!isIndoor && temperature >= 32) {
      return WorkoutTimeSlot(
        timeRange: "05:00 - 07:30",
        intensity: intensity,
        rating: 5,
        reason: "Paling aman untuk olahraga outdoor saat suhu tinggi.",
        benefit: benefit,
      );
    }

    final morningRatingBoostSports = {"LARI", "SEPEDA"};
    final rating = morningRatingBoostSports.contains(sport) ? 5 : 4;

    return WorkoutTimeSlot(
      timeRange: "05:30 - 09:00",
      intensity: intensity,
      rating: rating,
      reason: "Udara masih segar & risiko dehidrasi lebih rendah.",
      benefit: benefit,
    );
  }

  static WorkoutTimeSlot _eveningRecommendation(
    String sport,
    bool isIndoor,
    double temperature,
    String goal,
  ) {
    var intensity = "SEDANG - TINGGI";
    var benefit = "Performa otot, reaksi, dan power berada di titik optimal.";
    var rating = 5;

    if (goal == "PERFORMANCE") {
      rating = 5;
      benefit = "Waktu terbaik untuk speed, sprint, dan latihan kompetitif.";
    } else if (goal == "CASUAL") {
      rating = 4;
      benefit = "Cocok untuk sesi olahraga rutin setelah aktivitas harian.";
    }

    if (!isIndoor && temperature >= 33) {
      rating = 4;
      intensity = "SEDANG";
      benefit = "Tetap bagus, tapi kurangi intensitas karena suhu cukup panas.";
    }

    return WorkoutTimeSlot(
      timeRange: "16:00 - 18:30",
      intensity: intensity,
      rating: rating,
      reason: "Suhu inti tubuh tinggi -> fleksibilitas & kekuatan maksimal.",
      benefit: benefit,
    );
  }

  static WorkoutTimeSlot _nightRecommendation(
    String sport,
    bool isIndoor,
    double temperature,
    String goal,
  ) {
    var rating = 3;
    var reason = "Cocok untuk latihan santai atau recovery session.";
    var benefit =
        "Hindari intensitas tinggi agar tidak mengganggu kualitas tidur.";

    if (goal == "FAT_LOSS" && isIndoor) {
      rating = 4;
      reason = "Masih efektif untuk sesi kardio ringan indoor.";
      benefit = "Aman untuk pembakaran kalori ringan tanpa ganggu tidur.";
    }

    return WorkoutTimeSlot(
      timeRange: "19:30 - 21:00",
      intensity: "RINGAN",
      rating: rating,
      reason: reason,
      benefit: benefit,
    );
  }

  static WorkoutTimeSlot? bestSlot(WorkoutTimeRecommendation recommendation) {
    if (recommendation.recommendedSlots.isEmpty) return null;
    final sorted = [...recommendation.recommendedSlots]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.first;
  }

  static String suggestedTarget({
    required String sport,
    required String level,
    required double temperature,
    String weather = "",
  }) {
    final s = sport.toUpperCase();
    final l = level.toUpperCase();

    if (s == "LARI") {
      final base = {
        "NEVER": 2.0,
        "SOMETIMES": 4.0,
        "OFTEN": 7.0,
        "DAILY": 10.0,
      }[l] ??
          4.0;
      final adjusted = _weatherAdjustment(base, temperature, weather);
      return "${adjusted.toStringAsFixed(1)} KM";
    }

    if (s == "SEPEDA") {
      final base = {
        "NEVER": 5.0,
        "SOMETIMES": 12.0,
        "OFTEN": 25.0,
        "DAILY": 40.0,
      }[l] ??
          12.0;
      final adjusted = _weatherAdjustment(base, temperature, weather);
      return "${adjusted.toStringAsFixed(1)} KM";
    }

    if (s == "BASKET" || s == "BASKETBALL") {
      final minutes = {
        "NEVER": 20,
        "SOMETIMES": 35,
        "OFTEN": 60,
        "DAILY": 90,
      }[l] ??
          35;
      return "$minutes Menit";
    }

    if (s == "BOLA" || s == "FOOTBALL" || s == "SEPAK BOLA") {
      final minutes = {
        "NEVER": 30,
        "SOMETIMES": 50,
        "OFTEN": 75,
        "DAILY": 100,
      }[l] ??
          50;
      return "$minutes Menit";
    }

    final fallback = {
      "NEVER": 15,
      "SOMETIMES": 25,
      "OFTEN": 35,
      "DAILY": 45,
    }[l] ??
        25;
    return "$fallback Menit";
  }
}
