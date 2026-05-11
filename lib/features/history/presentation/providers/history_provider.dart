import 'package:flutter/material.dart';
import 'package:lora_1/features/history/domain/usecases/get_history_stream.dart';
import 'package:lora_1/features/history/domain/usecases/delete_history_item.dart';

class HistoryProvider extends ChangeNotifier {
  final GetHistoryStream _getHistoryStreamUseCase;
  final DeleteHistoryItem _deleteHistoryItemUseCase;

  HistoryProvider({
    required GetHistoryStream getHistoryStream,
    required DeleteHistoryItem deleteHistoryItem,
  })  : _getHistoryStreamUseCase = getHistoryStream,
        _deleteHistoryItemUseCase = deleteHistoryItem;

  Stream<List<Map<String, dynamic>>> get historyStream => _getHistoryStreamUseCase();

  Future<void> deleteHistory(String key) async {
    final result = await _deleteHistoryItemUseCase(key);
    
    result.fold(
      (failure) {
        debugPrint('History Delete Error: ${failure.message}');
      },
      (_) {
        debugPrint('History item $key deleted successfully');
      },
    );
  }
}
