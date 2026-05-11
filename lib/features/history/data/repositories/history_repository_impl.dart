import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/core/errors/failures.dart';
import 'package:lora_1/features/history/data/datasources/history_remote_datasource.dart';
import 'package:lora_1/features/history/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource remoteDataSource;

  HistoryRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Map<String, dynamic>>> getHistoryStream() {
    return remoteDataSource.getHistoryStream().map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      Map values = snapshot.value as Map;
      List<Map<String, dynamic>> historyList = [];
      
      values.forEach((key, value) {
        var item = Map<String, dynamic>.from(value);
        item['key'] = key;
        historyList.add(item);
      });

      historyList.sort(
        (a, b) => (b['time'] ?? "").compareTo(a['time'] ?? ""),
      );

      return historyList;
    });
  }

  @override
  Future<Result<void>> deleteHistoryItem(String key) async {
    try {
      await remoteDataSource.deleteHistory(key);
      return Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
