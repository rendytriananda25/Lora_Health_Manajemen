import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/features/workout/domain/entities/workout_session_entity.dart';

/// Kontrak repository untuk Workout.
abstract class WorkoutRepository {
  /// Ambil daftar olahraga yang dipilih user.
  Future<Result<List<String>>> getUserSports();

  /// Ambil preferensi user (level, goal, gender, weight, frequency, sessions).
  Future<Result<Map<String, dynamic>>> getUserPreferences();

  /// Ambil nama user.
  Future<Result<String>> getUserName();

  /// Simpan sesi workout ke Firebase.
  Future<Result<void>> saveWorkoutSession(WorkoutSessionEntity session);

  /// Ambil data cuaca sederhana berdasarkan koordinat.
  Future<Result<Map<String, dynamic>>> getWeather(double lat, double lon);
}
