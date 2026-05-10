import 'package:lora_1/core/errors/either.dart';
import '../repositories/settings_repository.dart';

class UpdateUserName {
  final SettingsRepository repository;

  UpdateUserName(this.repository);

  Future<Result<void>> call(String newName) async {
    return await repository.updateUserName(newName);
  }
}
