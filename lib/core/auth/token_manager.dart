import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';

class TokenManager {
  const TokenManager(this._secureStorage);

  final SecureStorage _secureStorage;

  Future<String?> readAccessToken() {
    return _secureStorage.read(StorageKeys.accessToken);
  }

  Future<void> saveAccessToken(String token) {
    return _secureStorage.write(StorageKeys.accessToken, token);
  }

  Future<void> clearAccessToken() {
    return _secureStorage.delete(StorageKeys.accessToken);
  }

  Future<void> clearSession() {
    return _secureStorage.clear();
  }
}
