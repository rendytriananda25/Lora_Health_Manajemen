import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/features/workout/domain/entities/workout_session_entity.dart';

abstract class WorkoutRepository {
  Future<Result<List<String>>> getUserSports();

  Future<Result<Map<String, dynamic>>> getUserPreferences();

  Future<Result<String>> getUserName();

  Future<Result<void>> saveWorkoutSession(WorkoutSessionEntity session);

  Future<Result<Map<String, dynamic>>> getWeather(double lat, double lon);
}
