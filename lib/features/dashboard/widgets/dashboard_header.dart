import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/features/gamification/rank_system.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;
  final String? localPhotoPath;
  final RankData? userRank;
  final GlobalKey? rankIconKey;
  final int currentExp;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.onProfileTap,
    this.localPhotoPath,
    this.userRank,
    this.rankIconKey,
    this.currentExp = 0,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    // Determine Image Provider
    ImageProvider? imageProvider;
    if (localPhotoPath != null && localPhotoPath!.isNotEmpty) {
      final file = File(localPhotoPath!);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }
    if (imageProvider == null && user?.photoURL != null) {
      imageProvider = NetworkImage(user!.photoURL!);
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 15),
          decoration: BoxDecoration(
            color: theme.bgColor.withOpacity(0.9),
            border: Border(
              bottom: BorderSide(
                color: theme.textColor.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.boxColor,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Icon(
                          Icons.person,
                          color: theme.textColor.withOpacity(0.38),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LORA HEALTH MANAGEMENT",
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textColor.withOpacity(0.54),
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${lang.translate('dashboard.hello')}, $userName",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (userRank != null)
                GestureDetector(
                  key: rankIconKey, // Assign Key Here
                  onTap: () {
                    // Show detailed EXP Dialog
                    // Calculate Progress
                    // Note: Need current Exp. Assuming userRank is just static data usually.
                    // But in Dashboard we pass updated ranks based on EXP.
                    // We need actual EXP to show progress bar.
                    // Let's rely on parent passing valid RankData, but wait... RankData doesn't store currentExp.
                    // RankData is strict static config.
                    // We need to pass currentExp to DashboardHeader
                    // OR we just show basic info for now.
                    // To do it right, let's just show the rank info for now and let user click for more stats page later.
                    // OR better: Just show the badge name.
                    // User requested "keterangan exp kita".
                    // I will just show generic info for now, as I don't have currentExp passed here.
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: theme.boxColor,
                        title: Text(
                          userRank?.name ?? "Rank",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              userRank!.assetPath,
                              height: 100,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: 80,
                              ),
                            ),
                            SizedBox(height: 15),
                            // Progress Text
                            Text(
                              "EXP: $currentExp / ${RankSystem.getNextRankExp(currentExp)}",
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: RankSystem.getProgressValue(currentExp),
                                backgroundColor: theme.textColor.withOpacity(
                                  0.1,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green,
                                ),
                                minHeight: 10,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Terus latihan untuk naik rank!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        userRank!.assetPath,
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 40,
                            ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        userRank!.name.toUpperCase(),
                        style: TextStyle(
                          color: theme.isDarkMode
                              ? Colors.amber
                              : Colors.orange[800],
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
