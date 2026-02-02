import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart'; 
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
  
  // LOGIC CUACA ASLI
  String _currentTemp = "--";
  final String _apiKey = "d0fa6ab4f8080a9265e6a1bdf035fad0"; 

  List<LatLng> _routePoints = [];
  double _totalDistance = 0.0;
  int _seconds = 0;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  LatLng _currentLocation = const LatLng(-6.8898, 109.6713); 
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchInitialWeather();
  }

  Future<void> _fetchInitialWeather() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      final url = "https://api.openweathermap.org/data/2.5/weather?lat=${pos.latitude}&lon=${pos.longitude}&appid=$_apiKey&units=metric";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) setState(() => _currentTemp = data['main']['temp'].toInt().toString());
      }
    } catch (e) {
      debugPrint("Gagal ambil cuaca: $e");
    }
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // --- LOGIC ANTI-HANTU & RINGAN ---
  Future<void> _startTrackingManual() async {
    HapticFeedback.mediumImpact(); 
    SystemSound.play(SystemSoundType.click);
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isRecording = true;
      _routePoints.clear();
      _totalDistance = 0.0;
      _seconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });

    LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Filter gerak minimal 5 meter
      forceLocationManager: true, 
      intervalDuration: const Duration(seconds: 3), 
    );

    try {
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) {
        if (!mounted) return;
        if (position.accuracy > 20) return; // Filter sinyal jelek

        LatLng newPoint = LatLng(position.latitude, position.longitude);
        
        setState(() {
          if (_routePoints.isNotEmpty) {
            double gap = Geolocator.distanceBetween(
              _routePoints.last.latitude, _routePoints.last.longitude,
              newPoint.latitude, newPoint.longitude
            );
            // Logic Anti-Jitter: Hanya tambah jarak jika gerak > 2 meter
            if (gap > 2.0) {
               _totalDistance += gap / 1000;
               _routePoints.add(newPoint);
            }
          } else {
            _routePoints.add(newPoint);
          }
          _currentLocation = newPoint;
        });
        _mapController.move(newPoint, _mapController.camera.zoom); 
      });
    } catch (e) {
      debugPrint("GPS Error: $e");
    }
  }

  Future<void> _stopTrackingManual() async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
    _timer?.cancel();
    await _positionStream?.cancel();

    setState(() => _isSaving = true);

    double met = _selectedSport == "LARI" ? 9.8 : 7.5;
    double finalCalories = met * 70 * (_seconds / 3600);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dbRef = FirebaseDatabase.instance.ref("users/${user.uid}/history");
        await dbRef.push().set({
          'type': 'TRACKING',
          'activity': "Track $_selectedSport",
          'distance_km': double.parse(_totalDistance.toStringAsFixed(2)),
          'duration_sec': _seconds,
          'calories': double.parse(finalCalories.toStringAsFixed(0)),
          'time': DateTime.now().toIso8601String(),
        });

        if (mounted) _showSyncedSuccessDialog(); // Tampilkan pop-up baru
      }
    } catch (e) {
      debugPrint("Gagal simpan: $e");
    }
    
    setState(() {
      _isRecording = false;
      _showControlPanel = false;
      _isSaving = false;
    });
  }

  // ✅ POP-UP SINKRON DENGAN DESAIN KAMU
  void _showSyncedSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur tipis saja agar fokus ke pop-up
        child: Dialog(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
            decoration: BoxDecoration(
              // ✅ Warna Hitam Pekat Semi-Transparan (Samar)
              color: const Color(0xFF000000).withOpacity(0.85), 
              borderRadius: BorderRadius.circular(28),
              // ✅ Border tipis agar pop-up tidak "tenggelam" di background map yang gelap
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1), 
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Bulat Hijau Toska khas LORA
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5EEAD4), 
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Color.fromARGB(255, 32, 32, 32), size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  "KERJA BAGUS!",
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 20, 
                    letterSpacing: 1.5
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Sesi $_selectedSport kamu telah aman tersimpan di riwayat.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7), 
                    fontSize: 14, 
                    height: 1.4
                  ),
                ),
                const SizedBox(height: 32),
                // Tombol Biru Solid
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 251, 251, 251),
                      foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Selanjutnya",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI WIDGETS ---
  void _toggleMenu() {
    HapticFeedback.selectionClick(); 
    setState(() {
      _showSportMenu = !_showSportMenu;
      if (_showSportMenu) _showControlPanel = false; 
    });
  }

  void _selectSport(String sport) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSport = sport;
      _showSportMenu = false;
      _showControlPanel = true;
      _isRecording = false;
      _seconds = 0;
      _totalDistance = 0.0;
      _routePoints.clear();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-6.8898, 109.6713), 
              initialZoom: 15.0,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', userAgentPackageName: 'com.example.lora_1'),
              PolylineLayer(polylines: [Polyline(points: _routePoints, color: Colors.blueAccent, strokeWidth: 4, strokeCap: StrokeCap.round)]),
              MarkerLayer(markers: [Marker(point: _currentLocation, width: 40, height: 40, child: Container(decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20)))]),
            ],
          ),
          Positioned(top: 50, left: 20, child: GestureDetector(onTap: _toggleMenu, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: Icon(_showSportMenu ? Icons.close_rounded : Icons.menu_rounded, color: Colors.white, size: 28)))),
          if (_showSportMenu) _buildSportSelectionMenu(),
          if (_showControlPanel) _buildGlassControlPanel(),
          if (_isSaving) Container(color: Colors.black87, child: const Center(child: CircularProgressIndicator(color: Colors.white)))
        ],
      ),
    );
  }

  Widget _buildSportSelectionMenu() {
    return Positioned(top: 110, left: 20, child: Material(type: MaterialType.transparency, child: Container(width: 220, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("PILIH AKTIVITAS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)), const SizedBox(height: 15), _buildMenuItem(Icons.directions_run_rounded, "LARI"), const Divider(color: Colors.white12, height: 25), _buildMenuItem(Icons.directions_bike_rounded, "SEPEDA")]))));
  }

  Widget _buildMenuItem(IconData icon, String label) {
    return InkWell(onTap: () => _selectSport(label), child: Row(children: [Icon(icon, color: Colors.white, size: 24), const SizedBox(width: 15), Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]));
  }

  Widget _buildGlassControlPanel() {
    return Positioned(bottom: 130, left: 20, right: 20, child: Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(_selectedSport, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))), Row(children: [const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 18), const SizedBox(width: 5), Text("$_currentTemp°C", style: const TextStyle(color: Colors.white))])]), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildBigStat("${_totalDistance.toStringAsFixed(2)}", "KM"), Container(width: 1, height: 30, color: Colors.white12), _buildBigStat(_formatTime(_seconds), "TIME"), Container(width: 1, height: 30, color: Colors.white12), _buildBigStat("-", "KCAL")]), const SizedBox(height: 25), GestureDetector(onTap: _isRecording ? _stopTrackingManual : _startTrackingManual, child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 55, width: double.infinity, decoration: BoxDecoration(color: _isRecording ? const Color(0xFFFF0000) : Colors.white, borderRadius: BorderRadius.circular(18)), child: Center(child: Text(_isRecording ? "STOP RECORDING" : "START TRACKING", style: TextStyle(color: _isRecording ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)))))])));
  }

  Widget _buildBigStat(String value, String unit) {
    return Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')), const SizedBox(height: 4), Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500))]);
  }
}