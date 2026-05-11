/// Entity untuk satu sesi workout yang sudah selesai.
class WorkoutSessionEntity {
  final String activity;
  final int durationSec;
  final double distanceKm;
  final int calories;
  final DateTime time;
  final List<Map<String, dynamic>>? workoutDetails;
  final String? details;
  /// Rute GPS (titik-titik koordinat lat/lng) untuk olahraga tracking.
  final List<Map<String, double>>? path;
  /// Tipe sesi: "TRACKING" untuk GPS sport, "HOME_WORKOUT" dll.
  final String? type;

  const WorkoutSessionEntity({
    required this.activity,
    required this.durationSec,
    required this.distanceKm,
    required this.calories,
    required this.time,
    this.workoutDetails,
    this.details,
    this.path,
    this.type,
  });

  Map<String, dynamic> toFirebaseMap() => {
    'activity': activity,
    'duration_sec': durationSec,
    'distance_km': distanceKm,
    'calories': calories,
    'time': time.toIso8601String(),
    'details': details,
    'workout_details': workoutDetails,
    if (path != null) 'path': path,
    if (type != null) 'type': type,
  };
}
