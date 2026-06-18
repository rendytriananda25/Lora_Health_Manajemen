class CalculateCalories {
  int call({
    required String sport,
    required double weightKg,
    required int durationSec,
    List<Map<String, dynamic>> workoutDetails = const [],
    bool isGpsSport = false,
  }) {
    double met = _getMETValue(sport);
    double durationHours = durationSec / 3600.0;
    int calories = (met * weightKg * durationHours).toInt();

    if (!isGpsSport && workoutDetails.isNotEmpty) {
      double bonusCalories = 0.0;
      for (var item in workoutDetails) {
        String res = item['result']?.toString() ?? '';
        if (res.toLowerCase().contains('reps')) {
          int count = int.tryParse(res.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          bonusCalories += count * 0.4;
        }
      }
      calories += bonusCalories.toInt();
    }

    if (calories == 0 && (durationSec > 10 || workoutDetails.isNotEmpty)) {
      calories = 1;
    }

    return calories;
  }

  double _getMETValue(String sport) {
    String s = sport.toUpperCase();
    if (s.contains('LARI') || s.contains('RUN')) return 9.0;
    if (s.contains('SEPEDA') || s.contains('CYCL')) return 7.5;
    if (s.contains('BASKET')) return 6.5;
    if (s.contains('BOLA') || s.contains('SOCCER') || s.contains('FOOTBALL')) return 7.0;
    if (s.contains('JALAN') || s.contains('WALK')) return 3.8;
    if (s.contains('HOME') || s.contains('WORKOUT')) return 5.0;
    return 4.5;
  }
}
