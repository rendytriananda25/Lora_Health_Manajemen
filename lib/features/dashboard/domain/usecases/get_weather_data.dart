import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/core/usecases/usecase.dart';
import 'package:lora_1/features/dashboard/domain/entities/weather_entity.dart';
import 'package:lora_1/features/dashboard/domain/repositories/dashboard_repository.dart';

/// UseCase: Ambil data cuaca, AQI, dan UV.
/// Satu tugas saja — Single Responsibility.
class GetWeatherData extends UseCase<WeatherEntity, WeatherParams> {
  final DashboardRepository repository;

  GetWeatherData(this.repository);

  @override
  Future<Result<WeatherEntity>> call(WeatherParams params) async {
    return await repository.getWeatherData(langCode: params.langCode);
  }
}

/// Parameter input untuk GetWeatherData.
class WeatherParams {
  final String langCode;
  const WeatherParams({this.langCode = 'id'});
}
