import 'dart:io';
import 'package:flutter/material.dart';

class SettingHeader extends StatelessWidget {
  final String title;
  final bool isDarkMode;

  const SettingHeader({super.key, required this.title, this.isDarkMode = true});

  @override
  Widget build(BuildContext context) {
    final color = isDarkMode ? Colors.white : Colors.black;
    final btnBg = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, color: color, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: btnBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingProfileCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String? photoUrl;
  final String? localPhotoPath;
  final VoidCallback? onPhotoTap;
  final bool isDarkMode;

  const SettingProfileCard({
    super.key,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.localPhotoPath,
    this.onPhotoTap,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final txt = isDarkMode ? Colors.white : Colors.black87;
    final subTxt = isDarkMode ? Colors.white54 : Colors.black54;
    final border = isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black12;

    ImageProvider? imageProvider;
    if (localPhotoPath != null && localPhotoPath!.isNotEmpty) {
      final file = File(localPhotoPath!);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }

    if (imageProvider == null && photoUrl != null && photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: border),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          if (onPhotoTap != null)
            GestureDetector(
              onTap: onPhotoTap,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFF008BFF).withOpacity(0.2),
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF008BFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF008BFF).withOpacity(0.2),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    color: txt,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(email, style: TextStyle(color: subTxt, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDarkMode;

  const SettingItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final txt = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        elevation: isDarkMode ? 0 : 2,
        shadowColor: Colors.black12,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF5EEAD4).withOpacity(0.15),
          highlightColor: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: txt, fontSize: 15),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.white24 : Colors.black26,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
