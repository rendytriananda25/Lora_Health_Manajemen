/// Entity untuk satu gerakan latihan.
class ExerciseEntity {
  final String name;
  final String target;    // "15 Reps", "30 Detik"
  final String type;      // 'time', 'reps', 'info'
  final String? videoUrl;
  final int? startAt;     // Detik mulai video
  final String? tips;

  const ExerciseEntity({
    required this.name,
    required this.target,
    required this.type,
    this.videoUrl,
    this.startAt,
    this.tips,
  });

  /// Konversi dari Map (format WorkoutData.generateRoutine).
  factory ExerciseEntity.fromMap(Map<String, dynamic> map) => ExerciseEntity(
    name: map['name'] ?? '',
    target: map['target'] ?? '',
    type: map['type'] ?? 'info',
    videoUrl: map['video_url'],
    startAt: map['start_at'] != null
        ? int.tryParse(map['start_at'].toString())
        : null,
    tips: map['tips'],
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'target': target,
    'type': type,
    'video_url': videoUrl,
    'start_at': startAt,
    'tips': tips,
  };
}
