import 'package:flutter/material.dart';

// ✅ WIDGET 1: HEADER (Tetap)
class SettingHeader extends StatelessWidget {
  final String title;
  const SettingHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 20),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ✅ WIDGET 2: PROFILE CARD (Tetap)
class SettingProfileCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String? photoUrl;

  const SettingProfileCard({super.key, required this.fullName, required this.email, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF008BFF).withOpacity(0.2),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ WIDGET 3: SETTING ITEM (DIPERBARUI DENGAN ONTAP)
class SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap; // ✅ Parameter wajib untuk fungsi klik

  const SettingItem({
    super.key, 
    required this.icon, 
    required this.title, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), 
        borderRadius: BorderRadius.circular(18)
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        onTap: onTap, // ✅ Masukkan fungsi klik ke sini
      ),
    );
  }
}