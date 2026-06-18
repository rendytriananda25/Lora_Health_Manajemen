import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lora_1/screen/navbar.dart';
import 'package:lora_1/setup/setup_page.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<User?> loginOrRegisterEmail(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          UserCredential regCred = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          return regCred.user;
        } catch (regErr) {
          _showSnack(context, "Gagal Register: ${regErr.toString()}");
          return null;
        }
      } else {
        _showSnack(context, "Login Gagal: ${e.message}");
        return null;
      }
    } catch (e) {
      _showSnack(context, "Error: $e");
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        return userCredential.user;
      }
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
    }
    return null;
  }

  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );
        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        return userCredential.user;
      }
    } catch (e) {
      debugPrint("Facebook Login Error: $e");
    }
    return null;
  }

  Future<void> checkUserAndNavigate(BuildContext context, User user) async {
    final userRef = _db.ref("users/${user.uid}");

    String autoName =
        user.displayName ??
        (user.email != null ? user.email!.split('@')[0] : "User Lora");

    await userRef.update({
      "username": autoName,
      "email": user.email ?? "",
      "photoUrl": user.photoURL ?? "",
      "last_login": ServerValue.timestamp,
    });

    final sportSnapshot = await userRef.child("favorite_sports").get();

    if (context.mounted) {
      if (sportSnapshot.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Navbar()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SetupPage()),
        );
      }
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
