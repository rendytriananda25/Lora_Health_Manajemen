
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Gagal mengambil data dari server.'])
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Gagal mengambil data lokal.'])
      : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Tidak ada koneksi internet.'])
      : super(message);
}

class LocationFailure extends Failure {
  const LocationFailure([String message = 'Gagal mendapatkan lokasi.'])
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'User belum login.'])
      : super(message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'Terjadi kesalahan yang tidak terduga.'])
      : super(message);
}
