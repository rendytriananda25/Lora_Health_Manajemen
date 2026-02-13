import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_database/firebase_database.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false; 
  
  late AnimationController _controller;

  // --- LOGIKA UTAMA REGISTER DENGAN URL DATABASE SINGAPORE ---
  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      _showSnackBar("Semua kolom wajib diisi!", Colors.orange);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Password tidak sama!", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. BUAT AKUN DI AUTH
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential.user != null) {
        String uid = credential.user!.uid;
        
        // 2. KUNCI UTAMA: Masukkan URL Database kamu di sini agar tidak 'null'
        // Salin URL dari image_adf6b4.png
        String dbUrl = "https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app";
        
        DatabaseReference ref = FirebaseDatabase.instanceFor(
          app: FirebaseAuth.instance.app, 
          databaseURL: dbUrl
        ).ref("users/$uid");

        await ref.set({
          "full_name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "role": "user",
          "created_at": ServerValue.timestamp,
        });

        print("DEBUG: Data berhasil masuk ke Server Singapore!");
      }

      if (mounted) {
        setState(() => _isLoading = false);

        // Tampilkan dialog sukses dengan efek glass
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dialog(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60),
                      const SizedBox(height: 20),
                      const Text(
                        "Registrasi Berhasil",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Anda akan dialihkan ke halaman login...",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        // Tunggu 3 detik, lalu kembali ke halaman Login
        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          // Tutup dialog dan semua halaman di atas login screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar(e.message ?? "Gagal Mendaftar", Colors.red);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar("Koneksi Error: Periksa URL Database!", Colors.red);
      print("DEBUG ERROR: $e");
    }
  }

  // --- SISANYA TETAP SAMA (UI DESIGN) ---
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: color, content: Text(message), behavior: SnackBarBehavior.floating)
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF000000)],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (ctx, child) => Positioned(
              top: -60 + (_controller.value * 40), right: -60 + (_controller.value * 20),
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.deepPurpleAccent.withOpacity(0.3), boxShadow: [BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.3), blurRadius: 100)]),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Hero(
                    tag: 'app-logo',
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.2))),
                      child: const Icon(Icons.bolt_rounded, size: 50, color: Color(0xFF008BFF)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.1))),
                        child: Column(
                          children: [
                            _buildGlassTextField(controller: _nameController, hint: "Full Name", icon: Icons.person_outline),
                            const SizedBox(height: 16),
                            _buildGlassTextField(controller: _emailController, hint: "Email Address", icon: Icons.email_outlined),
                            const SizedBox(height: 16),
                            _buildGlassTextField(
                              controller: _passwordController, hint: "Password", icon: Icons.lock_outline,
                              isPassword: true, isVisible: _isPasswordVisible,
                              onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                            const SizedBox(height: 16),
                            _buildGlassTextField(
                              controller: _confirmPasswordController, hint: "Confirm Password", icon: Icons.lock_reset,
                              isPassword: true, isVisible: _isConfirmPasswordVisible,
                              onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity, height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF008BFF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: _isLoading 
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("CREATE ACCOUNT", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ", style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text("Login", style: TextStyle(color: Color(0xFF008BFF), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, bool isVisible = false, VoidCallback? onVisibilityToggle}) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: TextField(
        controller: controller, obscureText: isPassword && !isVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF008BFF), size: 20),
          suffixIcon: isPassword ? IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white24, size: 18), onPressed: onVisibilityToggle) : null,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}