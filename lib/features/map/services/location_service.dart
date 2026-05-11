import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  Future<LatLng?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Gagal ambil lokasi: $e");
      return null;
    }
  }

  Stream<Position> getPositionStream() {
    final LocationSettings settings = AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 1),
      forceLocationManager: false,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "LORA - Tracking Aktif",
        notificationText: "Sedang merekam aktivitas olahraga kamu...",
        notificationChannelName: "Lora GPS Tracking",
        enableWakeLock: true,
        enableWifiLock: false,
        setOngoing: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    ) / 1000;
  }
  bool isValidPoint(Position newPos, LatLng? lastPoint) {
    if (newPos.accuracy > 15.0) {
      debugPrint('⚠️ GPS Noise: akurasi ${newPos.accuracy}m (> 15m), titik dibuang');
      return false;
    }

    if (newPos.speed > 13.9) {
      debugPrint('⚠️ GPS Noise: kecepatan ${newPos.speed} m/s, titik dibuang');
      return false;
    }

    if (lastPoint != null) {
      double distMeters = Geolocator.distanceBetween(
        lastPoint.latitude, lastPoint.longitude,
        newPos.latitude, newPos.longitude,
      );
      if (distMeters > 100) {
        debugPrint('⚠️ GPS Noise: loncat ${distMeters}m, titik dibuang');
        return false;
      }
      if (distMeters < 3.0) {
        return false;
      }
    }

    return true;
  }
}
