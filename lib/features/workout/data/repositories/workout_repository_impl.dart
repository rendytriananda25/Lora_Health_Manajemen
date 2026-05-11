import 'package:flutter/foundation.dart';
import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/core/errors/failures.dart';
import 'package:lora_1/core/errors/exceptions.dart';
import 'package:lora_1/features/workout/domain/entities/workout_session_entity.dart';
import 'package:lora_1/features/workout/domain/repositories/workout_repository.dart';
import 'package:lora_1/features/workout/data/datasources/workout_remote_datasource.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutRemoteDataSource dataSource;

  WorkoutRepositoryImpl({required this.dataSource});

  @override
  Future<Result<List<String>>> getUserSports() async {
    try {
      final sports = await dataSource.fetchUserSports();
      return Result.right(sports);
    } on ServerException catch (e) {
      return Result.left(AuthFailure(e.message));
    } catch (e) {
      debugPrint('WorkoutRepo getUserSports Error: $e');
      return Result.left(ServerFailure('Gagal memuat olahraga'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserPreferences() async {
    try {
      final prefs = await dataSource.fetchUserPreferences();
      return Result.right(prefs);
    } catch (e) {
      debugPrint('WorkoutRepo getUserPrefs Error: $e');
      return Result.left(ServerFailure('Gagal memuat preferensi'));
    }
  }

  @override
  Future<Result<String>> getUserName() async {
    try {
      final name = await dataSource.fetchUserName();
      return Result.right(name);
    } catch (e) {
      return Result.right('User');
    }
  }

  @override
  Future<Result<void>> saveWorkoutSession(WorkoutSessionEntity session) async {
    try {
      await dataSource.saveWorkoutSession(session.toFirebaseMap());
      return Result.right(null);
    } on ServerException catch (e) {
      return Result.left(AuthFailure(e.message));
    } catch (e) {
      debugPrint('WorkoutRepo saveSession Error: $e');
      return Result.left(ServerFailure('Gagal menyimpan sesi'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getWeather(double lat, double lon) async {
    try {
      final data = await dataSource.fetchWeather(lat, lon);
      return Result.right(data);
    } catch (e) {
      debugPrint('WorkoutRepo getWeather Error: $e');
      return Result.left(ServerFailure('Gagal memuat cuaca'));
    }
  }
}
