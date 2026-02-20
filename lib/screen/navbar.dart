import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/features/map/map_pages.dart';
import 'package:lora_1/features/history/history_page.dart';
import 'package:lora_1/features/dashboard/dashboard.dart';
import 'package:lora_1/features/bmi/bmi_page.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.bgColor, // Adaptive Background
      extendBody: true, // Allow body to extend behind navbar
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

          // Custom Glassmorphism Navbar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildGlassNavbar(themeProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassNavbar(ThemeProvider theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur Effect
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            // Glass Color: Semi-transparent based on theme
            color: (theme.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white)
                .withOpacity(0.75),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: (theme.isDarkMode ? Colors.white : Colors.black)
                  .withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double itemWidth = constraints.maxWidth / 4;
              return Stack(
                children: [
                  // 🔵 MOVING INDICATOR (Blue Circle)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    left:
                        _selectedIndex * itemWidth +
                        (itemWidth / 2 -
                            25), // Center it: (ItemWidth/2) - (CircleWidth/2)
                    top: 10, // (70 - 50) / 2 = 10 vertical centering
                    height: 50,
                    width: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF008BFF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66008BFF),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🔘 ICONS ROW
                  Row(
                    children: [
                      _buildNavItem(Icons.home_rounded, 0, itemWidth, theme),
                      _buildNavItem(
                        Icons.fiber_manual_record_rounded,
                        1,
                        itemWidth,
                        theme,
                        isRec: true,
                      ), // Changed icon to verify it's not the REC text circle
                      _buildNavItem(Icons.history_rounded, 2, itemWidth, theme),
                      _buildNavItem(
                        Icons.monitor_weight_rounded,
                        3,
                        itemWidth,
                        theme,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    int index,
    double width,
    ThemeProvider theme, {
    bool isRec = false,
  }) {
    bool isActive = _selectedIndex == index;

    // Logic for REC button special appearance?
    // User's previous code had a specific _buildRecordNavItem with "REC" text.
    // Let's preserve the Text "REC" if it's index 1, or use Icon.
    // Screenshot shows "REC" text inside a circle.

    return SizedBox(
      width: width,
      height: 70,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = index);
        },
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: isRec
              ? _buildRecContent(isActive, theme)
              : AnimatedScale(
                  scale: isActive ? 1.0 : 0.9, // Slight zoom effect
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    // Active: White (on blue circle). Inactive: Theme text color (faded)
                    color: isActive
                        ? Colors.white
                        : theme.textColor.withOpacity(0.5),
                    size: 28,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRecContent(bool isActive, ThemeProvider theme) {
    // If active: White text on Blue circle (Background circle handled by AnimatedPositioned)
    // If inactive: "REC" text without circle? Or grey circle?
    // Previous implementation had a grey circle for inactive.
    // But now we have a moving blue indicator.
    // If we use the moving blue indicator for ALL items, then:
    // When Index 1 is active, Blue Circle is behind it. Text should be white.
    // When Index 1 is inactive, No Circle behind it. Text should be Grey.

    return AnimatedScale(
      scale: isActive ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 200),
      child: Text(
        "REC",
        style: TextStyle(
          color: isActive ? Colors.white : theme.textColor.withOpacity(0.5),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
