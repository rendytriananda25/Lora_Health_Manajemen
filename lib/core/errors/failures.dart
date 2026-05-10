/// ═══════════════════════════════════════════════════════════════
/// Failures — Representasi error yang aman untuk Presentation Layer.
/// UseCase mengembalikan Failure, bukan throw Exception.
/// Widget tinggal cek tipe Failure-nya dan tampilkan pesan.
/// ═══════════════════════════════════════════════════════════════

abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Gagal mengambil data dari server (API / Firebase).
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Gagal mengambil data dari server.'])
      : super(message);
}

/// Gagal mengambil data dari local storage.
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Gagal mengambil data lokal.'])
      : super(message);
}

/// Gagal karena tidak ada koneksi internet.
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Tidak ada koneksi internet.'])
      : super(message);
}

/// Gagal karena lokasi/GPS tidak tersedia.
class LocationFailure extends Failure {
  const LocationFailure([String message = 'Gagal mendapatkan lokasi.'])
      : super(message);
}

/// Gagal karena user belum login atau sesi habis.
class AuthFailure extends Failure {
  const AuthFailure([String message = 'User belum login.'])
      : super(message);
}

/// Gagal karena alasan tidak terduga.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'Terjadi kesalahan yang tidak terduga.'])
      : super(message);
}
