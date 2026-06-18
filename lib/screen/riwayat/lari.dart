import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class HistoryLariDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const HistoryLariDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {

    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    DateTime dt = DateTime.parse(
      data['time'] ?? DateTime.now().toIso8601String(),
    );
    String formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(dt);

    double distance = double.parse(data['distance_km']?.toString() ?? "0");
    int seconds = data['duration_sec'] ?? 0;
    double pace = distance > 0 ? (seconds / 60) / distance : 0;

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 5, child: _buildRouteMap(theme)),
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    color: theme.boxColor.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    border: Border.all(color: theme.textColor.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DETAIL AKTIVITAS LARI",
                        style: TextStyle(
                          color: Color(0xFF5EEAD4),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(
                        color: theme.textColor.withOpacity(0.1),
                        height: 40,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            "JARAK",
                            "${distance.toStringAsFixed(2)}",
                            "KM",
                            theme,
                          ),
                          _buildStatItem(
                            "PACE",
                            "${pace.toStringAsFixed(1)}",
                            "MIN/KM",
                            theme,
                          ),
                          _buildStatItem(
                            "KALORI",
                            "${data['calories'] ?? 0}",
                            "KCAL",
                            theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBackButton(context, theme),
        ],
      ),
    );
  }

  Widget _buildRouteMap(ThemeProvider theme) {

    List<LatLng> points = [];
    if (data['path'] != null && data['path'] is List) {
      points = (data['path'] as List).map((p) {
        double lat = (p['lat'] as num).toDouble();
        double lng = (p['lng'] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.isNotEmpty
            ? points.last
            : const LatLng(-6.8898, 109.6713),
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: theme.isDarkMode
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const [
            'a',
            'b',
            'c',
          ],
          retinaMode: true,
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              color: const Color(0xFF008BFF),
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
            ),
          ],
        ),
        if (points.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: points.first,
                child: const Icon(Icons.circle, color: Colors.green, size: 15),
              ),
              Marker(
                point: points.last,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    ThemeProvider theme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.38),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.54),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context, ThemeProvider theme) =>
      Positioned(
        top: 50,
        left: 20,
        child: CircleAvatar(
          backgroundColor: theme.boxColor.withOpacity(0.5),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: theme.textColor),
          ),
        ),
      );
}
