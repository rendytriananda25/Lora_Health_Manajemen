import 'package:lora_1/core/errors/either.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/settings_repository.dart';

class GetUserProfile {
  final SettingsRepository repository;

  GetUserProfile(this.repository);

  Future<Result<UserProfileEntity>> call() async {
    return await repository.getUserProfile();
  }
}
