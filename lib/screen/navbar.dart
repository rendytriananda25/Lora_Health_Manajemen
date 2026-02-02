import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ WAJIB: Buat Haptic Feedback (Getar)
import 'package:lora_1/screen/map.dart';
import 'dashboard.dart';
import 'history.dart';
import 'bmi.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(), // 0: Home
    const MapPage(),       // 1: Map
    const HistoryPage(),   // 2: History
    const BMIPage(),       // 3: BMI
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // Biar background map nyatu sama navbar
      body: Stack(
        children: [
          Positioned.fill(
            child: _pages[_selectedIndex],
          ),
          _buildBottomNavbar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavbar() {
    return Positioned(
      bottom: 30, left: 20, right: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withOpacity(0.95), // Agak transparan dikit biar kaca
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 5))
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double itemWidth = constraints.maxWidth / 4;
            return Stack(
              children: [
                // 🔵 INDIKATOR BIRU (ANIMASI SLIDE MULUS)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300), // ✅ Durasi sedikit diperlambat biar elegan
                  curve: Curves.fastOutSlowIn, // ✅ GANTI INI: Slide Mulus (Tanpa Bounce)
                  left: _selectedIndex * itemWidth,
                  top: 8, bottom: 8, width: itemWidth,
                  child: Center(
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF008BFF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF008BFF).withOpacity(0.6), blurRadius: 20, spreadRadius: 2)
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 🔘 ICON-ICON NAVBAR
                Row(
                  children: [
                    _buildNavItem(Icons.home_rounded, 0, itemWidth),
                    _buildNavItem(Icons.location_on_rounded, 1, itemWidth),
                    _buildNavItem(Icons.history_rounded, 2, itemWidth),
                    _buildNavItem(Icons.monitor_weight_rounded, 3, itemWidth),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, double width) {
    bool isActive = _selectedIndex == index;
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () {
          // ✅ Tambah Getar Halus Biar Satisfying
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = index);
        },
        behavior: HitTestBehavior.translucent,
        child: Center(
          // Animasi Icon scale sedikit pas aktif
          child: AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon, 
              color: isActive ? Colors.white : Colors.white38, 
              size: 26 // Ukuran icon sedikit diperbesar
            ),
          ),
        ),
      ),
    );
  }
}