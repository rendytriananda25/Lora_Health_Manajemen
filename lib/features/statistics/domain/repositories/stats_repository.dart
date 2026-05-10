import 'package:lora_1/core/errors/either.dart';

/// Kontrak repository untuk Statistics.
abstract class StatsRepository {
  /// Ambil daftar olahraga yang dipilih user.
  Future<Result<List<String>>> getUserSports();

  /// Ambil seluruh history latihan dari Firebase.
  Future<Result<List<Map<String, dynamic>>>> getWorkoutHistory();
}
