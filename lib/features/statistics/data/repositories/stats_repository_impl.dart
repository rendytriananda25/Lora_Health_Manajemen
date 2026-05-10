import 'package:flutter/foundation.dart';
import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/core/errors/failures.dart';
import 'package:lora_1/features/statistics/domain/repositories/stats_repository.dart';
import 'package:lora_1/features/statistics/data/datasources/stats_remote_datasource.dart';

/// Implementasi StatsRepository.
class StatsRepositoryImpl implements StatsRepository {
  final StatsRemoteDataSource dataSource;

  StatsRepositoryImpl({required this.dataSource});

  @override
  Future<Result<List<String>>> getUserSports() async {
    try {
      final sports = await dataSource.fetchUserSports();
      return Result.right(sports);
    } catch (e) {
      debugPrint('StatsRepo getUserSports Error: $e');
      return Result.left(ServerFailure('Gagal memuat olahraga'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getWorkoutHistory() async {
    try {
      final history = await dataSource.fetchWorkoutHistory();
      return Result.right(history);
    } catch (e) {
      debugPrint('StatsRepo getHistory Error: $e');
      return Result.left(ServerFailure('Gagal memuat history'));
    }
  }
}
