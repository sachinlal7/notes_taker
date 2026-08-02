import '../../shared/entities/user_entity.dart';

class AuthSession {
  const AuthSession({required this.accessToken, this.user});

  final String accessToken;
  final UserEntity? user;
}
