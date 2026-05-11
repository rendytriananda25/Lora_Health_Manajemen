class ExerciseEntity {
  final String name;
  final String target;
  final String type;
  final String? videoUrl;
  final int? startAt;
  final String? tips;

  const ExerciseEntity({
    required this.name,
    required this.target,
    required this.type,
    this.videoUrl,
    this.startAt,
    this.tips,
  });

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
