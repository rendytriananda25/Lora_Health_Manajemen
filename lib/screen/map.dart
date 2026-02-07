import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _isRecording = false;
  bool _showControlPanel = false;
  bool _showSportMenu = false;
  bool _isSaving = false;
  String _selectedSport = "LARI";
  
  // ✅ Data Cuaca
  String _currentTemp = "--";
  int _tempValue = 0; 
  final String _apiKey = "d0fa6ab4f8080a9265e6a1bdf035fad0"; 

  // ✅ VARIABEL GUIDED WORKOUT (TETAP AMAN)
  int _currentExerciseIndex = 0;
  List<Map<String, dynamic>> _workoutSessionData = [];
  final PageController _pageController = PageController(viewportFraction: 0.85);

  final List<Map<String, dynamic>> _exercises = [
    {"name": "Jumping Jack", "target": "1 Menit", "type": "time", "icon": "🤸"},
    {"name": "Push-up", "target": "15 Reps x 3 Set", "type": "reps", "icon": "💪"},
    {"name": "Squat", "target": "20 Reps x 3 Set", "type": "reps", "icon": "🏋️"},
    {"name": "Plank", "target": "60 Detik", "type": "time", "icon": "🧱"},
    {"name": "Mountain Climber", "target": "45 Detik", "type": "time", "icon": "⛰️"},
  ];

  List<LatLng> _routePoints = [];
  double _totalDistance = 0.0;
  int _seconds = 0;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  // Default Malang (Sebagai fallback)
  LatLng _currentLocation = const LatLng(-7.9509, 112.6074); 
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  // ✅ 1. UPDATE: INISIALISASI DENGAN AKURASI 'BEST'
  Future<void> _initMap() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Pakai 'Best' agar HP dipaksa cari sinyal terkuat di Kab. Malang
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      
      if (mounted) {
        setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
        _mapController.move(_currentLocation, 16.0); // Langsung zoom in
        _fetchInitialWeather(position);
      }
    } catch (e) { 
      debugPrint("Gagal init lokasi: $e");
      _fetchInitialWeather(null); 
    }
  }

  // ✅ 2. FITUR BARU: TOMBOL PAKSA POSISI (RECENTER)
  Future<void> _recenterMap() async {
    HapticFeedback.mediumImpact();
    try {
      // Ambil posisi real-time paling akurat
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Animasi kamera pindah ke user
      _mapController.move(_currentLocation, 17.0); 
    } catch (e) {
      debugPrint("Gagal recenter: $e");
    }
  }

  Future<void> _fetchInitialWeather(Position? pos) async {
    final lat = pos?.latitude ?? _currentLocation.latitude;
    final lon = pos?.longitude ?? _currentLocation.longitude;
    final url = "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric";
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _tempValue = data['main']['temp'].toInt();
            _currentTemp = _tempValue.toString();
          });
        }
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _startTrackingManual() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
      _seconds = 0;
      _routePoints.clear();
      _totalDistance = 0.0;
      _currentExerciseIndex = 0;
      _workoutSessionData.clear();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) { if (mounted) setState(() => _seconds++); });

    if (isMapSport) {
      // ✅ UPDATE: TRACKING JUGA PAKAI AKURASI 'BEST'
      LocationSettings settings = AndroidSettings(
        accuracy: LocationAccuracy.best, 
        distanceFilter: 3, // Lebih sensitif (3 meter gerak langsung catat)
        forceLocationManager: true, 
      );
      
      _positionStream = Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
        if (!mounted) return;
        LatLng newPoint = LatLng(pos.latitude, pos.longitude);
        setState(() {
          if (_routePoints.isNotEmpty) {
            _totalDistance += Geolocator.distanceBetween(_routePoints.last.latitude, _routePoints.last.longitude, newPoint.latitude, newPoint.longitude) / 1000;
          }
          _routePoints.add(newPoint);
          _currentLocation = newPoint;
        });
        _mapController.move(newPoint, 17); // Auto follow user
      });
    }
  }

  void _completeExercise(String name, String result) {
    HapticFeedback.lightImpact();
    _workoutSessionData.add({"name": name, "result": result});
    if (_currentExerciseIndex < _exercises.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _stopTrackingManual();
    }
  }

  Future<void> _stopTrackingManual() async {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    _positionStream?.cancel();
    setState(() => _isSaving = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dbRef = FirebaseDatabase.instance.ref("users/${user.uid}/history");
        
        String detailText = "";
        if (_selectedSport == "HOME WORKOUT") {
          if (_workoutSessionData.isEmpty) {
            detailText = "Tidak ada gerakan diselesaikan";
          } else {
            detailText = _workoutSessionData.map((e) => "${e['name']}: ${e['result']}").join(", ");
          }
        }

        await dbRef.push().set({
          'activity': _selectedSport,
          'duration_sec': _seconds,
          'calories': (_seconds * 0.15).toInt(),
          'distance_km': _totalDistance,
          'time': DateTime.now().toIso8601String(),
          'temp_at_start': _currentTemp,
          'details': detailText,
        });
        if (mounted) _showSyncedSuccessDialog();
      }
    } catch (e) { debugPrint(e.toString()); }
    setState(() { _isRecording = false; _isSaving = false; _showControlPanel = false; });
  }

  // --- UI WIDGETS (TIDAK BERUBAH) ---
  Widget _buildTimerBackground() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          if (_isRecording && _selectedSport == "HOME WORKOUT")
            Text(_formatTime(_seconds), style: const TextStyle(color: Colors.white54, fontSize: 30, fontFamily: 'monospace', fontWeight: FontWeight.bold))
          else ...[
             const SizedBox(height: 40),
             Icon(
              _selectedSport == "BASKET" ? Icons.sports_basketball : 
              _selectedSport == "BOLA" ? Icons.sports_soccer : Icons.fitness_center,
              size: 50, color: const Color(0xFF5EEAD4).withOpacity(0.5),
            ),
            const SizedBox(height: 10),
            Text(_formatTime(_seconds), style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            const Text("SESI AKTIF", style: TextStyle(color: Colors.white38, letterSpacing: 4, fontSize: 10)),
          ],
          
          const SizedBox(height: 20),

          if (_selectedSport == "HOME WORKOUT" && _isRecording)
            SizedBox(
              height: 420, 
              child: PageView.builder(
                controller: _pageController,
                itemCount: _exercises.length,
                onPageChanged: (index) => setState(() => _currentExerciseIndex = index),
                itemBuilder: (context, index) {
                  return _buildExerciseCard(_exercises[index], index == _currentExerciseIndex);
                },
              ),
            )
          else 
            GestureDetector(
              onTap: _isRecording ? _stopTrackingManual : _startTrackingManual,
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                height: 50, width: 200,
                decoration: BoxDecoration(color: _isRecording ? Colors.redAccent : Colors.white, borderRadius: BorderRadius.circular(25)),
                child: Center(child: Text(_isRecording ? "SELESAI" : "MULAI SESI", style: TextStyle(color: _isRecording ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
              ),
            ),

          if (_selectedSport == "HOME WORKOUT" && _isRecording)
             Padding(
               padding: const EdgeInsets.only(top: 20),
               child: TextButton(onPressed: _stopTrackingManual, child: const Text("AKHIRI LATIHAN SEKARANG", style: TextStyle(color: Colors.redAccent))),
             )
          else if (!_isRecording) 
            const Spacer(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> data, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E1E1E) : Colors.black, 
        borderRadius: BorderRadius.circular(30),
        border: isActive ? Border.all(color: const Color(0xFF5EEAD4), width: 1.5) : Border.all(color: Colors.white10),
        boxShadow: isActive ? [BoxShadow(color: const Color(0xFF5EEAD4).withOpacity(0.2), blurRadius: 15)] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data['icon'], style: const TextStyle(fontSize: 50)),
          const SizedBox(height: 15),
          Text(data['name'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(data['target'], style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const Spacer(),
          if (isActive) ...[
            if (data['type'] == 'reps')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton("1 SET", () => _completeExercise(data['name'], "1 Set"), width: 60),
                  const SizedBox(width: 8),
                  _buildActionButton("2 SET", () => _completeExercise(data['name'], "2 Set"), width: 60),
                  const SizedBox(width: 8),
                  _buildActionButton("DONE", () => _completeExercise(data['name'], data['target']), isPrimary: true, width: 70),
                ],
              )
            else
              _buildActionButton("SELESAI (${data['target']})", () => _completeExercise(data['name'], data['target']), isPrimary: true, width: 180),
            const SizedBox(height: 15),
            const Text("Swipe kiri untuk skip", style: TextStyle(color: Colors.white24, fontSize: 10)),
          ] else 
            const Icon(Icons.lock_clock, color: Colors.white24, size: 30),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap, {bool isPrimary = false, double width = 80}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isPrimary ? const Color(0xFF5EEAD4) : Colors.white10, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: TextStyle(color: isPrimary ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
      ),
    );
  }

  bool get isMapSport => (_selectedSport == "LARI" || _selectedSport == "SEPEDA");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 1: MAP ATAU TIMER
          if (isMapSport) 
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation, 
                initialZoom: 15,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                retinaMode: true,
                ),
                PolylineLayer(polylines: [Polyline(points: _routePoints, color: Colors.blueAccent, strokeWidth: 4)]),
                MarkerLayer(markers: [
                  Marker(
                    point: _currentLocation,
                    width: 40, height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)
                      ),
                      child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                    ),
                  )
                ]),
              ],
            )
          else 
            _buildTimerBackground(),

          // LAYER 2: TOMBOL MENU (KIRI ATAS - TETAP)
          Positioned(
            top: 50, left: 20,
            child: GestureDetector(
              onTap: () => setState(() => _showSportMenu = !_showSportMenu),
              child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: Icon(_showSportMenu ? Icons.close : Icons.menu, color: Colors.white)),
            ),
          ),

          // ✅ LAYER 3: TOMBOL RECENTER (KANAN ATAS - BARU)
          // Hanya muncul jika sedang mode MAP (Lari/Sepeda)
          if (isMapSport)
            Positioned(
              top: 50, right: 20,
              child: GestureDetector(
                onTap: _recenterMap, // Panggil fungsi recenter
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.5)) // Warna Neon Tosca
                  ),
                  child: const Icon(Icons.my_location, color: Color(0xFF5EEAD4)), // Ikon Target
                ),
              ),
            ),

          if (_showSportMenu) _buildSportSelectionMenu(),
          if (_showControlPanel && isMapSport) _buildGlassControlPanel(),
          if (_isSaving) const Center(child: CircularProgressIndicator(color: Color(0xFF5EEAD4))),
        ],
      ),
    );
  }

  Widget _buildSportSelectionMenu() {
    return Positioned(
      top: 110, left: 20,
      child: Container(
        width: 240, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white12)),
        child: Column(
          children: [
            _buildMenuItem(Icons.directions_run, "LARI"),
            _buildMenuItem(Icons.directions_bike, "SEPEDA"),
            const Divider(color: Colors.white12),
            _buildMenuItem(Icons.fitness_center, "HOME WORKOUT"),
            _buildMenuItem(Icons.sports_basketball, "BASKET"),
            _buildMenuItem(Icons.sports_soccer, "BOLA"),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      onTap: () => setState(() { _selectedSport = label; _showSportMenu = false; _showControlPanel = true; _isRecording = false; _seconds = 0; }),
    );
  }

  Widget _buildGlassControlPanel() {
    return Positioned(
      bottom: 130, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_selectedSport, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("$_currentTemp°C", style: const TextStyle(color: Colors.white))]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildBigStat("${_totalDistance.toStringAsFixed(2)}", "KM"),
              _buildBigStat(_formatTime(_seconds), "TIME"),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _isRecording ? Colors.red : Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: _isRecording ? _stopTrackingManual : _startTrackingManual,
              child: Text(_isRecording ? "STOP" : "START", style: TextStyle(color: _isRecording ? Colors.white : Colors.black)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBigStat(String v, String u) => Column(children: [Text(v, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(u, style: const TextStyle(color: Colors.white54, fontSize: 10))]);
  
  void _showSyncedSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Icon(Icons.check_circle, color: Color(0xFF5EEAD4), size: 50),
        content: const Text("Data latihanmu berhasil disimpan.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }
}