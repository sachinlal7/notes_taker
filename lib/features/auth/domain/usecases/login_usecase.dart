import '../../../../core/network/api_response.dart';
import '../../../../shared/entities/user_entity.dart';

abstract interface class LoginUseCase {
  Result<UserEntity> call({required String email, required String password});
}
