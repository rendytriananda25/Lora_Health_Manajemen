import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class HistoryLariDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const HistoryLariDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    DateTime dt = DateTime.parse(data['time'] ?? DateTime.now().toIso8601String());
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);

    double distance = double.parse(data['distance_km']?.toString() ?? "0");
    int seconds = data['duration_sec'] ?? 0;
    double pace = distance > 0 ? (seconds / 60) / distance : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 5, child: _buildRouteMap()), 
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000).withOpacity(0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DETAIL AKTIVITAS LARI", 
                        style: TextStyle(color: Color(0xFF5EEAD4), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white10, height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("JARAK", "${distance.toStringAsFixed(2)}", "KM"),
                          _buildStatItem("PACE", "${pace.toStringAsFixed(1)}", "MIN/KM"),
                          _buildStatItem("KALORI", "${data['calories'] ?? 0}", "KCAL"),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          _buildBackButton(context),
        ],
      ),
    );
  }

  Widget _buildRouteMap() {
    List<LatLng> points = (data['path'] as List? ?? []).map((p) => LatLng(p['lat'], p['lng'])).toList();
    return FlutterMap(
      options: MapOptions(initialCenter: points.isNotEmpty ? points[0] : const LatLng(-6.8898, 109.6713), initialZoom: 16),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          retinaMode: true, // ✅ Menghilangkan peringatan log retina mode
        ),
        PolylineLayer(polylines: [Polyline(points: points, color: const Color(0xFF008BFF), strokeWidth: 5, strokeCap: StrokeCap.round)]),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ]);
  }

  Widget _buildBackButton(BuildContext context) => Positioned(top: 50, left: 20, child: CircleAvatar(backgroundColor: Colors.black.withOpacity(0.5), child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white))));
}