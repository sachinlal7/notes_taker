import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/exceptions.dart';

abstract interface class SecureStorage {
  Future<bool> containsKey(String key);

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<void> clear();
}

class FlutterSecureStorageService implements SecureStorage {
  const FlutterSecureStorageService(this._storage);

  static const AndroidOptions androidOptions = AndroidOptions();

  static const IOSOptions iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<bool> containsKey(String key) {
    return _wrap(
      () => _storage.containsKey(
        key: key,
        aOptions: androidOptions,
        iOptions: iosOptions,
      ),
    );
  }

  @override
  Future<String?> read(String key) {
    return _wrap(
      () => _storage.read(
        key: key,
        aOptions: androidOptions,
        iOptions: iosOptions,
      ),
    );
  }

  @override
  Future<void> write(String key, String value) {
    return _wrap(
      () => _storage.write(
        key: key,
        value: value,
        aOptions: androidOptions,
        iOptions: iosOptions,
      ),
    );
  }

  @override
  Future<void> delete(String key) {
    return _wrap(
      () => _storage.delete(
        key: key,
        aOptions: androidOptions,
        iOptions: iosOptions,
      ),
    );
  }

  @override
  Future<void> clear() {
    return _wrap(
      () => _storage.deleteAll(aOptions: androidOptions, iOptions: iosOptions),
    );
  }

  Future<T> _wrap<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw StorageException(error.toString());
    }
  }
}
