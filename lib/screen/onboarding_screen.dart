import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lora_1/screen/login.dart';
import 'login.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data Slide Discover
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Discover Real-time Weather",
      "desc":
          "Pantau kondisi cuaca dan kualitas udara di sekitarmu secara akurat.",
      "image": "assets/images/lari1.jpg",
    },
    {
      "title": "Smart Sports Suggestion",
      "desc":
          "Dapatkan rekomendasi olahraga terbaik yang sesuai dengan kondisi alam.",
      "image": "assets/images/sepeda.jpg",
    },
    {
      "title": "Track Your Progress",
      "desc":
          "Catat setiap aktivitas olahragamu dan lihat perkembangan kesehatanmu.",
      "image": "assets/images/basket.jpg",
    },
    {
      "title": "Make Your Dream Body Come True",
      "desc": "Wujudkan tubuh impianmu.",
      "image": "assets/images/home.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE DENGAN GRADIENT DARK
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index % _onboardingData.length);
            },
            // Logic Infinite Scroll: Pakai angka sangat besar
            itemBuilder: (context, index) {
              int realIndex = index % _onboardingData.length;
              return _buildSlideContent(_onboardingData[realIndex]);
            },
          ),

          // 2. OVERLAY CONTENT (Text & Button)
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Column(
              children: [
                // Indikator Titik (Slide 1, 2, 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF9D50FF)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // TOMBOL LANJUT (Hanya muncul/berubah di slide ke-3 atau sesuai index asli)
                // Di gambar kamu, tombolnya ada di bawah "Get Started"
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      } else {
                        // Jika belum terakhir, geser ke slide berikutnya
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9D50FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1
                          ? "GET STARTED"
                          : "NEXT",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContent(Map<String, String> data) {
    return Stack(
      children: [
        // Gambar Background Full
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(data['image']!), // Pastikan path benar
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4),
                BlendMode.darken,
              ),
            ),
          ),
        ),
        // Gradient Hitam Bawah ke Atas (Agar text terbaca)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.9), Colors.transparent],
            ),
          ),
        ),
        // Text Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                data['desc']!,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 50), // Ruang untuk tombol di bawahnya
            ],
          ),
        ),
      ],
    );
  }
}
