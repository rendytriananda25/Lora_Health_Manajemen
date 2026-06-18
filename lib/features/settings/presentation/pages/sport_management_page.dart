import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/setup/data/setup_constants.dart';
import '../widgets/setting_widgets.dart';

class SportManagementPage extends StatefulWidget {
  const SportManagementPage({super.key});

  @override
  State<SportManagementPage> createState() => _SportManagementPageState();
}

class _SportManagementPageState extends State<SportManagementPage> {
  final Set<int> _selectedIndices = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSports();
  }

  Future<void> _loadCurrentSports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref("users/${user.uid}/favorite_sports")
          .get();

      if (snapshot.exists) {
        final List<dynamic> favSports = snapshot.value as List<dynamic>;
        for (int i = 0; i < SetupConstants.sports.length; i++) {
          final sportName = SetupConstants.sports[i]['name'];
          if (favSports.contains(sportName)) {
            _selectedIndices.add(i);
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading sports: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSports() async {
    if (_selectedIndices.isEmpty) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('sportManagement.minOneRequired')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final selectedNames = _selectedIndices
          .map((i) => SetupConstants.sports[i]['name'] ?? "Unknown")
          .toList();

      final Map<String, bool> sportsForMap = {};
      for (final name in selectedNames) {
        var key = name.toUpperCase();
        if (key == "RUNNING") key = "LARI";
        if (key == "CYCLING") key = "SEPEDA";
        if (key == "FOOTBALL") key = "BOLA";
        if (key == "BASKETBALL") key = "BASKET";
        sportsForMap[key] = true;
      }

      await FirebaseDatabase.instance.ref("users/${user.uid}").update({
        "sports": sportsForMap,
        "favorite_sports": selectedNames,
      });

      if (mounted) {
        final lang = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('sportManagement.saved')),
            backgroundColor: const Color(0xFF008BFF),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error saving sports: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            SettingHeader(
              title: lang.translate('sportManagement.title'),
              isDarkMode: theme.isDarkMode,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                lang.translate('sportManagement.subtitle'),
                style: TextStyle(
                  color: theme.subTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF008BFF)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: SetupConstants.sports.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemBuilder: (context, index) {
                    final sport = SetupConstants.sports[index];
                    final isSelected = _selectedIndices.contains(index);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIndices.remove(index);
                          } else {
                            _selectedIndices.add(index);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: theme.boxColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF008BFF) : theme.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sport['name']!,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? const Color(0xFF008BFF) : theme.subTextColor,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSports,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008BFF),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          lang.translate('sportManagement.saveChanges'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
