import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  // Cek Izin & Ambil Lokasi Awal
  Future<LatLng?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Gagal ambil lokasi: $e");
      return null;
    }
  }

  // Stream untuk Tracking Real-time
  Stream<Position> getPositionStream() {
    // Settingan GPS biar hemat baterai tapi akurat
    final LocationSettings settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 6, // Low-end friendly: kurangi frekuensi update GPS
      intervalDuration: const Duration(seconds: 2),
      forceLocationManager: false,
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  // Hitung Jarak Antar Titik (KM)
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude, start.longitude, 
      end.latitude, end.longitude
    ) / 1000; // Konversi ke KM
  }
}
