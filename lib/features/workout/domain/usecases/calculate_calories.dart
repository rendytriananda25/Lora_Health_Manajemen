/// UseCase: Kalkulasi kalori yang dibakar.
///
/// Logika ini dipindahkan dari _executeStop() di map_pages.dart.
/// Sekarang bisa di-unit test tanpa emulator!
class CalculateCalories {
  /// Hitung kalori berdasarkan MET * berat * durasi.
  ///
  /// [sport] — jenis olahraga (Lari, Sepeda, dll)
  /// [weightKg] — berat badan user dalam kg
  /// [durationSec] — durasi sesi dalam detik
  /// [workoutDetails] — detail gerakan (untuk bonus kalori repetisi)
  /// [isGpsSport] — true jika olahraga berbasis GPS (Lari/Sepeda)
  int call({
    required String sport,
    required double weightKg,
    required int durationSec,
    List<Map<String, dynamic>> workoutDetails = const [],
    bool isGpsSport = false,
  }) {
    // 1. Hitung kalori dasar: MET * Berat * Durasi (jam)
    double met = _getMETValue(sport);
    double durationHours = durationSec / 3600.0;
    int calories = (met * weightKg * durationHours).toInt();

    // 2. Bonus kalori dari repetisi (hanya non-GPS sport)
    if (!isGpsSport && workoutDetails.isNotEmpty) {
      double bonusCalories = 0.0;
      for (var item in workoutDetails) {
        String res = item['result']?.toString() ?? '';
        if (res.toLowerCase().contains('reps')) {
          int count = int.tryParse(res.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          bonusCalories += count * 0.4; // ~0.4 kcal per repetisi
        }
      }
      calories += bonusCalories.toInt();
    }

    // 3. Minimal 1 kalori jika durasi > 10 detik
    if (calories == 0 && (durationSec > 10 || workoutDetails.isNotEmpty)) {
      calories = 1;
    }

    return calories;
  }

  /// MET (Metabolic Equivalent) berdasarkan jenis olahraga.
  /// Referensi: Compendium of Physical Activities.
  double _getMETValue(String sport) {
    String s = sport.toUpperCase();
    if (s.contains('LARI') || s.contains('RUN')) return 9.0;
    if (s.contains('SEPEDA') || s.contains('CYCL')) return 7.5;
    if (s.contains('BASKET')) return 6.5;
    if (s.contains('BOLA') || s.contains('SOCCER') || s.contains('FOOTBALL')) return 7.0;
    if (s.contains('JALAN') || s.contains('WALK')) return 3.8;
    if (s.contains('HOME') || s.contains('WORKOUT')) return 5.0;
    return 4.5; // Default moderate
  }
}
