import 'package:lora_1/core/errors/either.dart';

abstract class StatsRepository {
  Future<Result<List<String>>> getUserSports();

  Future<Result<List<Map<String, dynamic>>>> getWorkoutHistory();
}
