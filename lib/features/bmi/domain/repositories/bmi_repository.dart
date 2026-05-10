import 'package:lora_1/core/errors/either.dart';

abstract class BmiRepository {
  Future<Result<void>> saveBmiHistory({
    required double score,
    required String status,
    required int weight,
    required int height,
  });
}
