import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lora_1/screen/navbar.dart';
import 'dashboard.dart';

class SportsSelectionPage extends StatefulWidget {
  const SportsSelectionPage({super.key});

  @override
  State<SportsSelectionPage> createState() => _SportsSelectionPageState();
}

class _SportsSelectionPageState extends State<SportsSelectionPage> {
  final List<Map<String, String>> _sports = [
    {"name": "Basketball", "img": "assets/images/basket2.jpg"},
    {"name": "Running", "img": "assets/images/mlayu.jpg"},
    {"name": "Football", "img": "assets/images/bal.jpg"},
    {"name": "Home Workout", "img": "assets/images/wo.png"},
    {"name": "Cycling", "img": "assets/images/pedah.jpg"},
  ];

  final Set<int> _selectedIndices = {};
  bool _isSaving = false;

  Future<void> _handleStart() async {
    if (_selectedIndices.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<String> selected = _selectedIndices
            .map((i) => _sports[i]['name'] ?? "Unknown")
            .toList();

        await FirebaseDatabase.instance.ref("users/${user.uid}").update({
          "favorite_sports": selected,
          "onboarding_completed": true,
        });

        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const Navbar())
          );
        }
      }
    } catch (e) {
      debugPrint("Error save: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pilih Olahraga",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Pilih jenis olahraga yang kamu suka",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: ListView.builder(
                  itemCount: _sports.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    bool isSelected = _selectedIndices.contains(index);
                    String sportName = _sports[index]['name'] ?? "Sport";
                    String imgPath = _sports[index]['img'] ?? "";

                    return GestureDetector(
                      onTap: () => setState(
                        () => isSelected
                            ? _selectedIndices.remove(index)
                            : _selectedIndices.add(index),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        height:
                            150, // Tinggi sedikit dinaikkan agar gambar lebih lega
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: const Color(
                            0xFF1E293B,
                          ).withOpacity(0.5), // Base color card
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: isSelected
                                ? [
                                    const Color(0xFF008BFF).withOpacity(0.4),
                                    Colors.black,
                                  ]
                                : [
                                    const Color(0xFF1E293B).withOpacity(0.2),
                                    Colors.black,
                                  ],
                          ),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white10,
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Biar gambar ikut melengkung di pojok
                          child: Stack(
                            children: [
                              Row(
                                children: [
                                  // ✅ BAGIAN GAMBAR EDGE-TO-EDGE + GRADASI
                                  ShaderMask(
                                    shaderCallback: (rect) {
                                      return const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        // Gradasi: Gambar solid di kiri (1.0), pudar di kanan (0.0)
                                        colors: [
                                          Colors.black,
                                          Colors.transparent,
                                        ],
                                      ).createShader(
                                        Rect.fromLTRB(
                                          0,
                                          0,
                                          rect.width,
                                          rect.height,
                                        ),
                                      );
                                    },
                                    blendMode: BlendMode
                                        .dstIn, // Efek fading ke arah kanan
                                    child: SizedBox(
                                      width: 140, // Lebar gambar
                                      height: double.infinity,
                                      child: imgPath.isNotEmpty
                                          ? Image.asset(
                                              imgPath,
                                              fit: BoxFit
                                                  .cover, // Mentok atas bawah kiri
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.sports_rounded,
                                                    color: Colors.white24,
                                                    size: 40,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.sports_rounded,
                                              color: Colors.white24,
                                              size: 40,
                                            ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // ✅ TEXT OLAHRAGA
                                  Expanded(
                                    child: Text(
                                      sportName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // ✅ CHECKMARK
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 20),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008BFF),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF008BFF).withOpacity(0.5),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "MULAI DASHBOARD",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
