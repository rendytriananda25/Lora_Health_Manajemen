
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);
  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache not found']);
  @override
  String toString() => 'CacheException: $message';
}

class LocationException implements Exception {
  final String message;
  const LocationException([this.message = 'Location unavailable']);
  @override
  String toString() => 'LocationException: $message';
}
