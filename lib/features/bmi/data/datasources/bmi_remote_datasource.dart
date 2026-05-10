import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lora_1/core/errors/exceptions.dart';

class BmiRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<void> saveHistory(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw const ServerException('User belum login');

    final dbRef = _db.ref("users/${user.uid}/history");
    await dbRef.push().set(data);
  }
}
