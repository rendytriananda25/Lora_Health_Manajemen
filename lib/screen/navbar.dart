import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ WAJIB: Buat Haptic Feedback (Getar)
import 'package:lora_1/features/map/map_pages.dart';
import 'package:lora_1/features/history/history_page.dart';
import 'package:lora_1/features/dashboard/dashborad.dart';
import 'bmi.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 0;

  final List<Widget?> _pages = List<Widget?>.filled(4, null);

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();
      case 1:
        return const MapPage();
      case 2:
        return const HistoryPage();
      case 3:
        return const BMIPage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    _pages[_selectedIndex] ??= _buildPage(_selectedIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // Biar background map nyatu sama navbar
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: List<Widget>.generate(
                _pages.length,
                (i) => _pages[i] ?? const SizedBox.shrink(),
              ),
            ),
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
          color: const Color(0xFF1C1C1E).withOpacity(0.95),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
          // Shadow hitam di bawah navbar tetap ada biar kelihatan melayang (depth), 
          // tapi tidak "glow"
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 5))
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double itemWidth = constraints.maxWidth / 4;
            return Stack(
              children: [
                // 🔵 INDIKATOR BIRU (CLEAN VERSION - NO GLOW)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn, 
                  left: _selectedIndex * itemWidth,
                  top: 8, bottom: 8, width: itemWidth,
                  child: Center(
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1
                            ? Colors.transparent
                            : const Color(0xFF008BFF),
                        shape: BoxShape.circle,
                        // ✅ BOXSHADOW GLOW DIHAPUS TOTAL DI SINI
                      ),
                    ),
                  ),
                ),
                
                // 🔘 ICON-ICON NAVBAR
                Row(
                  children: [
                    _buildNavItem(Icons.home_rounded, 0, itemWidth),
                    _buildRecordNavItem(itemWidth),
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
              size: 26 
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordNavItem(double width) {
    final isActive = _selectedIndex == 1;
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = 1);
        },
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFF008BFF)
                    : Colors.white38,
              ),
              alignment: Alignment.center,
              child: const Text(
                "REC",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
