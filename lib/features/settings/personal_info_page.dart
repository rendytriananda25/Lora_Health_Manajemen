import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart'; // ✅ Import ThemeProvider
import 'widgets/setting_widgets.dart';
import 'package:file_picker/file_picker.dart'; // ✅ Import File Picker
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Import SharedPrefs

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
  String? _localPhotoPath; // ✅ Local Photo Path

  @override
  void initState() {
    super.initState();
    _fetchUserHealthData();
    _loadLocalPhoto();
  }

  Future<void> _loadLocalPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localPhotoPath = prefs.getString('user_local_photo');
    });
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

  // ✅ GANTI FOTO LOKAL
  Future<void> _pickAndSaveImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;

        // Save to SharedPrefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_local_photo', path);

        setState(() {
          _localPhotoPath = path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("📸 Foto Profil Diperbarui (Lokal)"),
              backgroundColor: Color(0xFF008BFF),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error Pick Image: $e");
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
    final theme = Provider.of<ThemeProvider>(context); // ✅ Global Theme
    final userRef = FirebaseDatabase.instance.ref(
      "users/${user!.uid}/username",
    );

    // Determine Image Provider
    ImageProvider? imageProvider;
    if (_localPhotoPath != null && _localPhotoPath!.isNotEmpty) {
      final file = File(_localPhotoPath!);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }
    if (imageProvider == null && user?.photoURL != null) {
      imageProvider = NetworkImage(user!.photoURL!);
    }

    return Scaffold(
      backgroundColor: theme.bgColor, // ✅ Adaptive Background
      body: SafeArea(
        child: Column(
          children: [
            SettingHeader(
              title: lang.translate('personalInfo.title'),
              isDarkMode: theme.isDarkMode, // ✅ Pass Theme
            ),
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
                            GestureDetector(
                              onTap: _pickAndSaveImage, // ✅ TAP TO EDIT PHOTO
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor:
                                        theme.boxColor, // ✅ Adaptive
                                    backgroundImage: imageProvider,
                                    child: imageProvider == null
                                        ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: theme.subTextColor,
                                          )
                                        : null,
                                  ),
                                  // Camera Icon Overlay
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF008BFF),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              name,
                              style: TextStyle(
                                color: theme.textColor, // ✅ Adaptive
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // ✅ TOMBOL EDIT NAMA
                            TextButton.icon(
                              onPressed: () =>
                                  _showEditNameDialog(name, lang, theme),
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
                        Expanded(
                          child: _buildHealthBox(
                            lang.translate('personalInfo.height'),
                            height,
                            "cm",
                            Icons.height,
                            Colors.blueAccent,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildHealthBox(
                            lang.translate('personalInfo.weight'),
                            weight,
                            "kg",
                            Icons.monitor_weight_outlined,
                            Colors.orangeAccent,
                            theme,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ✅ INFO LAINNYA
                    _buildInfoTile(
                      lang.translate('personalInfo.gender'),
                      gender,
                      theme,
                    ),
                    _buildInfoTile(
                      lang.translate('personalInfo.age'),
                      "$age ${lang.translate('personalInfo.years')}",
                      theme,
                    ),
                    _buildInfoTile(
                      lang.translate('personalInfo.location'),
                      "Malang, Indonesia",
                      theme,
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
  void _showEditNameDialog(
    String currentName,
    LanguageProvider lang,
    ThemeProvider theme,
  ) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.boxColor, // ✅ Adaptive
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          lang.translate('personalInfo.changeName'),
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _nameController,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            hintText: lang.translate('personalInfo.enterNewName'),
            hintStyle: TextStyle(color: theme.subTextColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.borderColor),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF008BFF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.translate('personalInfo.cancel'),
              style: TextStyle(color: theme.subTextColor),
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
    ThemeProvider theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.boxColor, // ✅ Adaptive
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 15),
          Text(
            label,
            style: TextStyle(color: theme.subTextColor, fontSize: 12),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(color: theme.subTextColor, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, ThemeProvider theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.boxColor, // ✅ Adaptive
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: theme.subTextColor, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
