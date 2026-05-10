/// Entity cuaca — data inti yang digunakan oleh UI.
/// Tidak bergantung pada framework atau sumber data apapun.
class WeatherEntity {
  final String city;
  final String temperature;
  final String condition;
  final int aqi;        // Air Quality Index (0-500)
  final double uvIndex; // UV Index

  const WeatherEntity({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.aqi,
    required this.uvIndex,
  });

  /// Factory untuk state awal (loading / belum ada data).
  factory WeatherEntity.empty() => const WeatherEntity(
    city: 'Memuat Lokasi...',
    temperature: '--',
    condition: 'Memuat...',
    aqi: 0,
    uvIndex: 0.0,
  );
}
