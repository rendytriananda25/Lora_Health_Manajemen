import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // ✅ Library FB
import 'package:firebase_database/firebase_database.dart';
import 'sports_selection.dart';
import 'navbar.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final TextEditingController _phoneController = TextEditingController();

  // --- 1. LOGIC CEK DATABASE (Dipakai semua metode login) ---
  Future<void> _checkUserAndNavigate(User user) async {
    final userRef = FirebaseDatabase.instance.ref("users/${user.uid}");
    
    // Simpan/Update data dasar
    await userRef.update({
      "username": user.displayName ?? "User Lora",
      "email": user.email ?? "",
      "photoUrl": user.photoURL ?? "",
      "last_login": ServerValue.timestamp,
    });

    final sportSnapshot = await userRef.child("favorite_sports").get();

    if (mounted) {
      if (sportSnapshot.exists) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Navbar()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SportsSelectionPage()));
      }
    }
  }

  // --- 2. LOGIN GOOGLE ---
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) await _checkUserAndNavigate(userCredential.user!);
      }
    } catch (e) {
      debugPrint("Error Google: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. LOGIN FACEBOOK ---
  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) await _checkUserAndNavigate(userCredential.user!);
      }
    } catch (e) {
      debugPrint("Error Facebook: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 4. LOGIN NOMOR TELEPON (OTP) ---
  Future<void> _handlePhoneSignIn() async {
    // Munculkan dialog input nomor
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Text("Input Phone Number", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "+62812345678",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyPhone();
            }, 
            child: const Text("Send OTP")
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPhone() async {
    setState(() => _isLoading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) await _checkUserAndNavigate(userCredential.user!);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${e.message}")));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _isLoading = false);
        _showOTPDialog(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void _showOTPDialog(String verificationId) {
    final TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Text("Enter OTP Code", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(counterText: ""),
          maxLength: 6,
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: verificationId, 
                  smsCode: otpController.text
                );
                UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
                if (userCredential.user != null) {
                  Navigator.pop(context);
                  await _checkUserAndNavigate(userCredential.user!);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
              } finally {
                setState(() => _isLoading = false);
              }
            }, 
            child: const Text("Verify")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/hitam.jpg', fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Let's get started", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  
                  // Google
                  _buildActionButton(label: "Continue With Google", color: Colors.white.withOpacity(0.1), icon: 'google.png', onTap: _handleGoogleSignIn),
                  const SizedBox(height: 12),
                  
                  // Facebook
                  _buildActionButton(label: "Continue With Facebook", color: const Color(0xFF1877F2).withOpacity(0.2), icon: 'facebook.png', onTap: _handleFacebookSignIn),
                  const SizedBox(height: 12),
                  
                  // Phone
                  _buildActionButton(label: "Continue With Phone", color: Colors.white.withOpacity(0.05), icon: null, isPhone: true, onTap: _handlePhoneSignIn),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Color(0xFF9D50FF))),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required Color color, String? icon, bool isPhone = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity, height: 55,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (icon != null) Positioned(left: 20, child: Image.asset('assets/images/$icon', height: 24)),
            if (isPhone) const Positioned(left: 20, child: Icon(Icons.phone_android, color: Colors.white, size: 24)),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}