import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'badges.dart';
import 'badge_service.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  List<String> unlockedIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final ids = await BadgeService.getUnlockedBadges();
    if (mounted) {
      setState(() {
        unlockedIds = ids;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        title: Text(
          "Pencapaian & Badges",
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.textColor),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF008BFF)),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.75, // Taller cards
              ),
              itemCount: BadgeList.allBadges.length,
              itemBuilder: (context, index) {
                final badge = BadgeList.allBadges[index];
                final isUnlocked = unlockedIds.contains(badge.id);
                return _buildBadgeCard(badge, isUnlocked, theme);
              },
            ),
    );
  }

  Widget _buildBadgeCard(
    BadgeItem badge,
    bool isUnlocked,
    ThemeProvider theme,
  ) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: theme.boxColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isUnlocked ? badge.color : Colors.transparent,
                width: 2,
              ),
            ),
            title: Text(
              badge.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? badge.color.withOpacity(0.1)
                        : theme.textColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    badge.icon,
                    size: 50,
                    color: isUnlocked
                        ? badge.color
                        : theme.textColor.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  isUnlocked ? "TERBUKA! 🎉" : "TERKUNCI 🔒",
                  style: TextStyle(
                    color: isUnlocked ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textColor.withOpacity(0.8)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Tutup", style: TextStyle(color: theme.textColor)),
              ),
            ],
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: theme.boxColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked
                ? badge.color.withOpacity(0.5)
                : theme.textColor.withOpacity(0.1),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: badge.color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? badge.color.withOpacity(0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    badge.icon,
                    size: 32,
                    color: isUnlocked
                        ? badge.color
                        : theme.textColor.withOpacity(0.1),
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(
                      Icons.lock,
                      size: 14,
                      color: theme.textColor.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isUnlocked
                      ? theme.textColor
                      : theme.textColor.withOpacity(0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BadgeUnlockDialog extends StatelessWidget {
  final List<BadgeItem> badges;
  const BadgeUnlockDialog({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.boxColor, // Adaptive
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 20),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "BADGE UNLOCKED! 🏆",
                  style: TextStyle(
                    color: theme.textColor, // Adaptive
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: PageView.builder(
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      final b = badges[index];
                      return Column(
                        children: [
                          Icon(b.icon, size: 80, color: b.color),
                          const SizedBox(height: 10),
                          Text(
                            b.title,
                            style: TextStyle(
                              color: theme.textColor, // Adaptive
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            b.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.textColor.withOpacity(
                                0.7,
                              ), // Adaptive
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  child: const Text(
                    "KEREN!",
                    style: TextStyle(
                      color:
                          Colors.black, // Tetap hitam agar kontras dengan Amber
                      fontWeight: FontWeight.bold,
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
}
