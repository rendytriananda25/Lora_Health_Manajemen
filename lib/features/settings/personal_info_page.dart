import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'widgets/setting_widgets.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();

  // Data Kesehatan
  String height = "--", weight = "--", gender = "--", age = "--";

  @override
  void initState() {
    super.initState();
    _fetchUserHealthData();
  }

  // ✅ AMBIL DATA KESEHATAN
  Future<void> _fetchUserHealthData() async {
    if (user != null) {
      final ref = FirebaseDatabase.instance.ref(
        "users/${user!.uid}/health_data",
      );
      final snapshot = await ref.get();
      if (snapshot.exists && mounted) {
        final data = snapshot.value as Map;
        setState(() {
          height = data['height']?.toString() ?? "--";
          weight = data['weight']?.toString() ?? "--";
          gender = data['gender']?.toString() ?? "--";
          age = data['age']?.toString() ?? "--";
        });
      }
    }
  }

  // ✅ FUNGSI EDIT NAMA KE FIREBASE
  Future<void> _updateName() async {
    if (_nameController.text.isNotEmpty && user != null) {
      final newName = _nameController.text.trim();
      await FirebaseDatabase.instance.ref("users/${user!.uid}").update({
        "username": newName,
        "full_name": newName,
      });
      await user!.updateDisplayName(newName);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userRef = FirebaseDatabase.instance.ref(
      "users/${user!.uid}/username",
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SettingHeader(title: lang.translate('personalInfo.title')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ✅ STREAM NAMA (Live Update ke Seluruh Menu)
                    StreamBuilder(
                      stream: userRef.onValue,
                      builder: (context, snapshot) {
                        String name =
                            snapshot.hasData &&
                                snapshot.data!.snapshot.value != null
                            ? snapshot.data!.snapshot.value.toString()
                            : (user?.displayName ?? "User");
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFF1C1C1E),
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null,
                              child: user?.photoURL == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white24,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // ✅ TOMBOL EDIT NAMA
                            TextButton.icon(
                              onPressed: () => _showEditNameDialog(name, lang),
                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Color(0xFF008BFF),
                              ),
                              label: Text(
                                lang.translate('settings.editName'),
                                style: const TextStyle(
                                  color: Color(0xFF008BFF),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // ✅ DATA TINGGI & BERAT
                    Row(
                      children: [
                        _buildHealthBox(
                          lang.translate('personalInfo.height'),
                          height,
                          "cm",
                          Icons.height,
                          Colors.blueAccent,
                        ),
                        const SizedBox(width: 15),
                        _buildHealthBox(
                          lang.translate('personalInfo.weight'),
                          weight,
                          "kg",
                          Icons.monitor_weight_outlined,
                          Colors.orangeAccent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ✅ INFO LAINNYA
                    _buildInfoTile(
                      lang.translate('personalInfo.gender'),
                      gender,
                    ),
                    _buildInfoTile(
                      lang.translate('personalInfo.age'),
                      "$age ${lang.translate('personalInfo.years')}",
                    ),
                    _buildInfoTile(
                      lang.translate('personalInfo.location'),
                      "Malang, Indonesia",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ POPUP EDIT NAMA
  void _showEditNameDialog(String currentName, LanguageProvider lang) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          lang.translate('personalInfo.changeName'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: lang.translate('personalInfo.enterNewName'),
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.translate('personalInfo.cancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: _updateName,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008BFF),
            ),
            child: Text(
              lang.translate('personalInfo.save'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBox(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 15),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
