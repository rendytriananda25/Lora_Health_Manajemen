import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; 
import 'package:firebase_database/firebase_database.dart';
import 'sports_selection.dart';
import 'navbar.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC AUTH ---
  Future<void> _checkUserAndNavigate(User user) async {
    final userRef = FirebaseDatabase.instance.ref("users/${user.uid}");
    String autoName = user.displayName ?? (user.email != null ? user.email!.split('@')[0] : "User Lora");

    await userRef.update({
      "username": autoName,
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

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email dan Password wajib diisi!")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) await _checkUserAndNavigate(userCredential.user!);
    } catch (e) {
      try {
         UserCredential regCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (regCredential.user != null) await _checkUserAndNavigate(regCredential.user!);
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $err")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) await _checkUserAndNavigate(userCredential.user!);
      }
    } catch (e) { debugPrint("Error Google: $e"); } 
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) await _checkUserAndNavigate(userCredential.user!);
      }
    } catch (e) { debugPrint("Error Facebook: $e"); } 
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // --- UI SCREEN (LAYOUT FIXED) ---
  @override
  Widget build(BuildContext context) {
    // Deteksi Keyboard
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardHeight > 0;
    
    // Space aman bawah (buat navigasi gesture HP)
    final double safePaddingBottom = MediaQuery.of(context).padding.bottom;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent, 
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // Background
          Positioned.fill(child: Image.asset('assets/images/hitam.jpg', fit: BoxFit.cover)),
          
          // Gradient
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(isKeyboardOpen ? 0.95 : 0.85), 
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            top: false, bottom: false,
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false, 
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    padding: EdgeInsets.only(
                      left: 30, 
                      right: 30,
                      // ✅ Padding Bawah: Kalau keyboard buka, kasih jarak keyboard.
                      // Kalau tutup, kasih jarak safe area.
                      bottom: isKeyboardOpen ? keyboardHeight + 20 : safePaddingBottom,
                      top: MediaQuery.of(context).padding.top + 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- HEADER ---
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                const Text(
                                  "Welcome to Lora",
                                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Masuk untuk melanjutkan, dan nikmatti petualangan olahraga bersama Lora",
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Spacer Flexible
                        const Spacer(),

                        // --- FORM ---
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                _buildInput(controller: _emailController, hint: "Email", icon: Icons.email_outlined),
                                const SizedBox(height: 15),
                                _buildInput(controller: _passwordController, hint: "Password", icon: Icons.lock_outline, isPass: true),
                                const SizedBox(height: 25),
                                _buildMainButton(),
                              ],
                            ),
                          ),
                        ),

                        // --- SOCIAL BUTTONS (Fading) ---
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          // Kalau keyboard buka, sembunyikan. Kalau tutup, tampilkan.
                          height: isKeyboardOpen ? 0 : null, 
                          child: SingleChildScrollView( 
                            physics: const NeverScrollableScrollPhysics(),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isKeyboardOpen ? 0.0 : 1.0, 
                              child: Column(
                                children: [
                                  const SizedBox(height: 30),
                                  Row(
                                    children: [
                                      const Expanded(child: Divider(color: Colors.white24)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Text("OR", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                      ),
                                      const Expanded(child: Divider(color: Colors.white24)),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  _buildSocialButton(label: "Continue With Google", color: Colors.white.withOpacity(0.1), iconPath: 'google.png', onTap: _handleGoogleSignIn),
                                  const SizedBox(height: 12),
                                  _buildSocialButton(label: "Continue With Facebook", color: const Color(0xFF1877F2).withOpacity(0.2), iconPath: 'facebook.png', onTap: _handleFacebookSignIn),
                                  
                                  // ✅ INI KUNCINYA WAK! 
                                  // Jarak extra 50 pixel di paling bawah biar tombol FB naik ke atas
                                  const SizedBox(height: 50), 
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Jarak minimal pas keyboard buka biar form ga nempel keyboard banget
                        if (isKeyboardOpen) const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Color(0xFF008BFF))),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildInput({required TextEditingController controller, required String hint, required IconData icon, bool isPass = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass ? !_isPasswordVisible : false, 
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          suffixIcon: isPass 
            ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54, size: 20),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ) 
            : null,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        _handleEmailLogin();
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF008BFF), Color(0xFF0055FF)]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: const Color(0xFF008BFF).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: const Center(child: Text("Login with Email", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildSocialButton({required String label, required Color color, required String iconPath, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity, height: 55,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(left: 20, child: Image.asset('assets/images/$iconPath', height: 22)),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}