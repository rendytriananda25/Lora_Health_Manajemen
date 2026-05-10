/// ═══════════════════════════════════════════════════════════════
/// Exceptions — Digunakan HANYA di Data Layer (DataSource).
/// DataSource boleh throw Exception.
/// Repository akan menangkap Exception dan mengubahnya jadi Failure.
/// ═══════════════════════════════════════════════════════════════

/// Exception saat server mengembalikan response error.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);
  @override
  String toString() => 'ServerException: $message';
}

/// Exception saat data lokal tidak ditemukan.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache not found']);
  @override
  String toString() => 'CacheException: $message';
}

/// Exception saat lokasi tidak bisa diambil.
class LocationException implements Exception {
  final String message;
  const LocationException([this.message = 'Location unavailable']);
  @override
  String toString() => 'LocationException: $message';
}
