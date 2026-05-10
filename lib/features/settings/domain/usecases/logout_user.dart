import 'package:lora_1/core/errors/either.dart';
import '../repositories/settings_repository.dart';

class LogoutUser {
  final SettingsRepository repository;

  LogoutUser(this.repository);

  Future<Result<void>> call() async {
    return await repository.logout();
  }
}
