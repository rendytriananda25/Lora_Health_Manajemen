import 'package:lora_1/core/errors/either.dart';

/// Kontrak untuk Repository Riwayat
abstract class HistoryRepository {
  /// Mengambil stream daftar riwayat (sudah diurutkan berdasarkan waktu terbaru)
  Stream<List<Map<String, dynamic>>> getHistoryStream();

  /// Menghapus item riwayat tertentu
  Future<Result<void>> deleteHistoryItem(String key);
}
