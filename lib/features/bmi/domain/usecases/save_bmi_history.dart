import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/features/bmi/domain/repositories/bmi_repository.dart';

class SaveBmiHistory {
  final BmiRepository repository;

  SaveBmiHistory(this.repository);

  Future<Result<void>> call({
    required double score,
    required String status,
    required int weight,
    required int height,
  }) {
    return repository.saveBmiHistory(
      score: score,
      status: status,
      weight: weight,
      height: height,
    );
  }
}
