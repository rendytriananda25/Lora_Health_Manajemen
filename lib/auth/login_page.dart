import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password wajib diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    User? user = await _authService.loginOrRegisterEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      context,
    );

    if (user != null && mounted) {
      await _authService.checkUserAndNavigate(context, user);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    User? user = await _authService.signInWithGoogle();
    if (user != null && mounted) {
      await _authService.checkUserAndNavigate(context, user);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleFacebookLogin() async {
    setState(() => _isLoading = true);
    User? user = await _authService.signInWithFacebook();
    if (user != null && mounted) {
      await _authService.checkUserAndNavigate(context, user);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardHeight > 0;
    final double safePaddingBottom = MediaQuery.of(context).padding.bottom;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/hitam.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black26),
            ),
          ),

          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(isKeyboardOpen ? 0.95 : 0.85),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            top: false,
            bottom: false,
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
                      bottom: isKeyboardOpen
                          ? keyboardHeight + 20
                          : safePaddingBottom,
                      top: MediaQuery.of(context).padding.top + 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Masuk untuk melanjutkan, dan nikmati petualangan olahraga bersama Lora",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                AuthTextField(
                                  controller: _emailController,
                                  hintText: "Email",
                                  prefixIcon: Icons.email_outlined,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 15),
                                AuthTextField(
                                  controller: _passwordController,
                                  hintText: "Password",
                                  prefixIcon: Icons.lock_outline,
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                ),
                                const SizedBox(height: 25),
                                AuthButton(
                                  text: "Login with Email",
                                  onTap: _handleEmailLogin,
                                  isLoading: _isLoading,
                                ),
                              ],
                            ),
                          ),
                        ),

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
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
                                      const Expanded(
                                        child: Divider(color: Colors.white24),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                        ),
                                        child: Text(
                                          "OR",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.4,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(color: Colors.white24),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  SocialLoginButton(
                                    text: "Continue With Google",
                                    iconPath: "google.png",
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    onTap: _handleGoogleLogin,
                                  ),
                                  const SizedBox(height: 12),
                                  SocialLoginButton(
                                    text: "Continue With Facebook",
                                    iconPath: "facebook.png",
                                    backgroundColor: const Color(
                                      0xFF1877F2,
                                    ).withOpacity(0.2),
                                    onTap: _handleFacebookLogin,
                                  ),
                                  const SizedBox(height: 50),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (isKeyboardOpen) const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF008BFF)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
