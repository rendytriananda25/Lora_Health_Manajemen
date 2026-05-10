import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lora_1/core/errors/exceptions.dart';

/// DataSource untuk fitur Riwayat
class HistoryRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Mendapatkan stream data riwayat dari Firebase
  Stream<DatabaseEvent> getHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _db.ref("users/${user.uid}/history").orderByChild('time').onValue;
  }

  /// Menghapus satu item riwayat berdasarkan key
  Future<void> deleteHistory(String key) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ServerException('User belum login');
    }
    await _db.ref("users/${user.uid}/history/$key").remove();
  }
}
