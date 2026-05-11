import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// ═══════════════════════════════════════════════════════════════
/// LocationService — GPS Tracking Service dengan:
/// 1. Foreground Service (layar mati tetap tracking)
/// 2. Filter titik GPS noise (akurasi rendah / loncatan aneh)
/// 3. Akurasi tinggi menggunakan GPS murni (bukan WiFi/Cell)
/// ═══════════════════════════════════════════════════════════════
class LocationService {
  /// Ambil lokasi awal user (sekali saja)
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

  /// Stream GPS real-time untuk tracking lari/sepeda.
  /// Menggunakan AndroidSettings dengan foreground notification
  /// agar tracking tetap jalan saat layar HP dimatikan.
  Stream<Position> getPositionStream() {
    final LocationSettings settings = AndroidSettings(
      accuracy: LocationAccuracy.best,     // 🔥 GPS murni, akurasi tertinggi
      distanceFilter: 5,                    // Update setiap bergerak 5 meter
      intervalDuration: const Duration(seconds: 1),  // Interval update 1 detik
      forceLocationManager: false,          // Pakai Fused Location (lebih akurat)
      // 🔥 KEY FIX: Foreground Service agar tracking jalan saat layar mati
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "LORA - Tracking Aktif",
        notificationText: "Sedang merekam aktivitas olahraga kamu...",
        notificationChannelName: "Lora GPS Tracking",
        enableWakeLock: true,   // 🔥 Cegah CPU tidur saat layar mati
        enableWifiLock: false,
        setOngoing: true,       // Notifikasi tidak bisa di-swipe
      ),
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Hitung jarak antar 2 titik GPS (dalam KM)
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    ) / 1000; // Konversi ke KM
  }

  /// 🔥 FILTER: Cek apakah titik GPS layak dipakai
  /// Return false jika:
  /// - Akurasi terlalu rendah (> 25 meter)
  /// - Kecepatan tidak masuk akal (> 50 km/h untuk lari)
  /// - Titik loncat terlalu jauh dari titik sebelumnya
  bool isValidPoint(Position newPos, LatLng? lastPoint) {
    // 1. Filter akurasi rendah (GPS belum lock sinyal)
    if (newPos.accuracy > 15.0) {
      debugPrint('⚠️ GPS Noise: akurasi ${newPos.accuracy}m (> 15m), titik dibuang');
      return false;
    }

    // 2. Filter kecepatan tidak masuk akal
    //    50 km/h = 13.9 m/s → manusia tidak bisa lari secepat ini
    if (newPos.speed > 13.9) {
      debugPrint('⚠️ GPS Noise: kecepatan ${newPos.speed} m/s, titik dibuang');
      return false;
    }

    // 3. Filter loncatan GPS & GPS Drift
    if (lastPoint != null) {
      double distMeters = Geolocator.distanceBetween(
        lastPoint.latitude, lastPoint.longitude,
        newPos.latitude, newPos.longitude,
      );
      // Jika loncat > 100 meter dalam 1 kali update, pasti noise
      if (distMeters > 100) {
        debugPrint('⚠️ GPS Noise: loncat ${distMeters}m, titik dibuang');
        return false;
      }
      // 🔥 FIX: Anti-drift — jika bergerak < 3 meter, anggap diam di tempat
      if (distMeters < 3.0) {
        return false; // Buang titik, user belum bergerak cukup jauh
      }
    }

    return true;
  }
}
