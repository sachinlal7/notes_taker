import '../../../../core/network/api_response.dart';
import '../../../../shared/entities/user_entity.dart';

abstract interface class GetCurrentUserUseCase {
  Result<UserEntity> call();
}
