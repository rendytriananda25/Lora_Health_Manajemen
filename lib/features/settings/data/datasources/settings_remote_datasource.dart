import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsRemoteDataSource {
  final FirebaseAuth auth = FirebaseAuth.instance;

  FirebaseDatabase get db => FirebaseDatabase.instanceFor(
        app: auth.app,
        databaseURL:
            "https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app",
      );

  Future<Map<String, dynamic>> getUserProfile() async {
    final user = auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final Map<String, dynamic> result = {
      "uid": user.uid,
      "email": user.email ?? "No Email",
      "fullName": user.displayName ?? "User",
      "photoUrl": user.photoURL,
      "height": "--",
      "weight": "--",
      "gender": "--",
      "age": "--",
    };

    final snapshot = await db.ref("users/${user.uid}").get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final dbName =
          data['username']?.toString() ?? data['full_name']?.toString();
      if (dbName != null && dbName.isNotEmpty) {
        result['fullName'] = dbName;
      }
      
      final healthData = data['health_data'] as Map?;
      if (healthData != null) {
        result['height'] = healthData['height']?.toString() ?? "--";
        result['weight'] = healthData['weight']?.toString() ?? "--";
        result['gender'] = healthData['gender']?.toString() ?? "--";
        result['age'] = healthData['age']?.toString() ?? "--";
      }
    }

    return result;
  }

  Future<void> updateUserName(String newName) async {
    final user = auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    await db.ref("users/${user.uid}").update({
      "username": newName,
      "full_name": newName,
    });
    await user.updateDisplayName(newName);
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await auth.signOut();
  }
}
