import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/features/history/domain/repositories/history_repository.dart';

class DeleteHistoryItem {
  final HistoryRepository repository;

  DeleteHistoryItem(this.repository);

  Future<Result<void>> call(String key) {
    return repository.deleteHistoryItem(key);
  }
}
