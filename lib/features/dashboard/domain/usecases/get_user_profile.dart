import 'package:lora_1/core/errors/either.dart';
import 'package:lora_1/core/usecases/usecase.dart';
import 'package:lora_1/features/dashboard/domain/entities/user_profile_entity.dart';
import 'package:lora_1/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetUserProfile extends UseCase<UserProfileEntity, NoParams> {
  final DashboardRepository repository;

  GetUserProfile(this.repository);

  @override
  Future<Result<UserProfileEntity>> call(NoParams params) async {
    return await repository.getUserProfile();
  }
}
