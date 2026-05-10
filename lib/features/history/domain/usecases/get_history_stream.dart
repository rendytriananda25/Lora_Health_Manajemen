import 'package:lora_1/features/history/domain/repositories/history_repository.dart';

class GetHistoryStream {
  final HistoryRepository repository;

  GetHistoryStream(this.repository);

  Stream<List<Map<String, dynamic>>> call() {
    return repository.getHistoryStream();
  }
}
