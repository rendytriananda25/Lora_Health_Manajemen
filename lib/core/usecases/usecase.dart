import 'package:lora_1/core/errors/either.dart';

/// UseCase — Kontrak dasar untuk semua logika bisnis di Domain Layer.
///
/// Setiap UseCase memiliki SATU tugas (Single Responsibility):
///   - GetWeatherData -> ambil data cuaca
///   - CalculateBMI -> hitung BMI dari berat & tinggi
///   - SaveWorkout -> simpan sesi olahraga
///
/// UseCase mengembalikan `Result<T>` (`Either<Failure, T>`):
///   - Sukses -> `Result.right(data)`
///   - Gagal  -> `Result.left(ServerFailure('...'))`
///
/// Contoh penggunaan:
/// ```dart
/// class GetWeatherData extends UseCase<WeatherEntity, LocationParams> {
///   final WeatherRepository repository;
///   GetWeatherData(this.repository);
///
///   @override
///   Future<Result<WeatherEntity>> call(LocationParams params) async {
///     return await repository.getWeather(params.lat, params.lon);
///   }
/// }
/// ```

abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Untuk UseCase yang tidak butuh parameter input.
/// Contoh: GetCurrentUser(), LogOut()
class NoParams {
  const NoParams();
}
