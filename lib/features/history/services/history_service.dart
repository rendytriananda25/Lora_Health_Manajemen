import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryService {
  final _db = FirebaseDatabase.instance;
  final _auth = FirebaseAuth.instance;

  // Stream data riwayat urut waktu terbaru
  Stream<DatabaseEvent> getHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db.ref("users/${user.uid}/history").orderByChild('time').onValue;
  }

  // Fungsi hapus riwayat
  Future<void> deleteHistory(String key) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.ref("users/${user.uid}/history/$key").remove();
    }
  }
}