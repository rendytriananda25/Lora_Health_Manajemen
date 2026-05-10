import 'package:lora_1/core/errors/either.dart';
import '../entities/user_profile_entity.dart';

abstract class SettingsRepository {
  Future<Result<UserProfileEntity>> getUserProfile();
  Future<Result<void>> updateUserName(String newName);
  Future<Result<void>> saveLocalPhoto(String path);
  Future<Result<void>> logout();
}
