import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../errors/exceptions.dart';

abstract interface class LocalStorage {
  Future<bool> containsKey(String key);

  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, bool value);

  Future<int?> readInt(String key);

  Future<void> writeInt(String key, int value);

  Future<double?> readDouble(String key);

  Future<void> writeDouble(String key, double value);

  Future<List<String>?> readStringList(String key);

  Future<void> writeStringList(String key, List<String> value);

  Future<Map<String, dynamic>?> readJson(String key);

  Future<void> writeJson(String key, Map<String, dynamic> value);

  Future<void> remove(String key);

  Future<void> clear();

  Future<void> clearExcept(Set<String> preservedKeys);
}

class SharedPreferencesLocalStorage implements LocalStorage {
  const SharedPreferencesLocalStorage(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<bool> containsKey(String key) async {
    return _wrap(() => _preferences.containsKey(key));
  }

  @override
  Future<String?> readString(String key) async {
    return _wrap(() => _preferences.getString(key));
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _wrap(() => _preferences.setString(key, value));
  }

  @override
  Future<bool?> readBool(String key) async {
    return _wrap(() => _preferences.getBool(key));
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    await _wrap(() => _preferences.setBool(key, value));
  }

  @override
  Future<int?> readInt(String key) async {
    return _wrap(() => _preferences.getInt(key));
  }

  @override
  Future<void> writeInt(String key, int value) async {
    await _wrap(() => _preferences.setInt(key, value));
  }

  @override
  Future<double?> readDouble(String key) async {
    return _wrap(() => _preferences.getDouble(key));
  }

  @override
  Future<void> writeDouble(String key, double value) async {
    await _wrap(() => _preferences.setDouble(key, value));
  }

  @override
  Future<List<String>?> readStringList(String key) async {
    return _wrap(() => _preferences.getStringList(key));
  }

  @override
  Future<void> writeStringList(String key, List<String> value) async {
    await _wrap(() => _preferences.setStringList(key, value));
  }

  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    final value = await readString(key);
    if (value == null || value.trim().isEmpty) return null;

    return _wrap(() {
      final decodedValue = jsonDecode(value);
      if (decodedValue is Map<String, dynamic>) return decodedValue;

      throw const FormatException('Stored value is not a JSON object.');
    });
  }

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await writeString(key, jsonEncode(value));
  }

  @override
  Future<void> remove(String key) async {
    await _wrap(() => _preferences.remove(key));
  }

  @override
  Future<void> clear() async {
    await _wrap(_preferences.clear);
  }

  @override
  Future<void> clearExcept(Set<String> preservedKeys) async {
    final preservedValues = <String, Object?>{
      for (final key in preservedKeys) key: _preferences.get(key),
    }..removeWhere((_, value) => value == null);

    await clear();

    for (final entry in preservedValues.entries) {
      await _restoreValue(entry.key, entry.value);
    }
  }

  Future<void> _restoreValue(String key, Object? value) async {
    switch (value) {
      case String():
        await writeString(key, value);
      case bool():
        await writeBool(key, value);
      case int():
        await writeInt(key, value);
      case double():
        await writeDouble(key, value);
      case List<String>():
        await writeStringList(key, value);
    }
  }

  Future<T> _wrap<T>(FutureOr<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw StorageException(error.toString());
    }
  }
}
