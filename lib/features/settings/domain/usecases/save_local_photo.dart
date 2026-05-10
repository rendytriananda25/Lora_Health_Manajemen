import 'package:lora_1/core/errors/either.dart';
import '../repositories/settings_repository.dart';

class SaveLocalPhoto {
  final SettingsRepository repository;

  SaveLocalPhoto(this.repository);

  Future<Result<void>> call(String path) async {
    return await repository.saveLocalPhoto(path);
  }
}
