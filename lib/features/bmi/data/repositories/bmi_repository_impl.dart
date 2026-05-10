import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/core/errors/failures.dart';
import 'package:lora_1/features/bmi/data/datasources/bmi_remote_datasource.dart';
import 'package:lora_1/features/bmi/domain/repositories/bmi_repository.dart';

class BmiRepositoryImpl implements BmiRepository {
  final BmiRemoteDataSource remoteDataSource;

  BmiRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<void>> saveBmiHistory({
    required double score,
    required String status,
    required int weight,
    required int height,
  }) async {
    try {
      final data = {
        'activity': "Cek BMI: ${score.toStringAsFixed(1)}",
        'time': DateTime.now().toIso8601String(),
        'status': status,
        'weight': weight,
        'height': height,
        'bmi_score': score.toStringAsFixed(1),
        'type': 'BMI',
      };
      await remoteDataSource.saveHistory(data);
      return Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
