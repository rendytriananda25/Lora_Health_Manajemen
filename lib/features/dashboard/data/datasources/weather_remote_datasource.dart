import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:lora_1/core/constants/api_constants.dart';
import 'package:lora_1/core/errors/exceptions.dart';

/// DataSource untuk data cuaca dari OpenWeatherMap API.
/// HANYA bertugas: ambil data mentah → kembalikan Map.
/// Tidak boleh ada logika bisnis di sini.
class WeatherRemoteDataSource {
  /// Ambil data cuaca + AQI dari API berdasarkan GPS.
  /// Throws [ServerException] jika gagal.
  Future<Map<String, dynamic>> fetchWeatherAndAQI({
    String langCode = 'id',
  }) async {
    // 1. Ambil lokasi GPS
    double lat = -7.9666; // Default Malang
    double lon = 112.6326;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      lat = pos.latitude;
      lon = pos.longitude;
    } catch (_) {
      // Pakai koordinat default jika GPS gagal
    }

    // 2. Fetch cuaca + AQI secara paralel
    try {
      final results = await Future.wait([
        http.get(Uri.parse(ApiConstants.weatherUrl(lat, lon, lang: langCode))),
        http.get(Uri.parse(ApiConstants.aqiUrl(lat, lon))),
      ]);

      if (results[0].statusCode != 200) {
        throw ServerException('Weather API error: ${results[0].statusCode}');
      }
      if (results[1].statusCode != 200) {
        throw ServerException('AQI API error: ${results[1].statusCode}');
      }

      final weatherJson = json.decode(results[0].body);
      final aqiJson = json.decode(results[1].body);

      return {
        'weather': weatherJson,
        'aqi': aqiJson,
      };
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Gagal mengambil data cuaca: $e');
    }
  }
}
