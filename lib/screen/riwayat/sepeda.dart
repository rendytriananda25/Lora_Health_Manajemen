import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class HistorySepedaDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const HistorySepedaDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    DateTime dt = DateTime.parse(data['time'] ?? DateTime.now().toIso8601String());
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);

    int seconds = data['duration_sec'] ?? 0;
    String durationText = "${(seconds / 60).floor()}m ${seconds % 60}s";
    double fatBurned = (data['calories'] ?? 0) / 9;

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
                      const Text("DETAIL AKTIVITAS SEPEDA", 
                        style: TextStyle(color: Color(0xFF5EEAD4), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white10, height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("JARAK", "${data['distance_km'] ?? 0}", "KM"),
                          _buildStatItem("WAKTU", durationText, "DURASI"),
                          _buildStatItem("LEMAK", "${fatBurned.toStringAsFixed(1)}", "GRAM"),
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
    // 🔥 PERBAIKAN: Cara baca data yang lebih aman (cegah crash tipe data)
    List<LatLng> points = [];
    if (data['path'] != null && data['path'] is List) {
      points = (data['path'] as List).map((p) {
        // Pastikan lat/lng dibaca sebagai double
        double lat = (p['lat'] as num).toDouble();
        double lng = (p['lng'] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();
    }

    return FlutterMap(
      options: MapOptions(
        // Jika point kosong, default ke lokasi user (bisa disesuaikan) atau Monas/Pusat Kota
        initialCenter: points.isNotEmpty ? points.last : const LatLng(-6.8898, 109.6713), 
        initialZoom: 16
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c'], // Tambahkan subdomain agar map loading cepat
          retinaMode: true,
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points, 
              color: const Color(0xFF008BFF), 
              strokeWidth: 5, 
              strokeCap: StrokeCap.round
            )
          ]
        ),
        // Opsional: Tambahkan Marker Start & Finish biar keren
        if (points.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(point: points.first, child: const Icon(Icons.circle, color: Colors.green, size: 15)), // Start
              Marker(point: points.last, child: const Icon(Icons.location_on, color: Colors.red, size: 30)), // Finish
            ],
          ),
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