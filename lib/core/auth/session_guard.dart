import 'token_manager.dart';

class SessionGuard {
  const SessionGuard(this._tokenManager);

  final TokenManager _tokenManager;

  Future<bool> get hasActiveSession async {
    final token = await _tokenManager.readAccessToken();
    return token != null && token.trim().isNotEmpty;
  }
}
