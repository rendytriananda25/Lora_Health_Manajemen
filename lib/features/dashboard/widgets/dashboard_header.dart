import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/core/utils/app_size.dart';
import 'package:lora_1/features/gamification/rank_system.dart';
import 'package:lora_1/features/gamification/badge_translator.dart';

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
    AppSize.init(context);
    final user = FirebaseAuth.instance.currentUser;
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    ImageProvider? imageProvider;
    if (localPhotoPath != null && localPhotoPath!.isNotEmpty) {
      final file = File(localPhotoPath!);
      if (file.existsSync()) imageProvider = FileImage(file);
    }
    if (imageProvider == null && user?.photoURL != null) {
      imageProvider = NetworkImage(user!.photoURL!);
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSize.w(20),
            AppSize.statusBar + AppSize.h(10),
            AppSize.w(20),
            AppSize.h(15),
          ),
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
                  radius: AppSize.w(22),
                  backgroundColor: theme.boxColor,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Icon(
                          Icons.person,
                          size: AppSize.sp(22),
                          color: theme.textColor.withOpacity(0.38),
                        )
                      : null,
                ),
              ),
              SizedBox(width: AppSize.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LORA HEALTH MANAGEMENT",
                      style: TextStyle(
                        fontSize: AppSize.sp(9),
                        color: theme.textColor.withOpacity(0.54),
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${lang.translate('dashboard.hello')}, $userName",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSize.sp(17),
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (userRank != null)
                GestureDetector(
                  key: rankIconKey,
                  onTap: () {
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
                            fontSize: AppSize.sp(16),
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              userRank!.assetPath,
                              height: AppSize.h(100),
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: AppSize.sp(80),
                              ),
                            ),
                            SizedBox(height: AppSize.h(15)),
                            Text(
                              "EXP: $currentExp / ${RankSystem.getNextRankExp(currentExp)}",
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: AppSize.sp(15),
                              ),
                            ),
                            SizedBox(height: AppSize.h(8)),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSize.r(10)),
                              child: LinearProgressIndicator(
                                value: RankSystem.getProgressValue(currentExp),
                                backgroundColor: theme.textColor.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                minHeight: AppSize.h(10),
                              ),
                            ),
                            SizedBox(height: AppSize.h(15)),
                            Text(
                              BadgeTranslator.translateUi("Terus latihan untuk naik rank!", lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.textColor.withOpacity(0.7),
                                fontSize: AppSize.sp(13),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(BadgeTranslator.translateUi("OK", lang)),
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
                        width: AppSize.w(38),
                        height: AppSize.h(38),
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: AppSize.sp(36),
                        ),
                      ),
                      SizedBox(height: AppSize.h(2)),
                      Text(
                        BadgeTranslator.translateRank(userRank!.name, lang).toUpperCase(),
                        style: TextStyle(
                          color: theme.isDarkMode ? Colors.amber : Colors.orange[800],
                          fontSize: AppSize.sp(8),
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
