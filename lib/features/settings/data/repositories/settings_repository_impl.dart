import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/core/errors/failures.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Result<UserProfileEntity>> getUserProfile() async {
    try {
      final remoteData = await remoteDataSource.getUserProfile();
      final localPhoto = await localDataSource.getLocalPhoto();

      return Either.right(UserProfileEntity(
        uid: remoteData['uid'],
        fullName: remoteData['fullName'],
        email: remoteData['email'],
        photoUrl: remoteData['photoUrl'],
        localPhotoPath: localPhoto,
        height: remoteData['height'],
        weight: remoteData['weight'],
        gender: remoteData['gender'],
        age: remoteData['age'],
      ));
    } catch (e) {
      return Either.left(ServerFailure("Failed to get profile: $e"));
    }
  }

  @override
  Future<Result<void>> updateUserName(String newName) async {
    try {
      await remoteDataSource.updateUserName(newName);
      return Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure("Failed to update name: $e"));
    }
  }

  @override
  Future<Result<void>> saveLocalPhoto(String path) async {
    try {
      await localDataSource.saveLocalPhoto(path);
      return Either.right(null);
    } catch (e) {
      return Either.left(CacheFailure("Failed to save local photo: $e"));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await remoteDataSource.logout();
      return Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure("Failed to logout: $e"));
    }
  }
}
