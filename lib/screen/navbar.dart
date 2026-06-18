import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/features/workout/presentation/pages/workout_page.dart';
import 'package:lora_1/features/history/presentation/pages/history_page.dart';
import 'package:lora_1/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:lora_1/features/bmi/presentation/pages/bmi_page.dart';

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
        return const WorkoutPage();
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
      backgroundColor: themeProvider.bgColor,
      extendBody: true,
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
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

                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    left:
                        _selectedIndex * itemWidth +
                        (itemWidth / 2 -
                            25),
                    top: 10,
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

                  Row(
                    children: [
                      _buildNavItem(Icons.home_rounded, 0, itemWidth, theme),
                      _buildNavItem(
                        Icons.fiber_manual_record_rounded,
                        1,
                        itemWidth,
                        theme,
                        isRec: true,
                      ),
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
                  scale: isActive ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
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
