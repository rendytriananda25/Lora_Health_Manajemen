/// UseCase: Tentukan target olahraga berdasarkan level.
///
/// Logika ini dipindahkan dari _getTargetByLevel() di map_pages.dart.
class GetTargetByLevel {
  String call(String sport, String level) {
    final s = sport.toUpperCase();
    final l = level.toUpperCase();

    if (s == 'LARI') {
      if (l == 'NEVER') return '2.0 KM';
      if (l == 'SOMETIMES') return '4.0 KM';
      if (l == 'OFTEN') return '7.0 KM';
      return '10.0 KM';
    }

    if (s == 'SEPEDA') {
      if (l == 'NEVER') return '5.0 KM';
      if (l == 'SOMETIMES') return '12.0 KM';
      if (l == 'OFTEN') return '25.0 KM';
      return '40.0 KM';
    }

    if (s == 'BASKET' || s == 'BASKETBALL') {
      if (l == 'NEVER') return '20 Menit';
      if (l == 'SOMETIMES') return '35 Menit';
      if (l == 'OFTEN') return '60 Menit';
      return '90 Menit';
    }

    if (s == 'BOLA' || s == 'SEPAK BOLA' || s == 'FOOTBALL') {
      if (l == 'NEVER') return '30 Menit';
      if (l == 'SOMETIMES') return '50 Menit';
      if (l == 'OFTEN') return '75 Menit';
      return '100 Menit';
    }

    if (s == 'HOME WORKOUT' || s == 'HOME_WORKOUT') {
      if (l == 'NEVER') return '15 Menit';
      if (l == 'SOMETIMES') return '25 Menit';
      if (l == 'OFTEN') return '35 Menit';
      return '45 Menit';
    }

    return '20 Menit';
  }
}

/// UseCase: Cek apakah olahraga butuh GPS.
class CheckSportType {
  /// Return true jika olahraga ini butuh GPS tracking (Lari/Sepeda).
  bool isGpsSport(String sport) {
    final s = sport.toUpperCase();
    return s == 'LARI' || s == 'SEPEDA' || s == 'RUNNING' || s == 'CYCLING';
  }

  /// Return true jika olahraga ini berbasis durasi (bukan jarak).
  bool isDurationBased(String sport) {
    return !isGpsSport(sport);
  }
}

/// UseCase: Normalize gender string.
class NormalizeGender {
  String call(String raw) {
    final value = raw.trim().toUpperCase();
    if (value == 'FEMALE' || value == 'PEREMPUAN') return 'FEMALE';
    if (value == 'MALE' || value == 'LAKI-LAKI' || value == 'LAKILAKI') return 'MALE';
    return 'UNKNOWN';
  }
}

/// UseCase: Translate sport name by language.
class TranslateSport {
  String call(String sport, String langCode) {
    if (langCode == 'id') return sport;
    switch (sport) {
      case 'Lari':
        return langCode == 'en' ? 'Running' : langCode == 'es' ? 'Correr' : 'ランニング';
      case 'Sepeda':
        return langCode == 'en' ? 'Cycling' : langCode == 'es' ? 'Ciclismo' : 'サイクリング';
      case 'Basket':
        return langCode == 'en' ? 'Basketball' : langCode == 'es' ? 'Baloncesto' : 'バスケットボール';
      case 'Sepak Bola':
      case 'Bola':
        return langCode == 'en' ? 'Football' : langCode == 'es' ? 'Fútbol' : 'サッカー';
      case 'Home Workout':
        return langCode == 'ja' ? 'ホームワークアウト' : sport;
      default:
        return sport;
    }
  }
}
