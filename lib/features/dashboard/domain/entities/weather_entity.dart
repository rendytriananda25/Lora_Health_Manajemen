class WeatherEntity {
  final String city;
  final String temperature;
  final String condition;
  final int aqi;
  final double uvIndex;

  const WeatherEntity({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.aqi,
    required this.uvIndex,
  });

  factory WeatherEntity.empty() => const WeatherEntity(
    city: 'Memuat Lokasi...',
    temperature: '--',
    condition: 'Memuat...',
    aqi: 0,
    uvIndex: 0.0,
  );
}
