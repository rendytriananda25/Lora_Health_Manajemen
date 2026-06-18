import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Simple 2D Kalman Filter for GPS coordinate smoothing.
/// Reduces jitter/noise from raw GPS readings while preserving real movement.
class _GpsKalmanFilter {
  double _lat = 0;
  double _lng = 0;
  double _variance = -1; // Negative = uninitialized

  /// Process variance — lower = smoother but slower to react.
  /// 1e-5 is tuned for walking/running pace (1-5 m/s).
  static const double _processNoise = 1e-5;

  /// Feed a new GPS reading and get the smoothed result.
  LatLng filter(double lat, double lng, double accuracyMeters) {
    // Convert accuracy in meters to approximate degree variance.
    // 1 degree ≈ 111,320 meters at the equator.
    final double accDeg = accuracyMeters / 111320.0;
    final double measurementVariance = accDeg * accDeg;

    if (_variance < 0) {
      // First reading: initialize directly
      _lat = lat;
      _lng = lng;
      _variance = measurementVariance;
    } else {
      // Predict step
      _variance += _processNoise;

      // Update step (Kalman gain)
      final double k = _variance / (_variance + measurementVariance);
      _lat += k * (lat - _lat);
      _lng += k * (lng - _lng);
      _variance = (1 - k) * _variance;
    }

    return LatLng(_lat, _lng);
  }

  void reset() => _variance = -1;
}

class LocationService {
  final _GpsKalmanFilter _kalman = _GpsKalmanFilter();

  // Stored state for advanced filtering
  DateTime? _lastTimestamp;
  LatLng? _lastFilteredPoint;

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
      distanceFilter: 3,
      intervalDuration: const Duration(seconds: 1),
      // IMPORTANT: false = use FusedLocationProvider (GPS + WiFi + Sensors)
      // true  = use old LocationManager (cell tower only, MUCH less accurate)
      forceLocationManager: false,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "LORA - Tracking Aktif",
        notificationText: "Sedang merekam aktivitas olahraga kamu...",
        notificationChannelName: "Lora GPS Tracking",
        enableWakeLock: true,
        enableWifiLock: true,
        setOngoing: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000;
  }

  /// Validates and smooths a GPS point using Kalman filter.
  /// Returns the filtered LatLng if the point is valid, null if rejected.
  LatLng? filterPoint(Position newPos, LatLng? lastRoutePoint) {
    // --- Stage 1: Hard reject on bad accuracy ---
    if (newPos.accuracy > 12.0) {
      debugPrint(
        '⚠️ GPS: akurasi ${newPos.accuracy.toStringAsFixed(1)}m (>12m), dibuang',
      );
      return null;
    }

    // --- Stage 2: Speed sanity check (max ~50 km/h for sport tracking) ---
    if (newPos.speed > 13.9) {
      debugPrint(
        '⚠️ GPS: speed ${newPos.speed.toStringAsFixed(1)} m/s, dibuang',
      );
      return null;
    }

    // --- Stage 3: Time-based speed check against last accepted point ---
    final now = DateTime.fromMillisecondsSinceEpoch(
      newPos.timestamp.millisecondsSinceEpoch,
    );
    if (_lastFilteredPoint != null && _lastTimestamp != null) {
      final dtSec = now.difference(_lastTimestamp!).inMilliseconds / 1000.0;
      if (dtSec > 0.5) {
        final distM = Geolocator.distanceBetween(
          _lastFilteredPoint!.latitude,
          _lastFilteredPoint!.longitude,
          newPos.latitude,
          newPos.longitude,
        );
        final computedSpeed = distM / dtSec;
        // If computed speed > 15 m/s (~54 km/h), it's definitely noise
        if (computedSpeed > 15.0) {
          debugPrint(
            '⚠️ GPS: computed speed ${computedSpeed.toStringAsFixed(1)} m/s, dibuang',
          );
          return null;
        }
      }
    }

    // --- Stage 4: Teleport detection ---
    if (lastRoutePoint != null) {
      final jumpDist = Geolocator.distanceBetween(
        lastRoutePoint.latitude,
        lastRoutePoint.longitude,
        newPos.latitude,
        newPos.longitude,
      );
      if (jumpDist > 80) {
        debugPrint('⚠️ GPS: teleport ${jumpDist.toStringAsFixed(0)}m, dibuang');
        return null;
      }
    }

    // --- Stage 5: Apply Kalman filter for smoothing ---
    final filtered = _kalman.filter(
      newPos.latitude,
      newPos.longitude,
      newPos.accuracy,
    );

    // --- Stage 6: Minimum movement threshold (avoid stationary drift) ---
    if (_lastFilteredPoint != null) {
      final movedDist = Geolocator.distanceBetween(
        _lastFilteredPoint!.latitude,
        _lastFilteredPoint!.longitude,
        filtered.latitude,
        filtered.longitude,
      );
      if (movedDist < 2.0) {
        // Less than 2m movement = probably stationary drift
        return null;
      }
    }

    _lastFilteredPoint = filtered;
    _lastTimestamp = now;
    return filtered;
  }

  /// Legacy method kept for backward compatibility.
  bool isValidPoint(Position newPos, LatLng? lastPoint) {
    return filterPoint(newPos, lastPoint) != null;
  }

  /// Call when starting a new tracking session.
  void resetFilter() {
    _kalman.reset();
    _lastTimestamp = null;
    _lastFilteredPoint = null;
  }
}
