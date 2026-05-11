import 'package:lora_1/core/errors/either.dart';

abstract class HistoryRepository {
  Stream<List<Map<String, dynamic>>> getHistoryStream();

  Future<Result<void>> deleteHistoryItem(String key);
}
