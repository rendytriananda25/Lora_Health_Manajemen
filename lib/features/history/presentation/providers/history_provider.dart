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

  /// Mendapatkan Stream daftar riwayat dari database
  Stream<List<Map<String, dynamic>>> get historyStream => _getHistoryStreamUseCase();

  /// Menghapus item riwayat dan menangani state/error
  Future<void> deleteHistory(String key) async {
    final result = await _deleteHistoryItemUseCase(key);
    
    result.fold(
      (failure) {
        debugPrint('History Delete Error: ${failure.message}');
        // Bisa tambahkan snackbar atau toast error message di sini jika perlu
      },
      (_) {
        debugPrint('History item $key deleted successfully');
        // notifyListeners() tidak perlu karena StreamBuilder akan update otomatis
      },
    );
  }
}
